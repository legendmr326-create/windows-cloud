#!/usr/bin/env bash
set -euo pipefail

LOG=/tmp/desktop.log
exec >>"$LOG" 2>&1
echo "[$(date -Is)] starting desktop bootstrap"

# Keep VNC credentials out of the repository. Honor the Codespaces secret when
# configured; otherwise use a random password and keep it in the user's home.
if [[ -n "${VNC_PASSWORD:-}" ]]; then
  AUTH_PASSWORD="${VNC_PASSWORD:0:8}"
else
  AUTH_PASSWORD="$(head -c 6 /dev/urandom | base64 | tr -d '\n')"
fi
mkdir -p "$HOME/.vnc" "$HOME/Pictures"
umask 077
printf '%s\n' "$AUTH_PASSWORD" > "$HOME/.vnc/password"
printf '%s\n%s\n' "$AUTH_PASSWORD" "$AUTH_PASSWORD" | vncpasswd "$HOME/.vnc/passwd" >/dev/null
chmod 600 "$HOME/.vnc/password" "$HOME/.vnc/passwd"
unset VNC_PASSWORD AUTH_PASSWORD

# Drop stale forwarding/VNC daemons, then start exactly one of each.
pkill -x x11vnc 2>/dev/null || true
pkill -x websockify 2>/dev/null || true

# Start a persistent X server on :0 only when one is not already serving it.
if ! pgrep -af '^Xvfb :0([[:space:]]|$)' >/dev/null; then
  Xvfb :0 -screen 0 1280x800x24 -nolisten tcp >>"$LOG" 2>&1 &
fi
export DISPLAY=:0
for _ in $(seq 1 30); do
  if xdpyinfo -display :0 >/dev/null 2>&1; then break; fi
  sleep 1
done
if ! xdpyinfo -display :0 >/dev/null 2>&1; then
  echo "Xvfb :0 did not become ready"; exit 1
fi

# Reuse the active XFCE session bus, or create one for this desktop session.
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  eval "$(dbus-launch --sh-syntax)"
fi
export DBUS_SESSION_BUS_ADDRESS
if ! pgrep -u "$(id -u)" -x xfce4-session >/dev/null; then
  xfce4-session >>"$LOG" 2>&1 &
fi

# Always install the repository's exact wallpaper at the requested path.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "$REPO_DIR/assets/wallpaper.jpg" ]]; then
  echo "Missing exact wallpaper: $REPO_DIR/assets/wallpaper.jpg"; exit 1
fi
cp -f "$REPO_DIR/assets/wallpaper.jpg" "$HOME/Pictures/wallpaper.jpg"

# Wait for XFCE's backdrop channel, then set every known monitor/workspace.
for _ in $(seq 1 30); do
  if xfconf-query -c xfce4-desktop -l >/dev/null 2>&1; then break; fi
  sleep 1
done
mapfile -t image_props < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '^/backdrop/.*/last-image$' || true)
if ((${#image_props[@]} == 0)); then
  image_props=(/backdrop/screen0/monitor0/workspace0/last-image)
fi
for prop in "${image_props[@]}"; do
  xfconf-query -c xfce4-desktop -p "$prop" -n -t string -s "$HOME/Pictures/wallpaper.jpg" 2>/dev/null \
    || xfconf-query -c xfce4-desktop -p "$prop" -s "$HOME/Pictures/wallpaper.jpg"
  style_prop="${prop%/last-image}/image-style"
  xfconf-query -c xfce4-desktop -p "$style_prop" -n -t int -s 5 2>/dev/null \
    || xfconf-query -c xfce4-desktop -p "$style_prop" -s 5
 done
# Share the same background across workspaces, preventing workspace image cycling.
xfconf-query -c xfce4-desktop -p /backdrop/single-workspace-mode -n -t bool -s true 2>/dev/null \
  || xfconf-query -c xfce4-desktop -p /backdrop/single-workspace-mode -s true

# Refresh desktop and panel so the new image is visible immediately.
if pgrep -u "$(id -u)" -x xfdesktop >/dev/null; then
  xfdesktop --reload >>"$LOG" 2>&1 || true
else
  xfdesktop >>"$LOG" 2>&1 &
fi
if pgrep -u "$(id -u)" -x xfce4-panel >/dev/null; then
  xfce4-panel --restart >>"$LOG" 2>&1 || true
else
  xfce4-panel >>"$LOG" 2>&1 &
fi

NOVNC_WEB=/usr/share/novnc
if [[ ! -f "$NOVNC_WEB/vnc.html" ]]; then
  echo "noVNC client not found at $NOVNC_WEB/vnc.html"; exit 1
fi
x11vnc -display :0 -rfbport 5900 -rfbauth "$HOME/.vnc/passwd" -forever -shared -noxdamage >>"$LOG" 2>&1 &
for _ in $(seq 1 30); do
  if ss -ltn | grep -q ':5900 '; then break; fi
  sleep 1
done
if ! ss -ltn | grep -q ':5900 '; then echo "x11vnc failed to listen on 5900"; exit 1; fi
websockify --web="$NOVNC_WEB" 6080 localhost:5900 >>"$LOG" 2>&1 &
for _ in $(seq 1 30); do
  if curl --silent --fail http://127.0.0.1:6080/vnc.html >/dev/null; then
    echo "[$(date -Is)] desktop ready on :0, noVNC port 6080"
    exit 0
  fi
  sleep 1
done
echo "websockify failed to serve noVNC on 6080"
exit 1
