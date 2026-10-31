#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o Dpkg::Options::=--force-confold \
  xfce4 xfce4-terminal dbus-x11 tigervnc-standalone-server tigervnc-common \
  novnc websockify wget ca-certificates xz-utils curl

# Install Mozilla's current Firefox build instead of Ubuntu's snap-only wrapper.
if ! command -v firefox >/dev/null 2>&1 || ! firefox --version >/dev/null 2>&1; then
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64) firefox_os=linux64 ;;
    arm64) firefox_os=linux64-aarch64 ;;
    *) echo "Unsupported architecture for Firefox: $arch" >&2; exit 1 ;;
  esac
  tmp_file="$(mktemp --suffix=.tar.xz)"
  trap 'rm -f "$tmp_file"' EXIT
  wget -qO "$tmp_file" "https://download.mozilla.org/?product=firefox-latest&os=${firefox_os}&lang=en-US"
  sudo tar -xJf "$tmp_file" -C /opt
  sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox
fi

mkdir -p "$HOME/.vnc"
printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec dbus-launch startxfce4\n' > "$HOME/.vnc/xstartup"
chmod +x "$HOME/.vnc/xstartup"
