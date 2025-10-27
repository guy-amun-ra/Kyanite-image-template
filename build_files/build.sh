#!/bin/bash
set -euo pipefail

# Install additional packages with DNF5 that are not part of rpm-ostree overrides

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

# Enable any required systemd services

systemctl enable podman.socket

# Remove SteamOS / Steam Deck specific packages and window managers
rpm-ostree override remove \
    gamescope-session \
    sddm-sugar-steamOS \
    steamdeck-kde-presets \
    steamdeck-kde-presets-desktop \
    mutter \
    gnome-shell

# Install KDE Plasma desktop components explicitly
rpm-ostree install plasma-desktop kwin sddm

# Remove SteamOS-specific sddm config to revert to KDE defaults
rm -f /etc/sddm.conf.d/steamos.conf

# Set KDE as default graphical target session
loginctl set-default graphical.target || true

# Finalize rpm-ostree changes
rpm-ostree db filesystem

echo "Build customization complete - SteamOS components removed, KDE Plasma desktop ensured."
