# GlusterFS

Distributed network filesystem for Docker Swarm shared storage. Runs a GlusterFS server in a privileged container with host networking so every swarm node can mount the same volume — giving all your Docker stacks a common persistent storage path.

**Source:** [github.com/gluster/gluster-containers](https://github.com/gluster/gluster-containers)

## How it works — Tiered Storage (Turing Pi)

Two separate GlusterFS volumes map to the two storage tiers on the cluster:

```
┌─── TuringPiRK1 (NVMe) ──────────────────────────────────────────────────┐
│  glusterfs container  ──►  /mnt/nvme/docker-volumes/gluster-bricks/fast  │
│  host mount at /mnt/gluster-fast  ◄─────────────────────────────────────│
│                                                                            │
│  immich postgres  ──► /mnt/gluster-fast/immich/postgres                   │
│  immich ML cache  ──► /mnt/gluster-fast/immich/model-cache                │
│  vaultwarden      ──► /mnt/gluster-fast/vaultwarden                       │
└────────────────────────────────────────────────────────────────────────────┘
          ▲  GlusterFS protocol (TCP 24007)
┌─── TuringPICompute3 (SATA) ─────────────────────────────────────────────┐
│  glusterfs container  ──►  /mnt/gluster-bricks/bulk                      │
│  host mount at /mnt/gluster-bulk  ◄─────────────────────────────────────│
│                                                                            │
│  immich photos    ──► /mnt/gluster-bulk/immich/photos                     │
│  jellyfin/plex    ──► /mnt/gluster-bulk/media/{movies,tv,music}           │
│  ARM rips         ──► /mnt/gluster-bulk/arm/{media,music}                 │
└────────────────────────────────────────────────────────────────────────────┘
```

Other stacks reference the mounts as plain host bind mounts — no Docker plugin needed:
```yaml
volumes:
  - /mnt/gluster-fast/myapp:/data    # databases, config
  - /mnt/gluster-bulk/myapp:/media   # large files
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 24007 | TCP | glusterd management daemon |
| 24008 | TCP | Management backup channel |
| 49152+ | TCP | One port per brick (dynamically assigned) |

These are exposed on the host directly (`network_mode: host`). Open these between all swarm nodes in your firewall.

## Setup (first node)

### 1. (Optional) Set a custom brick storage path

By default bricks are stored at `/mnt/gluster-bricks`. To use a different drive:

```bash
export BRICK_PATH=/mnt/your-drive/gluster-bricks
```

Or create a `.env` file:
```env
BRICK_PATH=/mnt/your-drive/gluster-bricks
```

### 2. Start the container

```bash
docker compose up -d
```

### 3. Run setup (once only)

```bash
chmod +x setup.sh && sudo ./setup.sh
```

This script:
- Waits for glusterd to be ready
- Creates the brick directory
- Creates and starts a GlusterFS volume named `swarm`
- Installs `glusterfs-client` on the host if needed
- Mounts the volume at `/mnt/gluster`
- Prints the `/etc/fstab` line for persistence

### 4. Use the shared path in other stacks

```yaml
# In any other docker-compose.yml on this host:
services:
  myapp:
    volumes:
      - /mnt/gluster/myapp:/data
```

Create subdirectories as needed:
```bash
sudo mkdir -p /mnt/gluster/{immich,nextcloud,vaultwarden}
```

## Adding a second swarm node

On the new node:

```bash
# 1. Copy this folder to the new node and start the container
docker compose up -d

# 2. From the new node, probe the first node
docker exec glusterfs gluster peer probe <node1-ip>

# 3. Add the new brick (converts to 2-way replica)
docker exec glusterfs gluster volume add-brick swarm replica 2 \
  $(hostname -f):/gluster/bricks/swarm force

# 4. Mount on the new host
chmod +x mount.sh && sudo ./mount.sh <node1-ip>
```

The volume now replicates data across both nodes. Swarm services on either node read and write to `/mnt/gluster` and see the same files.

## mount.sh

Mount the GlusterFS volume on any host (after setup has been run on the first node):

```bash
sudo ./mount.sh <gluster-server-ip> [volume] [mount-point]
# defaults: volume=swarm  mount-point=/mnt/gluster
```

## Volumes and persistence

| Host Path | Purpose |
|-----------|---------|
| `/etc/glusterfs` | GlusterFS daemon configuration |
| `/var/lib/glusterd` | Volume metadata and peer info — must persist |
| `/var/log/glusterfs` | Daemon and brick logs |
| `$BRICK_PATH` (default `/mnt/gluster-bricks`) | Actual brick data |

> The `/etc/glusterfs` and `/var/lib/glusterd` paths are mounted directly on the host (not as named volumes) so that the glusterd daemon config survives container recreations without any data copy step.

## Tiered Storage on Turing Pi / Cluster Nodes

In a Turing Pi or similar ARM cluster, individual nodes often have very different storage hardware — an RK1 or CM4 module with an NVMe M.2 drive alongside compute nodes backed by larger SATA drives. GlusterFS lets you create separate volumes per storage tier so databases and latency-sensitive workloads land on NVMe while media libraries and bulk data land on SATA.

### Architecture

```
┌─── TuringPiRK1 ──────────────────────────────────────────────┐
│  NVMe M.2  ──►  /mnt/nvme-bricks  (GlusterFS brick: fast)   │
│  host mount ◄──  /mnt/gluster-fast                           │
└──────────────────────────────────────────────────────────────┘
          ▲  GlusterFS protocol
┌─── TuringPICompute3 ─────────────────────────────────────────┐
│  SATA HDD  ──►  /mnt/sata-bricks  (GlusterFS brick: bulk)   │
│  host mount ◄──  /mnt/gluster-bulk                           │
└──────────────────────────────────────────────────────────────┘
```

### 1. Run setup-tiered.sh on TuringPiRK1

`setup-tiered.sh` handles everything in one pass from TuringPiRK1:
- Waits for glusterd to be ready
- Peers with TuringPICompute3
- Creates brick directories on both nodes
- Creates and starts the `fast` (NVMe) and `bulk` (SATA) GlusterFS volumes
- Applies performance tuning per tier
- Mounts both volumes on TuringPiRK1
- Creates subdirectories for all BaumDocker stacks under each tier

```bash
chmod +x setup-tiered.sh && sudo ./setup-tiered.sh
```

### 2. Run mount-tiered.sh on all other nodes

On TuringPICompute3 and any additional swarm node, run:

```bash
chmod +x mount-tiered.sh && sudo ./mount-tiered.sh
# defaults to TuringPiRK1 (fast) and TuringPICompute3 (bulk)
# or: ./mount-tiered.sh <rk1-host> <compute3-host>
```

The script installs glusterfs-client if needed, mounts both volumes, and prints the `/etc/fstab` lines for persistence.

### 2. Create named Docker volumes backed by each tier

```bash
# On the manager node
docker volume create \
  --driver local \
  --opt type=none \
  --opt o=bind \
  --opt device=/mnt/gluster-fast \
  fast-storage

docker volume create \
  --driver local \
  --opt type=none \
  --opt o=bind \
  --opt device=/mnt/gluster-bulk \
  bulk-storage
```

### 3. Pin services to the right node with placement constraints

Use Swarm placement constraints to ensure a service always runs on the node whose storage tier it needs:

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

> **Why placement constraints?** Named volumes created with `--opt type=none` are local to the node they were created on. The constraint guarantees the container that mounts the volume always starts on the node where the volume exists — without it, Swarm may schedule the container on a different node and fail to find the volume.

### Typical tier assignments

| Workload | Tier | Path |
|----------|------|------|
| Databases (PostgreSQL, MariaDB) | Fast (NVMe) | `/mnt/gluster-fast` |
| App config / small state | Fast (NVMe) | `/mnt/gluster-fast` |
| Media libraries (Jellyfin, Immich) | Bulk (SATA) | `/mnt/gluster-bulk` |
| Backups, archives, large downloads | Bulk (SATA) | `/mnt/gluster-bulk` |

### Node labels (alternative to hostname constraints)

If your node names change or you want more flexibility, use node labels instead:

```bash
docker node update --label-add storage=nvme  TuringPiRK1
docker node update --label-add storage=sata  TuringPICompute3
```

```yaml
deploy:
  placement:
    constraints:
      - node.labels.storage == nvme
```

---

## Deploying via Portainer

This stack uses `network_mode: host` and `privileged: true`. Deploy it from the CLI on each node rather than via Portainer to ensure the setup script runs correctly:

```bash
docker compose up -d
sudo ./setup.sh   # first node only
sudo ./mount.sh   # subsequent nodes
```
