#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# [https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1](https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1)

# this installs a package from fedora repos
dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

# --- GPD Pocket 4 specific fixes for screen rotation and input ---

mkdir -p /usr/lib/bootc/kargs.d/
cat > /usr/lib/bootc/kargs.d/10-gpd-pocket4.toml <<EOF
kargs = [
  "fbcon=rotate:1",
  "video=eDP-1:panel_orientation=right_side_up"
]
EOF

mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/20-gpd-pocket4.conf <<EOF
Section "Device"
  Identifier "AMD Graphics"
  Driver "amdgpu"
  Option "TearFree" "true"
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

echo "GPD Pocket 4 screen and input fixes applied."
