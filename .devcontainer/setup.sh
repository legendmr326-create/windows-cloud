#!/bin/bash
set -e
if [ ! -x /usr/bin/vncserver ]; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::=--force-confold xfce4 xfce4-terminal dbus-x11 tigervnc-standalone-server tigervnc-common novnc websockify
fi
sudo mkdir -p /usr/share/backgrounds
mkdir -p ~/.vnc
printf 'vscode\nvscode\n' | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec dbus-launch startxfce4\n' > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -geometry 1600x900 -localhost yes -rfbport 5901 </dev/null
echo DESKTOP_READY
