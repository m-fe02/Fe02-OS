#!/usr/bin/bash
# Regenerate initramfs so Plymouth branding assets are baked in
set -euo pipefail

echo "INFO: Regenerating Initramfs for all installed kernels."

DRACUT="/usr/bin/dracut"
if [[ -f "/usr/libexec/rpm-ostree/wrapped/dracut" ]]; then
    DRACUT="/usr/libexec/rpm-ostree/wrapped/dracut"
    echo "INFO: Using rpm-ostree wrapped dracut."
fi

temp_conf_file="$(mktemp '/etc/dracut.conf.d/zzz-loglevels-XXXXXXXXXX.conf')"
cat > "${temp_conf_file}" <<'EOF'
stdloglvl=4   # Only show warnings/errors
sysloglvl=0
kmsgloglvl=0
fileloglvl=0
EOF

KERNEL_PATHS=($(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d))

if [ "${#KERNEL_PATHS[@]}" -eq 0 ]; then
    rm -f "${temp_conf_file}"
    echo "ERROR: No kernels found in /usr/lib/modules. Install likely failed." >&2
    exit 1
fi

for kernel_path in "${KERNEL_PATHS[@]}"; do
    kernel_version="$(basename "${kernel_path}")"
    initramfs_image="${kernel_path}/initramfs.img"

    echo "INFO: Starting initramfs generation for kernel version: ${kernel_version}"

    export DRACUT_NO_XATTR=1

    "${DRACUT}" --no-hostonly \
        --kver "${kernel_version}" \
        --reproducible \
        --add "ostree bash dracut-systemd" \
        --install "date" \
        --force "${initramfs_image}"

    chmod 0600 "${initramfs_image}"
    echo "INFO: Successfully generated initramfs for ${kernel_version}"
done

rm -f "${temp_conf_file}"
echo "INFO: Initramfs regeneration finished successfully."
