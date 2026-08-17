#!/bin/bash
set -ex

BUILD_SETUP_DIR="/ctx/scripts"

echo "Step 1: Installing signing policy, public key, and utilities..."
cp -drf /ctx/system/* /
mkdir -p /etc/pki/containers
cp /ctx/cosign.pub /etc/pki/containers/cosign.pub
cp /ctx/bin/seal-os.sh /usr/bin/seal-os
cp /ctx/bin/fe02 /usr/bin/fe02
chmod +x /usr/bin/seal-os /usr/bin/fe02

echo "Step 2: Installing packages..."
bash "$BUILD_SETUP_DIR/01-install-pkgs.sh"

echo "Step 3: Removing unwanted desktop entries..."
bash "$BUILD_SETUP_DIR/02-remove-desktop-entries.sh"

echo "Running cleanup..."
bash "$BUILD_SETUP_DIR/05-post-setup.sh"
