#!/usr/bin/env bash
# GlusterFS Tiered Volume Setup — Turing Pi Cluster
#
# Creates two separate GlusterFS volumes using the native glusterd service:
#   fast  — NVMe brick on TuringPiRK1       → mounted at /mnt/gluster-fast
#   bulk  — SATA brick on TuringPICompute3  → mounted at /mnt/gluster-bulk
#
# Prerequisites:
#   - glusterfs-server installed and glusterd running on BOTH nodes
#   - SSH access from TuringPiRK1 to TuringPICompute3 (ubuntu@)
#   - NVMe mounted at /mnt/nvme on TuringPiRK1
#   - SATA mounted at /mnt/sata on TuringPICompute3
#
# Run ONCE from TuringPiRK1 as root (or with sudo).
# After this completes, run ./mount-tiered.sh on TuringPICompute3.

set -euo pipefail

# ── Node configuration ────────────────────────────────────────────────────────
RK1_HOST="TuringPiRK1"
COMPUTE3_HOST="TuringPICompute3"

# Host paths for GlusterFS bricks
FAST_BRICK="/mnt/nvme/gluster-bricks/fast"
BULK_BRICK="/mnt/sata/gluster-bricks/bulk"

FAST_MOUNT="/mnt/gluster-fast"
BULK_MOUNT="/mnt/gluster-bulk"

echo "=== GlusterFS Tiered Volume Setup ==="
echo "  Fast volume:  ${RK1_HOST}:${FAST_BRICK}  ->  ${FAST_MOUNT}"
echo "  Bulk volume:  ${COMPUTE3_HOST}:${BULK_BRICK}  ->  ${BULK_MOUNT}"
echo ""

# ── 1. Wait for glusterd on this node ────────────────────────────────────────
echo "[1/7] Waiting for glusterd to be ready on ${RK1_HOST}..."
for i in $(seq 1 12); do
    if gluster peer status &>/dev/null; then
        echo "  glusterd is ready."
        break
    fi
    echo "  Attempt $i/12 — waiting 5s..."
    sleep 5
    if [ "$i" -eq 12 ]; then
        echo "ERROR: glusterd not responding. Run: systemctl start glusterd"
        exit 1
    fi
done

# ── 2. Peer with TuringPICompute3 ────────────────────────────────────────────
echo "[2/7] Probing peer ${COMPUTE3_HOST}..."
gluster peer probe "${COMPUTE3_HOST}" || true
sleep 3
gluster peer status

# ── 3. Create brick directories ───────────────────────────────────────────────
echo "[3/7] Creating brick directories..."
mkdir -p "${FAST_BRICK}"
echo "  Created ${FAST_BRICK} on ${RK1_HOST}."

ssh "ubuntu@${COMPUTE3_HOST}" "sudo mkdir -p '${BULK_BRICK}'" \
    && echo "  Created ${BULK_BRICK} on ${COMPUTE3_HOST}." \
    || echo "  WARNING: Could not create bulk brick via SSH. Run on ${COMPUTE3_HOST}: sudo mkdir -p ${BULK_BRICK}"

# ── 4. Create the fast volume ─────────────────────────────────────────────────
echo "[4/7] Creating 'fast' volume (NVMe on ${RK1_HOST})..."
if gluster volume info fast &>/dev/null; then
    echo "  'fast' volume already exists, skipping create."
else
    gluster volume create fast transport tcp "${RK1_HOST}:${FAST_BRICK}" force
    gluster volume start fast
fi
gluster volume set fast auth.allow "*"
gluster volume set fast performance.cache-size 512MB
gluster volume set fast performance.io-thread-count 16
gluster volume set fast performance.read-ahead on
echo "  'fast' volume ready."

# ── 5. Create the bulk volume ─────────────────────────────────────────────────
echo "[5/7] Creating 'bulk' volume (SATA on ${COMPUTE3_HOST})..."
if gluster volume info bulk &>/dev/null; then
    echo "  'bulk' volume already exists, skipping create."
else
    gluster volume create bulk transport tcp "${COMPUTE3_HOST}:${BULK_BRICK}" force
    gluster volume start bulk
fi
gluster volume set bulk auth.allow "*"
gluster volume set bulk performance.cache-size 256MB
gluster volume set bulk performance.io-thread-count 8
echo "  'bulk' volume ready."

# ── 6. Install glusterfs-client and mount on RK1 ─────────────────────────────
echo "[6/7] Mounting volumes on ${RK1_HOST}..."

if ! command -v mount.glusterfs &>/dev/null; then
    echo "  Installing glusterfs-client..."
    if command -v apt-get &>/dev/null; then
        apt-get install -y glusterfs-client
    elif command -v dnf &>/dev/null; then
        dnf install -y glusterfs-fuse
    fi
fi

mkdir -p "${FAST_MOUNT}"
if ! mountpoint -q "${FAST_MOUNT}"; then
    mount -t glusterfs "localhost:/fast" "${FAST_MOUNT}"
    echo "  ${FAST_MOUNT} mounted."
else
    echo "  ${FAST_MOUNT} already mounted."
fi

mkdir -p "${BULK_MOUNT}"
if ! mountpoint -q "${BULK_MOUNT}"; then
    mount -t glusterfs "${COMPUTE3_HOST}:/bulk" "${BULK_MOUNT}"
    echo "  ${BULK_MOUNT} mounted."
else
    echo "  ${BULK_MOUNT} already mounted."
fi

# ── 7. Create stack subdirectories ───────────────────────────────────────────
echo "[7/7] Creating stack subdirectories..."

# Fast tier — databases, config, small state
mkdir -p \
    "${FAST_MOUNT}/immich/postgres" \
    "${FAST_MOUNT}/immich/model-cache" \
    "${FAST_MOUNT}/vaultwarden" \
    "${FAST_MOUNT}/authentik/postgres" \
    "${FAST_MOUNT}/meshcentral" \
    "${FAST_MOUNT}/wordpress/db"
echo "  Fast subdirectories created."

# Bulk tier — media, archives, large files
mkdir -p \
    "${BULK_MOUNT}/immich/photos" \
    "${BULK_MOUNT}/media/movies" \
    "${BULK_MOUNT}/media/tv" \
    "${BULK_MOUNT}/media/music" \
    "${BULK_MOUNT}/calibre" \
    "${BULK_MOUNT}/arm/media" \
    "${BULK_MOUNT}/arm/music" \
    "${BULK_MOUNT}/karakeep"
echo "  Bulk subdirectories created."

echo ""
echo "=== Setup complete ==="
gluster volume list
echo ""
echo "Add to /etc/fstab on ${RK1_HOST} for persistence:"
echo "  localhost:/fast         ${FAST_MOUNT}  glusterfs  defaults,_netdev  0 0"
echo "  ${COMPUTE3_HOST}:/bulk  ${BULK_MOUNT}  glusterfs  defaults,_netdev  0 0"
echo ""
echo "Next: run ./mount-tiered.sh on ${COMPUTE3_HOST} to mount both volumes there."
