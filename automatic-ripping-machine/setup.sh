#!/usr/bin/env bash
# ARM Docker Setup Script
# Run once before: docker compose up -d
# Must be run as a user with sudo access.

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

echo "=== Automatic Ripping Machine — Docker Setup ==="
echo ""

# ── 1. lsscsi ────────────────────────────────────────────────────────────────
if ! command -v lsscsi &>/dev/null; then
    echo "[1/5] Installing lsscsi..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y lsscsi
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y lsscsi
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm lsscsi
    else
        echo "ERROR: Could not detect package manager. Install lsscsi manually and re-run."
        exit 1
    fi
else
    echo "[1/5] lsscsi already installed."
fi

# ── 2. arm user / group ───────────────────────────────────────────────────────
echo "[2/5] Checking arm user..."

if ! getent group arm &>/dev/null; then
    sudo groupadd arm
    echo "  Created group: arm"
fi

if ! id -u arm &>/dev/null; then
    sudo useradd -m -d /home/arm -g arm -s /usr/sbin/nologin arm
    echo "  Created user: arm"
else
    echo "  User arm already exists."
fi

ARM_UID=$(id -u arm)
ARM_GID=$(id -g arm)
echo "  arm UID=$ARM_UID  GID=$ARM_GID"

# ── 3. Storage paths ──────────────────────────────────────────────────────────
echo "[3/5] Storage paths..."
echo "  Press Enter to accept the default shown in brackets."
echo "  To use GlusterFS, enter the mounted path (e.g. /mnt/gluster/arm/media)."
echo ""

read -rp "  ARM home   [/home/arm]:        " INPUT_HOME
read -rp "  Logs       [/home/arm/logs]:   " INPUT_LOGS
read -rp "  Config     [/home/arm/config]: " INPUT_CONFIG
read -rp "  Media out  [/home/arm/media]:  " INPUT_MEDIA
read -rp "  Music out  [/home/arm/music]:  " INPUT_MUSIC

ARM_HOME="${INPUT_HOME:-/home/arm}"
ARM_LOGS="${INPUT_LOGS:-/home/arm/logs}"
ARM_CONFIG="${INPUT_CONFIG:-/home/arm/config}"
ARM_MEDIA="${INPUT_MEDIA:-/home/arm/media}"
ARM_MUSIC="${INPUT_MUSIC:-/home/arm/music}"

# ── 4. Directories ────────────────────────────────────────────────────────────
echo ""
echo "[4/5] Creating directories..."

for DIR in "$ARM_HOME" "$ARM_LOGS" "$ARM_CONFIG" "$ARM_MEDIA" "$ARM_MUSIC"; do
    sudo mkdir -p "$DIR"
    echo "  $DIR"
done
sudo chown -R arm:arm "$ARM_HOME"
# Chown output dirs separately in case they are on a different mount (GlusterFS)
sudo chown -R arm:arm "$ARM_MEDIA" "$ARM_MUSIC" "$ARM_LOGS" "$ARM_CONFIG" 2>/dev/null || true

# ── 5. .env file ──────────────────────────────────────────────────────────────
echo "[5/5] Writing .env..."

DEFAULT_TZ="America/New_York"
read -rp "  Timezone [${DEFAULT_TZ}]: " INPUT_TZ
TZ="${INPUT_TZ:-$DEFAULT_TZ}"

cat > "${SCRIPT_DIR}/.env" <<EOF
# Identity — must match the arm user on this host
ARM_UID=${ARM_UID}
ARM_GID=${ARM_GID}

# Timezone
TZ=${TZ}

# Storage paths
ARM_HOME=${ARM_HOME}
ARM_LOGS=${ARM_LOGS}
ARM_CONFIG=${ARM_CONFIG}
ARM_MEDIA=${ARM_MEDIA}
ARM_MUSIC=${ARM_MUSIC}
EOF

echo "  Written: .env"

# ── Drive detection ───────────────────────────────────────────────────────────
echo ""
echo "=== Optical drives detected on this host ==="
DRIVES=$(lsscsi -g 2>/dev/null | grep -iE "cd|dvd|blu|optical|rom" || true)

if [[ -z "$DRIVES" ]]; then
    echo "  (none found — make sure a drive is connected and powered on)"
else
    echo "$DRIVES"
    echo ""
    echo "Add the corresponding /dev/srN device entries to docker-compose.yml:"
    while IFS= read -r line; do
        DEV=$(echo "$line" | awk '{print $NF}')
        echo "  - ${DEV}:${DEV}"
    done <<< "$DRIVES"
fi

echo ""
echo "Setup complete. Next steps:"
echo "  1. Edit docker-compose.yml and update the devices: section to match your drives above"
echo "  2. docker compose up -d"
echo "  3. Open http://$(hostname -I | awk '{print $1}'):8082 — default login: admin / password"
echo "  4. Go to Settings to configure TRANSCODE, HandBrake preset, MakeMKV key, etc."
