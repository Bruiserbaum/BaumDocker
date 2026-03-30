# GlusterFS

Distributed network filesystem for Docker Swarm shared storage. Runs a GlusterFS server in a privileged container with host networking so every swarm node can mount the same volume — giving all your Docker stacks a common persistent storage path.

**Source:** [github.com/gluster/gluster-containers](https://github.com/gluster/gluster-containers)

## How it works

```
┌────────────────── Swarm Node 1 (this server) ──────────────────┐
│  glusterfs container  ──►  brick data at /mnt/gluster-bricks   │
│  host mount at /mnt/gluster  ◄──────────────────────────────── │
│                                                                  │
│  docker stack: immich    ──► bind mount /mnt/gluster/immich     │
│  docker stack: nextcloud ──► bind mount /mnt/gluster/nextcloud  │
└──────────────────────────────────────────────────────────────────┘
          ▲  GlusterFS protocol (TCP port 24007 + bricks)
┌─────────┴──────── Swarm Node 2 (future) ────────────────────────┐
│  glusterfs container  ──►  replicated brick                     │
│  host mount at /mnt/gluster  (same path, replicated data)       │
└──────────────────────────────────────────────────────────────────┘
```

Other stacks reference GlusterFS simply as a host bind mount:
```yaml
volumes:
  - /mnt/gluster/myapp:/data
```

No Docker volume plugin or special driver needed.

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

## Deploying via Portainer

This stack uses `network_mode: host` and `privileged: true`. Deploy it from the CLI on each node rather than via Portainer to ensure the setup script runs correctly:

```bash
docker compose up -d
sudo ./setup.sh   # first node only
sudo ./mount.sh   # subsequent nodes
```
