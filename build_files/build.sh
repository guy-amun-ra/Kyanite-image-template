#!/bin/bash
set -euo pipefail

# Install essential packages non-interactively
dnf5 install -y shadow-utils tmux

# Enable podman.socket service if possible (skip errors)
systemctl enable podman.socket || true

# Remove Steam OS specific packages
dnf5 remove -y steam-devices steam-device-rules steam steamdeck-kde-presets-desktop || true

# Install KDE Plasma desktop components explicitly
dnf5 install -y plasma-desktop kwin sddm

# Remove Steam OS specific SDDM config to revert to KDE defaults
rm -f /etc/sddm.conf.d/steamos.conf || true

# Set KDE as default graphical target
loginctl set-default graphical.target || true

# --- Start of GPD Pocket 4 specific display/input setup ---

# Create Xorg configuration for Intel GPU tear-free and rotation, touchscreen calibration
mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/20-gpd-pocket4.conf <<EOF
Section "Device"
    Identifier "Inteldrt"
    Driver "intel"
    Option "TearFree" "true"
    Option "AccelMethod" "sna"
EndSection

Section "Monitor"
    Identifier "eDP-1"
    Option "Rotate" "right"
EndSection

Section "InputClass"
    Identifier "touchscreen"
    MatchIsTouchpad "on"
    Option "Calibration" "0 1920 0 1080"
    Option "InvertY" "true"
EndSection
EOF

# Create SDDM config forcing KDE user modes
mkdir -p /etc/sddm.conf.d/
cat > /etc/sddm.conf.d/00-kde.conf <<EOF
[General]
InputMethod=
UserModes=force
EOF

echo "Build customization complete - SteamOS components removed, KDE Plasma desktop ensured, GPD Pocket 4 fixes applied."
