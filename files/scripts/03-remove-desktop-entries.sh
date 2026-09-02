#!/bin/bash
set -ex

if [ -z "${DESKTOP_ENV}" ]; then
    echo "ERROR: DESKTOP_ENV is not set" >&2
    exit 1
fi

PKG_FILE="/ctx/scripts/pkgs/packages.yaml"
if [ ! -f "$PKG_FILE" ]; then
    echo "ERROR: package list not found: $PKG_FILE" >&2
    exit 1
fi

readarray -t entries < <(
    yq -r "(.desktop_entries.remove.common // [])[], (.desktop_entries.remove.${DESKTOP_ENV} // [])[]" "$PKG_FILE"
)

for entry in "${entries[@]}"; do
    rm -f "/usr/share/applications/${entry}"
    echo "Removed desktop entry: ${entry}"
done
