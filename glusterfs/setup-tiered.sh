#!/usr/bin/env bash
# GlusterFS Tiered Volume Setup — Turing Pi Cluster
#
# Creates two separate GlusterFS volumes:
#   fast  — NVMe brick on TuringPiRK1  → mounted at /mnt/gluster-fast
#   bulk  — SATA brick on TuringPICompute3 → mounted at /mnt/gluster-bulk
#
# Run this script ONCE from TuringPiRK1 after:
#   1. docker compose up -d  (on TuringPiRK1)
#   2. docker compose up -d  (on TuringPICompute3)
#   3. Peer the two nodes together (step 2 below)
#
# On TuringPICompute3: run mount-tiered.sh after this script completes.

set -euo pipefail

# ── Node configuration ────────────────────────────────────────────────────────
RK1_HOST="TuringPiRK1"          # NVMe node — fast volume lives here
COMPUTE3_HOST="TuringPICompute3" # SATA node — bulk volume lives here

# Brick paths INSIDE the glusterfs container (maps to BRICK_PATH on host)
# TuringPiRK1 compose should have BRICK_PATH=/mnt/nvme/docker-volumes/gluster-bricks
# TuringPICompute3 compose can use the default /mnt/gluster-bricks
FAST_BRICK="/gluster/bricks/fast"
BULK_BRICK="/gluster/bricks/bulk"

FAST_MOUNT="/mnt/gluster-fast"
BULK_MOUNT="/mnt/gluster-bulk"

echo "=== GlusterFS Tiered Volume Setup ==="
echo "  Fast volume:  ${RK1_HOST}:${FAST_BRICK}  ->  ${FAST_MOUNT}"
echo "  Bulk volume:  ${COMPUTE3_HOST}:${BULK_BRICK}  ->  ${BULK_MOUNT}"
echo ""

# ── 1. Wait for glusterd on this node ────────────────────────────────────────
echo "[1/7] Waiting for glusterd to be ready on ${RK1_HOST}..."
for i in $(seq 1 12); do
    if docker exec glusterfs gluster peer status &>/dev/null; then
        echo "  glusterd is ready."
        break
    fi
    echo "  Attempt $i/12 — waiting 5s..."
    sleep 5
done

# ── 2. Peer with TuringPICompute3 ────────────────────────────────────────────
echo "[2/7] Probing peer ${COMPUTE3_HOST}..."
docker exec glusterfs gluster peer probe "${COMPUTE3_HOST}" || true
sleep 3
docker exec glusterfs gluster peer status

# ── 3. Create brick directories ───────────────────────────────────────────────
echo "[3/7] Creating brick directories..."
docker exec glusterfs mkdir -p "${FAST_BRICK}"
# Bulk brick is on TuringPICompute3 — SSH to create it there
ssh "${COMPUTE3_HOST}" "docker exec glusterfs mkdir -p '${BULK_BRICK}'" \
    || echo "  WARNING: Could not SSH to ${COMPUTE3_HOST} to create bulk brick dir."
echo "  (If the SSH step failed, run on ${COMPUTE3_HOST}:)"
echo "  docker exec glusterfs mkdir -p ${BULK_BRICK}"

# ── 4. Create the fast volume ─────────────────────────────────────────────────
echo "[4/7] Creating 'fast' volume (NVMe on ${RK1_HOST})..."
docker exec glusterfs \
    gluster volume create fast \
    transport tcp \
    "${RK1_HOST}:${FAST_BRICK}" \
    force

docker exec glusterfs gluster volume start fast
docker exec glusterfs gluster volume set fast auth.allow "*"
docker exec glusterfs gluster volume set fast performance.cache-size 512MB
docker exec glusterfs gluster volume set fast performance.io-thread-count 16
docker exec glusterfs gluster volume set fast performance.read-ahead on
echo "  'fast' volume created and started."

# ── 5. Create the bulk volume ─────────────────────────────────────────────────
echo "[5/7] Creating 'bulk' volume (SATA on ${COMPUTE3_HOST})..."
docker exec glusterfs \
    gluster volume create bulk \
    transport tcp \
    "${COMPUTE3_HOST}:${BULK_BRICK}" \
    force

docker exec glusterfs gluster volume start bulk
docker exec glusterfs gluster volume set bulk auth.allow "*"
docker exec glusterfs gluster volume set bulk performance.cache-size 256MB
docker exec glusterfs gluster volume set bulk performance.io-thread-count 8
echo "  'bulk' volume created and started."

# ── 6. Install glusterfs-client and mount on RK1 ─────────────────────────────
echo "[6/7] Mounting volumes on ${RK1_HOST}..."

if ! command -v mount.glusterfs &>/dev/null; then
    echo "  Installing glusterfs-client..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y glusterfs-client
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y glusterfs-fuse
    fi
fi

sudo mkdir -p "${FAST_MOUNT}"
sudo mount -t glusterfs "localhost:/fast" "${FAST_MOUNT}"
echo "  ${FAST_MOUNT} mounted."

sudo mkdir -p "${BULK_MOUNT}"
sudo mount -t glusterfs "${COMPUTE3_HOST}:/bulk" "${BULK_MOUNT}"
echo "  ${BULK_MOUNT} mounted."

# ── 7. Create stack subdirectories ───────────────────────────────────────────
echo "[7/7] Creating stack subdirectories..."

# Fast tier — databases, config, small state
sudo mkdir -p \
    "${FAST_MOUNT}/immich/postgres" \
    "${FAST_MOUNT}/immich/model-cache" \
    "${FAST_MOUNT}/vaultwarden" \
    "${FAST_MOUNT}/authentik/postgres" \
    "${FAST_MOUNT}/meshcentral" \
    "${FAST_MOUNT}/wordpress/db"
echo "  Fast subdirectories created."

# Bulk tier — media, archives, large files
sudo mkdir -p \
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
echo ""
echo "Volumes:"
docker exec glusterfs gluster volume list
echo ""
echo "Add to /etc/fstab on ${RK1_HOST} for persistence:"
echo "  localhost::/fast   ${FAST_MOUNT}   glusterfs  defaults,_netdev  0 0"
echo "  ${COMPUTE3_HOST}:/bulk  ${BULK_MOUNT}  glusterfs  defaults,_netdev  0 0"
echo ""
echo "Next: run ./mount-tiered.sh on ${COMPUTE3_HOST} to mount both volumes there."
