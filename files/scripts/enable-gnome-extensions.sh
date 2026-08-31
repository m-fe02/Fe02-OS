#!/bin/bash
# Enables every GNOME Shell extension installed via RPM.
# Run inside an active GNOME session (needs a D-Bus session bus) — this
# cannot run during the image build, since gsettings writes to the user's
# dconf, which requires a logged-in session.
set -e

mapfile -t EXTENSIONS < <(gnome-extensions list)

if [ ${#EXTENSIONS[@]} -eq 0 ]; then
    echo "No GNOME Shell extensions found."
    exit 0
fi

printf -v LIST "'%s', " "${EXTENSIONS[@]}"
gsettings set org.gnome.shell enabled-extensions "[${LIST%, }]"

echo "Enabled: ${EXTENSIONS[*]}"
