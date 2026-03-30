# Automatic Ripping Machine (ARM)

Automatically detects when an optical disc (CD, DVD, Blu-ray) is inserted, rips it, transcodes the content, and ejects when done — all without interaction.

**Source:** [github.com/automatic-ripping-machine/automatic-ripping-machine](https://github.com/automatic-ripping-machine/automatic-ripping-machine)
**Fork:** [github.com/Bruiserbaum/automatic-ripping-machine](https://github.com/Bruiserbaum/automatic-ripping-machine)

## Services

| Service | Port | Description |
|---------|------|-------------|
| **ARM Web UI** | 8082 | Dashboard — job history, logs, disc info, settings |

## Setup

### 1. Find your optical drive device

```bash
lsscsi -g
```

Add one `devices` entry per drive to `docker-compose.yml` (e.g. `/dev/sr0`, `/dev/sr1`). Only `/dev/sr0` is enabled by default.

### 2. Set your timezone and UID/GID

Edit `docker-compose.yml`:

```yaml
environment:
  - ARM_UID=1000   # match output of: id -u
  - ARM_GID=1000   # match output of: id -g
  - TZ=America/New_York
```

### 3. Create host directories

```bash
mkdir -p /home/arm/{logs,media,music,config}
```

### 4. Start

```bash
docker compose up -d
```

### 5. Access the UI

`http://your-server-ip:8082`

## Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `/home/arm` | `/home/arm` | ARM home directory |
| `/home/arm/logs` | `/home/arm/logs` | Rip and transcode logs |
| `/home/arm/media` | `/home/arm/media` | DVD/Blu-ray output |
| `/home/arm/music` | `/home/arm/music` | CD audio output |
| `/home/arm/config` | `/etc/arm/config` | ARM configuration files |

To redirect output to a different drive, change the host-side paths to an absolute path on your storage:

```yaml
- /mnt/your-drive/arm/media:/home/arm/media
- /mnt/your-drive/arm/music:/home/arm/music
```

## Configuration

ARM's main config file is `arm.yaml`, which ARM creates in `/home/arm/config` on first run. Key settings:

| Setting | Description |
|---------|-------------|
| `TRANSCODE` | Enable/disable transcoding after rip |
| `HANDBRAKE_CLI_PRESET` | HandBrake preset (e.g. `HQ 1080p30 Surround`) |
| `MAX_HITS` | How many title matches to look up online |
| `NOTIFY_RIP` / `NOTIFY_TRANSCODE` | Enable notifications (Pushbullet, Pushover, etc.) |

Edit via the web UI (Settings tab) or directly in `/home/arm/config/arm.yaml`.

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `automatic-ripping-machine/docker-compose.yml` |

3. Under **Environment variables**, add `ARM_UID`, `ARM_GID`, and `TZ`
4. Click **Deploy the stack**

> Note: Device passthrough (`/dev/sr0`) requires Portainer to be running on the same host as the optical drive. This stack cannot be deployed to a remote agent without device access.
