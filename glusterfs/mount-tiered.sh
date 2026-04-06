#!/usr/bin/env bash
# GlusterFS Tiered Mount Script
# Run on any swarm node AFTER setup-tiered.sh has been run on TuringPiRK1.
# Mounts both fast and bulk volumes at the standard paths.
#
# Usage: ./mount-tiered.sh [rk1-host] [compute3-host]
# Defaults: TuringPiRK1  TuringPICompute3

set -euo pipefail

RK1_HOST="${1:-TuringPiRK1}"
COMPUTE3_HOST="${2:-TuringPICompute3}"

FAST_MOUNT="/mnt/gluster-fast"
BULK_MOUNT="/mnt/gluster-bulk"

echo "=== GlusterFS Tiered Mount ==="
echo "  Fast volume:  ${RK1_HOST}:/fast  ->  ${FAST_MOUNT}"
echo "  Bulk volume:  ${COMPUTE3_HOST}:/bulk  ->  ${BULK_MOUNT}"
echo ""

# ── Install client if needed ──────────────────────────────────────────────────
if ! command -v mount.glusterfs &>/dev/null; then
    echo "Installing glusterfs-client..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y glusterfs-client
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y glusterfs-fuse
    fi
fi

# ── Mount fast ────────────────────────────────────────────────────────────────
sudo mkdir -p "${FAST_MOUNT}"
if mountpoint -q "${FAST_MOUNT}"; then
    echo "  ${FAST_MOUNT} already mounted — skipping."
else
    sudo mount -t glusterfs "${RK1_HOST}:/fast" "${FAST_MOUNT}"
    echo "  ${FAST_MOUNT} mounted."
fi

# ── Mount bulk ────────────────────────────────────────────────────────────────
sudo mkdir -p "${BULK_MOUNT}"
if mountpoint -q "${BULK_MOUNT}"; then
    echo "  ${BULK_MOUNT} already mounted — skipping."
else
    sudo mount -t glusterfs "${COMPUTE3_HOST}:/bulk" "${BULK_MOUNT}"
    echo "  ${BULK_MOUNT} mounted."
fi

echo ""
echo "Both volumes mounted."
echo ""
echo "To persist across reboots, add to /etc/fstab:"
echo "  ${RK1_HOST}:/fast    ${FAST_MOUNT}  glusterfs  defaults,_netdev,backupvolfile-server=${RK1_HOST}  0 0"
echo "  ${COMPUTE3_HOST}:/bulk  ${BULK_MOUNT}  glusterfs  defaults,_netdev,backupvolfile-server=${COMPUTE3_HOST}  0 0"
