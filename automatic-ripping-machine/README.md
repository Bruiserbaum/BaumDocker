# Automatic Ripping Machine (ARM)

Automatically detects when an optical disc (CD, DVD, Blu-ray) is inserted, rips it, transcodes the content, and ejects when done — all without interaction.

**Source:** [github.com/automatic-ripping-machine/automatic-ripping-machine](https://github.com/automatic-ripping-machine/automatic-ripping-machine)
**Fork:** [github.com/Bruiserbaum/automatic-ripping-machine](https://github.com/Bruiserbaum/automatic-ripping-machine)

## Services

| Service | Port | Description |
|---------|------|-------------|
| **ARM Web UI** | 8082 | Dashboard — job history, logs, disc info, settings |

## Setup

### Option A — Automated (recommended)

```bash
chmod +x setup.sh && sudo ./setup.sh
```

`setup.sh` handles everything in one pass:
- Installs `lsscsi` if not present
- Creates the `arm` user and group on the host
- Creates `/home/arm/{logs,media,music,config}` with correct ownership
- Prompts for your timezone and writes a `.env` file with the correct `ARM_UID`/`ARM_GID`
- Detects optical drives and prints the exact `devices:` lines to add to `docker-compose.yml`

After it runs, edit `docker-compose.yml` to add your detected drives, then:

```bash
docker compose up -d
```

### Option B — Manual

**1. Create the arm user and directories**

```bash
sudo useradd -m -d /home/arm -g arm arm
sudo mkdir -p /home/arm/{logs,media,music,config}
sudo chown -R arm:arm /home/arm
```

**2. Find your optical drive**

```bash
lsscsi -g
```

Add one `devices` entry per drive to `docker-compose.yml`.

**3. Write a `.env` file**

```bash
echo "ARM_UID=$(id -u arm)" >> .env
echo "ARM_GID=$(id -g arm)" >> .env
echo "TZ=America/New_York"  >> .env
```

**4. Start**

```bash
docker compose up -d
```

### Access the UI

`http://your-server-ip:8082` — default login: `admin` / `password`

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
