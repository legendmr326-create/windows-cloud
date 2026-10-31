#!/usr/bin/env bash
set -euo pipefail

# Generate a fresh password for each container start. TigerVNC uses the first
# eight characters, so generate exactly eight random hexadecimal characters.
VNC_PASSWORD="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
printf '%s\n' "$VNC_PASSWORD" > "$HOME/.vnc/password"
chmod 600 "$HOME/.vnc/password"
printf '%s\n%s\n' "$VNC_PASSWORD" "$VNC_PASSWORD" | vncpasswd "$HOME/.vnc/passwd" >/dev/null
chmod 600 "$HOME/.vnc/passwd"
unset VNC_PASSWORD

# Avoid stale display locks if a prior startup was interrupted.
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -geometry 1600x900 -localhost yes -rfbport 5901 </dev/null

NOVNC_WEB="/usr/share/novnc"
if [ ! -f "$NOVNC_WEB/vnc.html" ]; then
  echo "noVNC client not found at $NOVNC_WEB/vnc.html" >&2
  exit 1
fi
websockify --web="$NOVNC_WEB" 6080 localhost:5901 </dev/null >/tmp/novnc-websockify.log 2>&1 &
NOVNC_PID=$!

# Fail setup rather than reporting ready when the browser endpoint did not start.
for _ in $(seq 1 30); do
  if ! kill -0 "$NOVNC_PID" 2>/dev/null; then
    cat /tmp/novnc-websockify.log >&2
    exit 1
  fi
  if curl --silent --fail http://127.0.0.1:6080/vnc.html >/dev/null; then
    echo "noVNC is available on port 6080. Read the generated VNC password from ~/.vnc/password."
    echo DESKTOP_READY
    exit 0
  fi
  sleep 1
done
cat /tmp/novnc-websockify.log >&2
echo "Timed out waiting for noVNC on port 6080" >&2
exit 1
