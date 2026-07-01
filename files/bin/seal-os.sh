#!/bin/bash
# seal-os: Synchronizes policy and enables bootc signature enforcement

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# 1. Sync the policy from the image to the system
if [ -f "/usr/etc/containers/policy.json" ]; then
    echo "Syncing Fe02-OS signature policy..."
    cp -f /usr/etc/containers/policy.json /etc/containers/policy.json
else
    echo "Error: Custom policy not found in image (/usr/etc/containers/policy.json)."
    exit 1
fi

# 2. Get the current image reference
IMAGE_REF=$(bootc status --json | jq -r '.spec.image.image')

if [[ "$IMAGE_REF" == "null" || -z "$IMAGE_REF" ]]; then
    echo "Error: Could not determine image reference."
    exit 1
fi

echo "Enforcing signature policy for $IMAGE_REF..."

# 3. Lock it down
if bootc switch --enforce-container-sigpolicy "$IMAGE_REF"; then
    echo "-------------------------------------------------------"
    echo "Fe02-OS is now SEALED for production updates."
    echo "Please reboot your system."
else
    echo "Error: Failed to enforce signature policy."
    exit 1
fi
