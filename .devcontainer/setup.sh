#!/bin/bash
set -e
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-terminal firefox dbus-x11 tigervnc-standalone-server novnc websockify imagemagick
sudo mkdir -p /usr/share/backgrounds
convert -size 1920x1080 -define gradient:direction=diagonal gradient:'#0063b1' -gradient:'#1e4c8a' /usr/share/backgrounds/win.png || true
sudo cp /usr/share/backgrounds/win.png /usr/share/xfce4/backdrops/win.png 2>/dev/null || true
mkdir -p ~/.vnc
printf 'vscode\n' | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
cat > ~/.vnc/xstartup <<'X'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch startxfce4
X
chmod +x ~/.vnc/xstartup
vncserver :1 -geometry 1600x900 -localhost yes -rfbport 5901 || true
websockify --web /usr/share/novnc 6080 localhost:5901 -D || true
echo "Desktop ready: open forwarded port 6080, click Connect (password: vscode)"
