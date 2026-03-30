#!/usr/bin/env bash
# GlusterFS Volume Setup Script
# Run ONCE after: docker compose up -d
# Initialises the 'swarm' volume and mounts it on this host.
# On subsequent nodes: run mount.sh only — do NOT run setup.sh again.

set -euo pipefail

VOLUME="swarm"
BRICK_PATH="/gluster/bricks/${VOLUME}"
MOUNT_POINT="/mnt/gluster"
THIS_HOST=$(hostname -f)

echo "=== GlusterFS Volume Setup ==="
echo "  Host:        $THIS_HOST"
echo "  Volume:      $VOLUME"
echo "  Brick path:  $BRICK_PATH  (inside container)"
echo "  Mount point: $MOUNT_POINT  (on host)"
echo ""

# ── Wait for glusterd ─────────────────────────────────────────────────────────
echo "[1/5] Waiting for glusterd to be ready..."
for i in $(seq 1 12); do
    if docker exec glusterfs gluster peer status &>/dev/null; then
        echo "  glusterd is ready."
        break
    fi
    echo "  Attempt $i/12 — waiting 5s..."
    sleep 5
done

# ── Create brick directory ────────────────────────────────────────────────────
echo "[2/5] Creating brick directory inside container..."
docker exec glusterfs mkdir -p "$BRICK_PATH"

# ── Create volume ─────────────────────────────────────────────────────────────
echo "[3/5] Creating GlusterFS volume '$VOLUME'..."
# Single-brick distribute volume — expandable to replica/distribute when more nodes join.
# The 'force' flag allows creation on non-XFS filesystems.
docker exec glusterfs \
    gluster volume create "$VOLUME" \
    transport tcp \
    "${THIS_HOST}:${BRICK_PATH}" \
    force

echo "[4/5] Starting volume and applying settings..."
docker exec glusterfs gluster volume start "$VOLUME"

# Allow all clients — tighten to a subnet in production (e.g. 192.168.1.*)
docker exec glusterfs gluster volume set "$VOLUME" auth.allow "*"
# Improve small-file performance
docker exec glusterfs gluster volume set "$VOLUME" performance.cache-size 256MB
docker exec glusterfs gluster volume set "$VOLUME" performance.io-thread-count 16

docker exec glusterfs gluster volume info "$VOLUME"

# ── Mount on this host ────────────────────────────────────────────────────────
echo "[5/5] Mounting volume on this host at $MOUNT_POINT..."

if ! command -v mount.glusterfs &>/dev/null; then
    echo "  Installing glusterfs-client..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y glusterfs-client
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y glusterfs-fuse
    fi
fi

sudo mkdir -p "$MOUNT_POINT"
sudo mount -t glusterfs "localhost:/${VOLUME}" "$MOUNT_POINT"

echo ""
echo "=== Setup complete ==="
echo ""
echo "GlusterFS volume '$VOLUME' is mounted at: $MOUNT_POINT"
echo ""
echo "To persist across reboots, add to /etc/fstab:"
echo "  localhost:/${VOLUME}  ${MOUNT_POINT}  glusterfs  defaults,_netdev  0  0"
echo ""
echo "To add a second swarm node to this volume, on that node run:"
echo "  1. docker compose up -d               (start glusterfs container)"
echo "  2. docker exec glusterfs gluster peer probe $THIS_HOST"
echo "  3. docker exec glusterfs gluster volume add-brick $VOLUME replica 2 \$(hostname -f):${BRICK_PATH} force"
echo "  4. ./mount.sh $THIS_HOST"
