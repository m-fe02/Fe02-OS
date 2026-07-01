#!/bin/bash
set -ex

# Step 5: Install packages

export FEDORA_VERSION=$(rpm -E %fedora)

if [ -z "${DESKTOP_ENV}" ]; then
    echo "ERROR: DESKTOP_ENV is not set; must be one of: kde, cosmic" >&2
    exit 1
fi

PKG_FILE="/ctx/scripts/pkgs/packages.yaml"
if [ ! -f "$PKG_FILE" ]; then
    echo "ERROR: package list not found: $PKG_FILE" >&2
    exit 1
fi

DNF_INSTALL=(dnf --setopt=install_weak_deps=False install -y)

if ! command -v yq &> /dev/null; then
    echo "Installing yq for YAML parsing..."
    "${DNF_INSTALL[@]}" yq
fi

copr_manage() {
    local action=$1; shift
    for copr in "$@"; do
        dnf -y copr "$action" "$copr"
    done
}

# --- Setup global repos ---
yq -r '.repos.url // {} | to_entries[] | "\(.key) \(.value)"' "$PKG_FILE" \
  | while read -r name url; do
      [[ -z "$name" || -z "$url" ]] && continue
      curl -s -o "/etc/yum.repos.d/${name}.repo" "$(echo "$url" | envsubst)"
    done

yq -r '.repos.inline // {} | keys[]' "$PKG_FILE" | while read -r name; do
    yq -r ".repos.inline[\"${name}\"]" "$PKG_FILE" > "/etc/yum.repos.d/${name}.repo"
done

readarray -t GLOBAL_COPR < <(yq -r '.repos.copr // [] | .[]' "$PKG_FILE")
copr_manage enable "${GLOBAL_COPR[@]}"

# --- Install packages ---
echo "Parsing packages for variant: $DESKTOP_ENV"

REMOVALS=$(yq -r "(.packages.remove.common // [])[], (.packages.remove.${DESKTOP_ENV} // [])[]" "$PKG_FILE" | xargs)
COMMON_PKGS=$(yq -r '.packages.common[]' "$PKG_FILE" | xargs)
VARIANT_PKGS=$(yq -r ".packages.variants.${DESKTOP_ENV}.packages[]?" "$PKG_FILE" | xargs)

if [ -z "$COMMON_PKGS" ]; then
    echo "ERROR: No common packages found" >&2
    exit 1
fi

echo "Installing common and variant packages..."
"${DNF_INSTALL[@]}" $COMMON_PKGS $VARIANT_PKGS

if [ "$DESKTOP_ENV" = "sway" ]; then
    systemctl enable ly@tty2.service
fi

# --- Gaming packages ---
GAMING=${GAMING:-false}
if [ "$GAMING" = "true" ]; then
    echo "Gaming enabled; setting up gaming repos..."

    GAMING_RPM_URLS=$(yq -r '.packages.gaming.repos.rpm // {} | to_entries[] | .value' "$PKG_FILE" | envsubst | xargs)
    if [ -n "$GAMING_RPM_URLS" ]; then
        "${DNF_INSTALL[@]}" $GAMING_RPM_URLS
    fi

    readarray -t GAMING_COPR < <(yq -r '.packages.gaming.repos.copr // [] | .[]' "$PKG_FILE")
    copr_manage enable "${GAMING_COPR[@]}"

    GAMING_PKGS=$(yq -r '.packages.gaming.packages[]' "$PKG_FILE" | xargs)
    echo "Installing gaming packages..."
    "${DNF_INSTALL[@]}" $GAMING_PKGS

    # Cleanup gaming repos
    GAMING_RPM_PKGS=$(yq -r '.packages.gaming.repos.rpm // {} | keys[]' "$PKG_FILE" | xargs)
    if [ -n "$GAMING_RPM_PKGS" ]; then
        dnf remove -y $GAMING_RPM_PKGS
    fi

    copr_manage disable "${GAMING_COPR[@]}"
fi

# Remove bloat after all packages are installed so group deps are present to remove
if [ -n "$REMOVALS" ]; then
    echo "Removing bloat packages..."
    dnf remove -y $REMOVALS || true
fi


# --- Cleanup global repos ---
yq -r '.repos.url // {} | keys[]' "$PKG_FILE" | while read -r name; do
    rm -f "/etc/yum.repos.d/${name}.repo"
done

yq -r '.repos.inline // {} | keys[]' "$PKG_FILE" | while read -r name; do
    rm -f "/etc/yum.repos.d/${name}.repo"
done

copr_manage disable "${GLOBAL_COPR[@]}"
