# Nextcloud AIO

Self-hosted file sync and share — an all-in-one Nextcloud deployment that manages its own containers (database, cache, backup, Talk, etc.) through a built-in admin interface. No manual database or Redis setup required.

**Source:** [github.com/nextcloud/all-in-one](https://github.com/nextcloud/all-in-one)

## Services

| Service | Port | Description |
|---------|------|-------------|
| **AIO Admin UI** | 8080 | Initial setup and container management |
| **AIO Admin UI (HTTPS)** | 8443 | Same UI over a valid certificate (after domain setup) |
| **Nextcloud** | 80 / 443 | HTTP redirect and ACME validation / main HTTPS access |

All additional services (PostgreSQL, Redis, Collabora, Talk TURN server) are started and managed automatically by the AIO mastercontainer — they do not appear in the compose file.

## Setup

### 1. Start

```bash
docker compose up -d
```

### 2. Open the AIO admin interface

Navigate to `http://your-server-ip:8080`. You will be shown a one-time passphrase — copy it.

### 3. Enter your domain

AIO requires a publicly resolvable domain name pointing at your server. Enter it in the setup wizard. AIO will:
- Request a Let's Encrypt certificate automatically
- Start all required containers (database, Redis, Nextcloud, Talk, Collabora, ClamAV, Backup)

### 4. Access Nextcloud

Once setup completes, Nextcloud is available at `https://your-domain.com`.

## Custom Data Directory

To store Nextcloud files on a specific drive, uncomment the volume line and environment variable in `docker-compose.yml`:

```yaml
volumes:
  - /mnt/your-drive/nextcloud:/mnt/ncdata

environment:
  NEXTCLOUD_DATADIR: /mnt/ncdata
```

## Behind a Reverse Proxy

If you already have a reverse proxy (e.g. Nginx Proxy Manager), set `SKIP_DOMAIN_VALIDATION: true` and follow the [reverse proxy guide](https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md) in the upstream docs. AIO provides example configs for Nginx, Caddy, Traefik, and NPM.

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `nextcloud/docker-compose.yml` |

3. Click **Deploy the stack**
4. Open `http://your-server-ip:8080` to complete setup

> Note: AIO requires access to the Docker socket to manage its child containers. Portainer must allow this volume mount.

## Volumes

| Volume | Purpose |
|--------|---------|
| `nextcloud_aio_mastercontainer` | AIO configuration and state — do not rename |
| `/var/run/docker.sock` | Docker socket — AIO uses this to start/stop its child containers |

## Maintenance

AIO includes a built-in backup system (Borg) and one-click update for all managed containers — accessible from the AIO admin interface on port 8080.
