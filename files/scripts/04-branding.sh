#!/usr/bin/bash
set -ex

echo "Applying Fe02-OS branding..."

# kcm-about-distrorc is KDE's "About This System" config (kinfocenter).
# Only install it when building the KDE variant.
if [[ "${DESKTOP_ENV,,}" == "kde" ]]; then
    mkdir -p /etc/xdg
    cp /ctx/branding/kde/kcm-about-distrorc /etc/xdg/kcm-about-distrorc
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi

echo "Branding applied."
