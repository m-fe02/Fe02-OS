#!/usr/bin/bash
# Rebrand os-release. Must run BEFORE initramfs regeneration - IMAGE_ID is
# baked in and read back out of the initramfs for hibernation-image matching.
set -ex

echo "Applying Fe02-OS image identity..."

IMAGE_PRETTY_NAME="Fe02-OS"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/m-fe02/Fe02-OS"
DOCUMENTATION_URL="https://github.com/m-fe02/Fe02-OS"
SUPPORT_URL="https://github.com/m-fe02/Fe02-OS/issues"
BUG_REPORT_URL="https://github.com/m-fe02/Fe02-OS/issues"
LOGO_ICON="fe02-logo"
VARIANT_ID="${DESKTOP_ENV:-fe02-os}"

OS_RELEASE_FILE="/usr/lib/os-release"

sed -i "s|^VARIANT_ID=.*|VARIANT_ID=${VARIANT_ID}|" "${OS_RELEASE_FILE}"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^NAME=.*|NAME=\"${IMAGE_PRETTY_NAME}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${DOCUMENTATION_URL}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"${SUPPORT_URL}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"${BUG_REPORT_URL}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:m-fe02:fe02-os|" "${OS_RELEASE_FILE}"
sed -i "s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME=\"fe02-os\"|" "${OS_RELEASE_FILE}"
sed -i "s|^ID=fedora|ID=fe02-os\nID_LIKE=\"${IMAGE_LIKE}\"|" "${OS_RELEASE_FILE}"
sed -i "s|^LOGO=.*|LOGO=${LOGO_ICON}|" "${OS_RELEASE_FILE}"
sed -i "/^REDHAT_BUGZILLA_PRODUCT=/d; /^REDHAT_BUGZILLA_PRODUCT_VERSION=/d; /^REDHAT_SUPPORT_PRODUCT=/d; /^REDHAT_SUPPORT_PRODUCT_VERSION=/d" "${OS_RELEASE_FILE}"

# Fedora's grub2-switch-to-blscfg hardcodes EFIDIR based on the previous
# ID=fedora. It still needs to look in /boot/efi/EFI/fedora for the actual
# EFI assets even though ID no longer says "fedora", so patch it to avoid
# breaking UEFI boot config generation.
sed -i "s|^EFIDIR=.*|EFIDIR=\"fedora\"|" /usr/sbin/grub2-switch-to-blscfg

echo "Image identity applied."
cat "${OS_RELEASE_FILE}"
