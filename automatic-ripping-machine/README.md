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
- Prompts for each storage path — enter a GlusterFS path (e.g. `/mnt/gluster/arm/media`) or press Enter to keep the default under `/home/arm`
- Creates all directories with correct ownership
- Prompts for timezone
- Writes a complete `.env` file
- Detects optical drives and prints the exact `devices:` lines to add to `docker-compose.yml`

After it runs, update the `devices:` section in `docker-compose.yml` with your drive(s), then:

```bash
docker compose up -d
```

### Option B — Manual

**1. Create the arm user**

```bash
sudo groupadd arm
sudo useradd -m -d /home/arm -g arm -s /usr/sbin/nologin arm
```

**2. Copy and edit `.env`**

```bash
cp .env.example .env
```

Set `ARM_UID` and `ARM_GID` to match the arm user:

```bash
sed -i "s/^ARM_UID=.*/ARM_UID=$(id -u arm)/" .env
sed -i "s/^ARM_GID=.*/ARM_GID=$(id -g arm)/" .env
```

Update `ARM_MEDIA` and `ARM_MUSIC` if you want output on GlusterFS or a separate drive.

**3. Create directories and set ownership**

```bash
source .env
for DIR in "$ARM_HOME" "$ARM_LOGS" "$ARM_CONFIG" "$ARM_MEDIA" "$ARM_MUSIC"; do
    sudo mkdir -p "$DIR" && sudo chown arm:arm "$DIR"
done
```

**4. Find your optical drive**

```bash
lsscsi -g
```

Add one `devices:` entry per drive to `docker-compose.yml`.

**5. Start**

```bash
docker compose up -d
```

### Access the UI

`http://your-server-ip:8082` — default login: `admin` / `password`

---

## Storage Paths

All storage paths are configured in `.env` and injected into the compose file as volume mounts.

| Variable | Default | Description |
|----------|---------|-------------|
| `ARM_HOME` | `/home/arm` | ARM working directory — database, UI state |
| `ARM_LOGS` | `/home/arm/logs` | Rip and transcode log files |
| `ARM_CONFIG` | `/home/arm/config` | `arm.yaml` and supporting config |
| `ARM_MEDIA` | `/home/arm/media` | DVD / Blu-ray rip output |
| `ARM_MUSIC` | `/home/arm/music` | CD audio rip output |

### Using GlusterFS

Point `ARM_MEDIA` and `ARM_MUSIC` at your GlusterFS mount. Keep `ARM_HOME`, `ARM_LOGS`, and `ARM_CONFIG` local for lower latency on small files.

```env
ARM_HOME=/home/arm
ARM_LOGS=/home/arm/logs
ARM_CONFIG=/home/arm/config
ARM_MEDIA=/mnt/gluster/arm/media
ARM_MUSIC=/mnt/gluster/arm/music
```

Make sure the GlusterFS mount exists and the target directories are owned by `arm:arm` before starting the container.

---

## Configuration

ARM reads its settings from `arm.yaml`, which is generated in `ARM_CONFIG` on first run. The key options can be changed via the **Settings** tab in the web UI or by editing the file directly.

| Setting | Default | Description |
|---------|---------|-------------|
| `TRANSCODE` | `true` | Transcode ripped content with HandBrake |
| `TRANSCODE_MOVIE` | `true` | Transcode movies |
| `TRANSCODE_TV` | `true` | Transcode TV episodes |
| `HANDBRAKE_CLI_PRESET` | `HQ 1080p30 Surround` | HandBrake preset name |
| `RIPMETHOD` | `mkv` | `mkv` = MakeMKV, `dd` = raw disc copy |
| `MAINFEATURE` | `false` | Rip only the longest title (main feature only) |
| `MINLENGTH` | `600` | Minimum title length in seconds |
| `MAXLENGTH` | `99999` | Maximum title length in seconds |
| `EXTRAS` | `true` | Rip bonus features and extras |
| `METADATA_PROVIDER` | `tmdb` | `tmdb` or `omdb` for disc metadata lookup |
| `TMDB_API_KEY` | — | API key for The Movie Database |
| `MAKEMKV_KEY` | — | MakeMKV beta key for Blu-ray support |
| `NOTIFY_RIP` | `false` | Send notification when a rip starts |
| `NOTIFY_TRANSCODE` | `false` | Send notification when transcoding completes |
| `APPRISE_URL` | — | Apprise-compatible notification URL (Discord, Slack, etc.) |

All of these are documented with defaults in `.env.example` for reference. After first run, edit them in the web UI or in `${ARM_CONFIG}/arm.yaml`.

---

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `automatic-ripping-machine/docker-compose.yml` |

3. Under **Environment variables**, add all values from `.env.example` (at minimum `ARM_UID`, `ARM_GID`, `TZ`, and the five path variables)
4. Click **Deploy the stack**

> Note: Device passthrough (`/dev/sr0`) requires Portainer to be running on the same host as the optical drive. This stack cannot be deployed to a remote agent without device access.
