#!/bin/bash
set -euo pipefail

# Install additional packages with DNF5 that are not part of rpm-ostree overrides


# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1


# Assuming you have a chroot or target root path (e.g., $IMG_ROOT)
dnf5 install -y shadow-utils
dnf5 install --installroot=$IMG_ROOT -y shadow-utils

# this installs a package from fedora repos

dnf5 install -y tmux


# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

# Enable any required systemd services (podman.socket enablement likely works inside build container)
systemctl enable podman.socket || true

# Remove SteamOS / Steam Deck specific packages (only those confirmed installed)
dnf5 remove -y steam-devices steam-device-rules steam steamdeck-kde-presets-desktop || true

# Install KDE Plasma desktop components explicitly
dnf5 install -y plasma-desktop kwin sddm

# Remove SteamOS-specific SDDM config to revert to KDE defaults
rm -f /etc/sddm.conf.d/steamos.conf || true

# Set KDE as default graphical target session
loginctl set-default graphical.target || true


## DEBUGGING
echo "Skipping /ctx/cfg/xorg ls due to workaround"
## END DEBUGGING

# --- Start of GPD Pocket 4 specific additions ---

# dnf5 -y copr enable hhd-dev/hhd TODO enabled handheld later
# dnf5 -y install handheld-daemon


# Append kernel boot args for screen rotation and panel orientation by modifying systemd-boot config
# This command DOES NOT WORK inside the container build environment, comment it out
#rpm-ostree kargs --append=fbcon=rotate:1 --append=video=eDP-1:panel_orientation=right_side_up

# Read kernel cmdline parameters from cfg/kernel/cmdline
# Manually write kernel cmdline to systemd-boot loader entry
KERNEL_CMDLINE="fbcon=rotate:1 video=eDP-1:panel_orientation=right_side_up"
for ENTRY in /boot/loader/entries/*bazzite*.conf; do
  if [ -f "$ENTRY" ]; then
    echo "Appending kernel cmdline args to $ENTRY"
      # Append the cmdline flags to the options line
    sed -i "/^options / s/\$/ $KERNEL_CMDLINE/" "$ENTRY"
  fi
done
# TODO enabled handheld later
# Install handheld-daemon package for handheld device support (used by Bazzite)
# dnf5 install -y handheld-daemon

# TODO enabled handheld later
# Enable handheld daemon service by creating systemd symlink, not with systemctl enable inside build container
# mkdir -p /etc/systemd/system/multi-user.target.wants/
# cp cfg/systemd/handheld-daemon.service /etc/systemd/system/handheld-daemon.service
# ln -sf /etc/systemd/system/handheld-daemon.service /etc/systemd/system/multi-user.target.wants/handheld-daemon.service

# Copy Xorg config for GPD Pocket 4

# Manually write Xorg config file


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

# Manually write SDDM config file
mkdir -p /etc/sddm.conf.d/
cat > /etc/sddm.conf.d/00-kde.conf <<EOF
[General]
InputMethod=
UserModes=force
EOF

# # Handheld daemon service setup (copy unit and enable symlink)
# mkdir -p /etc/systemd/system/multi-user.target.wants/
# cat > /etc/systemd/system/handheld-daemon.service <<EOF
# [Unit]
# Description=Handheld Daemon Support
# After=network.target

# [Service]
# ExecStart=/usr/bin/handheld-daemon
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target
# EOF

# ln -sf /etc/systemd/system/handheld-daemon.service /etc/systemd/system/multi-user.target.wants/handheld-daemon.service

# --- End of GPD Pocket 4 specific additions ---

echo "Build customization complete - SteamOS components removed, KDE Plasma desktop ensured, GPD Pocket 4 fixes applied."
