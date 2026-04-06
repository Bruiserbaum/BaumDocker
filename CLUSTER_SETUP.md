# BaumDocker — Turing Pi 2 Cluster Setup Guide

This document covers the full setup process for the BaumDocker cluster running on a Turing Pi 2 board, including node configuration, Docker Swarm, storage, automatic updates, and security hardening.

---

## Table of Contents

1. [Hardware Layout](#hardware-layout)
2. [Default Credentials](#default-credentials)
3. [Flashing Node Images](#flashing-node-images)
4. [Accessing the BMC](#accessing-the-bmc)
5. [Connecting to Nodes via Picocom](#connecting-to-nodes-via-picocom)
6. [Enabling SSH on Nodes](#enabling-ssh-on-nodes)
7. [SSH Directly into Nodes](#ssh-directly-into-nodes)
8. [Changing Passwords](#changing-passwords)
9. [Automatic Updates](#automatic-updates)
10. [Docker Swarm Setup](#docker-swarm-setup)
11. [Storage Setup](#storage-setup)
12. [NAS Backup via Rsync over SMB](#nas-backup-via-rsync-over-smb)
13. [Portainer Setup](#portainer-setup)
14. [Maintenance Scripts](#maintenance-scripts)

---

## Hardware Layout

| Slot | Node | Hardware | Storage | Role |
|------|------|----------|---------|------|
| 1 | TuringPiRK1 | Turing RK1 | 256GB NVMe (fast) | Swarm Manager |
| 2 | — | — | — | Empty |
| 3 | TuringPICompute3 | Raspberry Pi CM4 | 2TB SATA (bulk) | Swarm Worker |
| 4 | TuringPICompute4 | Raspberry Pi CM4 | eMMC only | Swarm Worker |

> **Note:** On the Turing Pi 2, NVMe storage is only available to RK1 modules via PCIe. SATA storage is only available on the Node 3 slot. CM4 modules do not support NVMe.

---

## Default Credentials

> ⚠️ **Change all default passwords immediately after first boot.** See [Changing Passwords](#changing-passwords).

| Service | Username | Password | Access |
|---------|----------|----------|--------|
| BMC Web UI | `root` | `turing` | `http://turingpi.local` |
| BMC SSH | `root` | `turing` | `ssh root@turingpi.local` |
| Ubuntu Nodes | `ubuntu` | `ubuntu` | SSH per node IP |

---

## Flashing Node Images

Node images are flashed via the Turing Pi 2 BMC web interface.

1. Navigate to `http://turingpi.local` and log in
2. Go to the **Flash Node** tab
3. Select the target node slot
4. Upload your `.img` file and flash

> ⚠️ **Important:** Ubuntu images flashed via the BMC web interface have SSH disabled by default. You must enable it manually before you can SSH into the node. See [Enabling SSH on Nodes](#enabling-ssh-on-nodes).

### Recommended Images

- **RK1 (Node 1):** Ubuntu 24.04 LTS ARM64
- **CM4 (Nodes 3 & 4):** Ubuntu 24.04 LTS ARM64

---

## Accessing the BMC

The BMC (Board Management Controller) is the central management interface for the Turing Pi 2. It runs independently of the compute nodes.

```bash
ssh root@turingpi.local
# Password: turing (change this immediately)
```

If `turingpi.local` doesn't resolve, use the board's IP address directly.

### Useful BMC Commands

```bash
# Check node power status
tpi power status

# Power on a specific node
tpi power on -n 1

# Power off a specific node
tpi power off -n 1

# Check USB routing
tpi usb -n 1
```

---

## Connecting to Nodes via Picocom

When SSH is not yet available on a node, you can access it directly via serial console from the BMC using `picocom`.

```bash
# From the BMC SSH session:
picocom -b 115200 /dev/ttyS1   # Node 1
picocom -b 115200 /dev/ttyS2   # Node 2
picocom -b 115200 /dev/ttyS3   # Node 3
picocom -b 115200 /dev/ttyS4   # Node 4
```

To **exit picocom**, press `Ctrl+A` then `Ctrl+X`.

> **Tip:** If the console appears unresponsive, the node may be powered off. Power it on first with `tpi power on -n <node>`.

---

## Enabling SSH on Nodes

Since SSH is disabled by default on freshly flashed Ubuntu images, you must enable it via the picocom serial console before SSH access is available.

1. Connect to the node via picocom (see above)
2. Log in with `ubuntu` / `ubuntu`
3. Run the following:

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

4. Verify SSH is running:

```bash
sudo systemctl status ssh
```

5. Get the node's IP address:

```bash
ip addr show
```

6. Exit picocom (`Ctrl+A`, `Ctrl+X`) and SSH in normally from your computer.

---

## SSH Directly into Nodes

Once SSH is enabled on each node, connect directly from your computer:

```bash
ssh ubuntu@<node-ip>
```

### Recommended: Set Hostnames

Set a unique hostname on each node so they are easy to identify:

```bash
sudo hostnamectl set-hostname TuringPiRK1       # Node 1
sudo hostnamectl set-hostname TuringPICompute3  # Node 3
sudo hostnamectl set-hostname TuringPICompute4  # Node 4
```

Update `/etc/hosts` to match:

```bash
sudo nano /etc/hosts
```

Change the `127.0.1.1` line to reflect the new hostname:

```
127.0.1.1  TuringPiRK1
```

---

## Changing Passwords

Change the default password on every node and the BMC immediately after setup.

### Ubuntu Nodes

```bash
passwd
# Enter current password: ubuntu
# Enter new password: <your-password>
```

### BMC

```bash
# SSH into BMC first
ssh root@turingpi.local

passwd
# Enter new password: <your-password>
```

Also change the BMC web UI password via `http://turingpi.local` → **Settings** → **Change Password**.

---

## Automatic Updates

Enable unattended security updates on each node to keep the cluster patched without manual intervention.

### Install and Configure (run on each node)

```bash
sudo apt install -y unattended-upgrades apt-listchanges

sudo dpkg-reconfigure -plow unattended-upgrades
# Select "Yes" when prompted
```

### Verify the Configuration

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

Should contain:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

### Optional: Enable Automatic Reboots (if needed for kernel updates)

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Uncomment and set:

```
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
```

> **Note:** Be cautious with automatic reboots on swarm worker nodes. If all nodes reboot simultaneously, the swarm may become unavailable. Consider staggering reboot times across nodes.

---

## Docker Swarm Setup

### Step 1: Install Docker (run on all nodes)

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

### Step 2: Load Required Kernel Modules (RK1 only)

The RK1 requires some additional kernel modules for Docker Swarm networking:

```bash
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe nf_conntrack
```

Make them load on every boot:

```bash
sudo nano /etc/modules-load.d/ipvs.conf
```

Add:

```
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
```

### Step 3: Initialize the Swarm (Manager — RK1 Node 1)

```bash
docker swarm init --advertise-addr <RK1-IP>
```

This outputs a join command with a token. Copy it — you will need it for the worker nodes.

### Step 4: Join Worker Nodes (Nodes 3 and 4)

Run the join command output from Step 3 on each worker:

```bash
docker swarm join --token <SWMTKN-token> <RK1-IP>:2377
```

### Step 5: Verify the Swarm

Run on the manager (RK1):

```bash
docker node ls
```

All nodes should show as `Ready` and `Active`.

### Step 6: Fix Docker Startup Timing on Workers

Workers can show as `down` in Portainer after a full cluster reboot because Docker starts before the network is fully ready. Fix this on both worker nodes:

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d

sudo nano /etc/systemd/system/docker.service.d/override.conf
```

Add:

```
[Unit]
After=network-online.target
Wants=network-online.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## Storage Setup

### Overview

| Node | Storage | Mount Point | Purpose |
|------|---------|-------------|---------|
| TuringPiRK1 (Node 1) | 256GB NVMe | `/mnt/nvme` | Fast storage — Docker volumes, databases |
| TuringPICompute3 (Node 3) | 2TB SATA | `/mnt/sata` | Bulk storage — media, large files, backups |

### NVMe Setup (Node 1 — RK1)

```bash
# Format the drive
sudo mkfs.ext4 /dev/nvme0n1

# Create mount point and mount
sudo mkdir -p /mnt/nvme
sudo mount /dev/nvme0n1 /mnt/nvme

# Make persistent — get UUID first
sudo blkid /dev/nvme0n1
```

Add to `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

```
UUID=<your-uuid>  /mnt/nvme  ext4  defaults  0  2
```

Create directory structure:

```bash
sudo mkdir -p /mnt/nvme/docker-volumes
sudo mkdir -p /mnt/nvme/data
sudo chown -R $USER:$USER /mnt/nvme
```

### Point Docker at NVMe (Node 1 — RK1)

```bash
sudo nano /etc/docker/daemon.json
```

Add:

```json
{
  "data-root": "/mnt/nvme/docker-volumes"
}
```

```bash
sudo systemctl restart docker
docker info | grep "Docker Root Dir"
```

### SATA Setup (Node 3 — CM4)

```bash
# Wipe any old partitions and repartition cleanly
sudo wipefs -a /dev/sda
sudo parted /dev/sda mklabel gpt
sudo parted /dev/sda mkpart primary ext4 0% 100%

# Format
sudo mkfs.ext4 /dev/sda1

# Mount
sudo mkdir -p /mnt/sata
sudo mount /dev/sda1 /mnt/sata

# Make persistent
sudo blkid /dev/sda1
```

Add to `/etc/fstab`:

```
UUID=<your-uuid>  /mnt/sata  ext4  defaults  0  2
```

Create directory structure:

```bash
sudo mkdir -p /mnt/sata/bulk
sudo mkdir -p /mnt/sata/media
sudo mkdir -p /mnt/sata/backups
sudo chown -R $USER:$USER /mnt/sata
```

### Create Named Docker Volumes

On **Node 1 (RK1)**:

```bash
docker volume create --driver local \
  --opt type=none \
  --opt device=/mnt/nvme/data \
  --opt o=bind \
  fast-storage
```

On **Node 3 (CM4)**:

```bash
docker volume create --driver local \
  --opt type=none \
  --opt device=/mnt/sata/bulk \
  --opt o=bind \
  bulk-storage
```

### Using Storage in Docker Swarm Stacks

Use placement constraints in your compose files to ensure containers use the right storage on the right node:

```yaml
services:
  fast-app:
    image: yourimage
    volumes:
      - fast-storage:/data
    deploy:
      placement:
        constraints:
          - node.hostname == TuringPiRK1

  bulk-app:
    image: yourimage
    volumes:
      - bulk-storage:/data
    deploy:
      placement:
        constraints:
          - node.hostname == TuringPICompute3

volumes:
  fast-storage:
    external: true
  bulk-storage:
    external: true
```

---

## NAS Backup via Rsync over SMB

The bulk SATA storage on Node 3 is synced weekly to an existing NAS via SMB for offsite redundancy.

### Step 1: Install Required Packages (Node 3)

```bash
sudo apt install -y cifs-utils rsync
```

### Step 2: Create Mount Point and Credentials File

```bash
sudo mkdir -p /mnt/nas
```

Store your NAS credentials securely:

```bash
sudo nano /etc/nas-credentials
```

Add:

```
username=<your-nas-username>
password=<your-nas-password>
domain=WORKGROUP
```

Lock down the credentials file:

```bash
sudo chmod 600 /etc/nas-credentials
```

### Step 3: Mount the SMB Share Permanently

Add to `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Add:

```
//<NAS-IP>/<share-name>  /mnt/nas  cifs  credentials=/etc/nas-credentials,iocharset=utf8,vers=3.0,_netdev  0  0
```

Mount it:

```bash
sudo mount -a
```

Verify:

```bash
df -h | grep nas
```

### Step 4: Create the Rsync Script

```bash
sudo nano /usr/local/bin/backup-to-nas.sh
```

Add:

```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
LOG="/var/log/nas-backup.log"

echo "[$DATE] Starting NAS backup..." >> $LOG

rsync -av --delete \
  /mnt/sata/bulk/ \
  /mnt/nas/baum-docker-backup/ >> $LOG 2>&1

echo "[$DATE] NAS backup complete." >> $LOG
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/backup-to-nas.sh
```

Test it manually:

```bash
/usr/local/bin/backup-to-nas.sh
cat /var/log/nas-backup.log
```

### Step 5: Schedule Weekly via Cron

```bash
crontab -e
```

Add (runs every Sunday at 2:00 AM):

```
0 2 * * 0 /usr/local/bin/backup-to-nas.sh
```

---

## Portainer Setup

Portainer provides a web UI for managing the Docker Swarm. It runs on the manager node (RK1) and agents run on all worker nodes.

### Deploy Portainer Stack (run on RK1)

```bash
# Create volume for Portainer data
docker volume create portainer_data

# Create the stack file
nano portainer-agent-stack.yml
```

Paste:

```yaml
version: '3.2'

services:
  agent:
    image: portainer/agent:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - agent_network
    deploy:
      mode: global

  portainer:
    image: portainer/portainer-ce:latest
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - portainer_data:/data
    networks:
      - agent_network
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager

networks:
  agent_network:
    driver: overlay
    attachable: true

volumes:
  portainer_data:
```

Deploy:

```bash
docker stack deploy -c portainer-agent-stack.yml portainer
```

Access Portainer at:

- HTTP: `http://<RK1-IP>:9000`
- HTTPS: `https://<RK1-IP>:9443`

> ⚠️ Set your admin password immediately after first access. Portainer times out the initial setup after a few minutes. If it times out, force restart the service with `docker service update --force <portainer-service-name>`.

---

## Maintenance Scripts

### Restart Docker Workers

If worker nodes show as `down` in Portainer after a reboot, run this script from your local machine or the BMC:

```bash
#!/bin/bash
# restart-workers.sh
# Restarts Docker on all worker nodes to reconnect them to the swarm

WORKERS=("192.168.5.7" "192.168.5.8")
USER="ubuntu"

for NODE in "${WORKERS[@]}"; do
  echo "Restarting Docker on $NODE..."
  ssh $USER@$NODE "sudo systemctl restart docker"
  echo "Done: $NODE"
done

echo "All workers restarted. Check Portainer for status."
```

Save as `restart-workers.sh`, make executable, and run when needed:

```bash
chmod +x restart-workers.sh
./restart-workers.sh
```

### Rejoin a Worker to the Swarm

If a worker node fully loses its swarm connection:

```bash
# On the manager (RK1) — get a fresh join token
docker swarm join-token worker

# On the worker node that dropped off
docker swarm leave
docker swarm join --token <SWMTKN-token> <RK1-IP>:2377

# Verify on manager
docker node ls
```

### Check Swarm and Service Health

```bash
# Overall swarm status
docker node ls

# All running services
docker service ls

# Detailed status of a specific service
docker service ps <service-name>

# Check Portainer specifically
docker stack services portainer
```
