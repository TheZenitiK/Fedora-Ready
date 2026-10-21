# Fedora-Ready
What is Fedora-Ready?

Fedora-Ready is an automated setup script that transforms your Fedora Linux installation into a fully optimized multimedia and development system in minutes. It handles all the tedious configuration tasks that users typically need to do manually after installing Fedora.

To launch, use a single command in the terminal:
Quick start:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/TheZenitiK/Fedora-Ready/refs/heads/main/fedora-ready.sh)
```
Download, save, and run manually:
```bash
git clone https://github.com/TheZenitiK/Fedora-Ready.git
cd Fedora-Ready
sudo bash fedora-ready.sh
```

The script automates 11 major configuration tasks:

1. System Updates — Automatic OS updates via dnf or rpm-ostree
2. Cisco OpenH264 — Video codec installation with 403 error fix
3. Window Controls — Restore minimize/maximize buttons in GNOME
4. Screenshot Hotkey — Enable Win+Shift+S for screenshots
5. Language Switching — Setup Alt+Shift for keyboard layout switching
6. GNOME Extensions — Install full extension ecosystem (tweaks, apps)
7. RPM Fusion Repos — Enable free and nonfree repositories
8. Multimedia Codecs — Install GStreamer, FFmpeg, DVD support, AC-3 audio
9. Touchpad Context Menu — Enable right-click on touchpads
10. NVIDIA Drivers — Auto-detect and install GPU drivers (optional)
11. Full Setup Mode — Execute all tasks sequentially with one option
