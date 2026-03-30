#!/usr/bin/env bash
# ARM Docker Setup Script
# Run once before: docker compose up -d
# Must be run as a user with sudo access.

set -euo pipefail

echo "=== Automatic Ripping Machine — Docker Setup ==="
echo ""

# ── 1. lsscsi ────────────────────────────────────────────────────────────────
if ! command -v lsscsi &>/dev/null; then
    echo "[1/4] Installing lsscsi..."
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
    echo "[1/4] lsscsi already installed."
fi

# ── 2. arm user / group ───────────────────────────────────────────────────────
echo "[2/4] Checking arm user..."

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

# ── 3. directories ────────────────────────────────────────────────────────────
echo "[3/4] Creating directories..."

sudo mkdir -p /home/arm/{logs,media,music,config}
sudo chown -R arm:arm /home/arm
echo "  /home/arm/{logs,media,music,config} — owned by arm:arm"

# ── 4. .env file ──────────────────────────────────────────────────────────────
echo "[4/4] Writing .env..."

# Prompt for timezone
DEFAULT_TZ="America/New_York"
read -rp "  Timezone [${DEFAULT_TZ}]: " INPUT_TZ
TZ="${INPUT_TZ:-$DEFAULT_TZ}"

cat > "$(dirname "$0")/.env" <<EOF
ARM_UID=${ARM_UID}
ARM_GID=${ARM_GID}
TZ=${TZ}
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
echo "  1. Edit docker-compose.yml and add/remove devices entries to match your drives above"
echo "  2. docker compose up -d"
echo "  3. Open http://\$(hostname -I | awk '{print \$1}'):8082 — default login: admin / password"
