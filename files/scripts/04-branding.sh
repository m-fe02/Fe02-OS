#!/usr/bin/bash
set -ex

echo "Applying Fe02-OS branding..."

# kcm-about-distrorc is KDE's "About This System" config (kinfocenter). It's
# mirrored onto every variant by the step-1 file copy, but only makes sense
# on KDE - same scoping Bazzite uses for its own Kinoite-only copy.
if [[ "${DESKTOP_ENV,,}" != "kde" ]]; then
    rm -f /etc/xdg/kcm-about-distrorc
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi

echo "Branding applied."
