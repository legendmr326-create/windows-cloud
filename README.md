# Linux XFCE Cloud Desktop (GitHub Codespaces)

This repository runs a Linux Ubuntu XFCE desktop in your browser using noVNC. It is not a real Windows desktop. The Windows-style interface in the project page is only a visual theme.

## Start the desktop

1. Click **Code -> Codespaces -> Create codespace on main**.
2. Wait for the container setup to finish. It installs XFCE, Firefox, TigerVNC, noVNC, and websockify.
3. Codespaces forwards port **6080** and opens the noVNC page in your browser. If it does not open automatically, open the forwarded port from the **Ports** tab.
4. Connect to the desktop. Each container startup generates a new random VNC password, saved inside the Codespace at `~/.vnc/password`. In the terminal, run `cat ~/.vnc/password` to read it, then enter it in noVNC. Keep the password private.

The desktop uses a 1600x900 XFCE session. Firefox is installed in the Linux desktop. The VNC server listens only on localhost inside the Codespace; browser access is through noVNC on port 6080.

## Mobile (Chrome/Android)

- In noVNC, use the keyboard icon to type on your phone.
- Tap to click. Use the noVNC toolbar's drag option to move the pointer.
- Use your browser's fullscreen option for a larger view.
