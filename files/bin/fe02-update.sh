#!/bin/bash
# fe02-update: Updates the booted image, Flatpaks, and Distrobox containers

set -e

function show_usage() {
    echo "Fe02-OS Update"
    echo "Usage: fe02-update [command]"
    echo ""
    echo "Commands:"
    echo "  (none)   - Update the image, Flatpaks, and Distrobox containers"
    echo "  status   - Show current booted and staged images"
}

function update_image() {
    echo "==> Upgrading system image..."
    # Routed through fe02-update-image.service (see the matching polkit
    # rule) so this never needs a sudo password, e.g. when launched from
    # the desktop entry.
    systemctl start --wait fe02-update-image.service
}

function update_flatpaks() {
    if ! command -v flatpak &>/dev/null; then
        echo "==> Flatpak not found, skipping."
        return
    fi
    echo "==> Updating Flatpaks..."
    flatpak update -y
}

function update_distrobox() {
    if ! command -v distrobox &>/dev/null; then
        echo "==> Distrobox not found, skipping."
        return
    fi
    echo "==> Updating Distrobox containers..."
    distrobox upgrade --all
}

case "$1" in
    "")
        update_image
        update_flatpaks
        update_distrobox
        echo ""
        echo "Update complete. Reboot to apply the new image, if staged."
        ;;
    status)
        bootc status | grep -E "Booted|Queued|Image:"
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        show_usage
        exit 1
        ;;
esac
