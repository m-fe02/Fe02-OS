#!/bin/bash
set -ex

BUILD_SETUP_DIR="/ctx/scripts"

echo "Step 1: Installing signing policy, public key, and utilities..."
cp -drf /ctx/system/* /
mkdir -p /etc/pki/containers
cp /ctx/cosign.pub /etc/pki/containers/cosign.pub
cp /ctx/bin/fe02-sign.sh /usr/bin/fe02-sign
cp /ctx/bin/fe02-bootswitch /usr/bin/fe02-bootswitch
cp /ctx/bin/fe02-update.sh /usr/bin/fe02-update
chmod +x /usr/bin/fe02-sign /usr/bin/fe02-bootswitch /usr/bin/fe02-update

echo "Step 2: Switching /opt to an ostree state overlay..."
bash "$BUILD_SETUP_DIR/01-opt-overlay.sh"

echo "Step 3: Installing packages..."
bash "$BUILD_SETUP_DIR/02-install-pkgs.sh"

echo "Step 4: Removing unwanted desktop entries..."
bash "$BUILD_SETUP_DIR/03-remove-desktop-entries.sh"

echo "Step 5: Applying branding..."
bash "$BUILD_SETUP_DIR/04-branding.sh"

echo "Step 6: Applying image identity..."
bash "$BUILD_SETUP_DIR/05-image-info.sh"

echo "Step 7: Regenerating initramfs for Plymouth branding..."
bash "$BUILD_SETUP_DIR/06-initramfs.sh"

echo "Running cleanup..."
bash "$BUILD_SETUP_DIR/07-post-setup.sh"
