#!/bin/bash
set -ex

echo "INFO: Running container cleanup..."

# Remove DNF runtime state (leave /var/cache intact so the build cache mount works)
rm -rf /var/lib/dnf

# Clean /boot contents safely without expanding to '.' or '..'
find /boot -mindepth 1 -delete

# Clean log files (systemd-tmpfiles handles /var/log/journal permissions at boot)
find /var/log -type f -delete

# Clean package manager and daemon state left behind in /var
rm -rf \
    /var/lib/containers \
    /var/lib/tailscale \
    /var/lib/tpm2-tss \
    /var/lib/rpm-state \
    /var/lib/selinux/targeted/active \
    /var/lib/selinux/targeted/semanage.read.* \
    /var/lib/selinux/targeted/seusers \
    /var/lib/selinux/targeted/commit_num || true

# Remove container-engine injected resolv.conf so systemd-tmpfiles restores the stub symlink
rm -f /etc/resolv.conf
rm -rf /etc/skel/.mozilla /etc/skel/.config/user-tmpfiles.d || true

systemd-tmpfiles --create --boot --root=/ || true

# Empty runtime state (/tmp is in tmpfs and automatically discarded on unmount)
rm -rf /run/* /var/tmp/* || true

mkdir -p /run /var/tmp
chmod 0755 /run
chmod 1777 /var/tmp

echo "INFO: Container cleanup complete."
