#!/usr/bin/env bash
# GlusterFS Mount Script
# Run on any swarm node to mount the shared volume.
# Usage: ./mount.sh [gluster-server-ip] [volume] [mount-point]

set -euo pipefail

SERVER="${1:-localhost}"
VOLUME="${2:-swarm}"
MOUNT="${3:-/mnt/gluster}"

echo "Mounting GlusterFS volume..."
echo "  Server:  $SERVER"
echo "  Volume:  $VOLUME"
echo "  Mount:   $MOUNT"

if ! command -v mount.glusterfs &>/dev/null; then
    echo "Installing glusterfs-client..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y glusterfs-client
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y glusterfs-fuse
    fi
fi

sudo mkdir -p "$MOUNT"
sudo mount -t glusterfs "${SERVER}:/${VOLUME}" "$MOUNT"

echo ""
echo "Mounted at $MOUNT"
echo ""
echo "To persist across reboots, add to /etc/fstab:"
echo "  ${SERVER}:/${VOLUME}  ${MOUNT}  glusterfs  defaults,_netdev,backupvolfile-server=${SERVER}  0  0"
