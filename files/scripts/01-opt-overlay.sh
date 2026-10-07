#!/bin/bash
# Replace the base image's /opt -> /var/opt symlink with a real directory
# managed by ostree-state-overlay@.service. This lets /opt ship baked-in content as part
# of the ostree commit while still being writable client-side: the service
# layers an overlayfs over it with the writable upper dir stored in /var,
# and rebases that state onto the new base content on every upgrade.
set -ex

echo "INFO: Switching /opt to an ostree state overlay..."

if [ -L /opt ]; then
    rm /opt
fi
mkdir -p /opt

systemctl enable ostree-state-overlay@opt.service

echo "INFO: /opt state overlay enabled."
