# Jellyfin

A fully free and open-source media server — no account required, no Plex Pass, no phone-home. Stream movies, TV, music, and live TV to any device on your network or remotely.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Jellyfin** | 8096 | HTTP web UI |
| **Jellyfin** | 8920 | HTTPS web UI (optional) |
| **LAN Discovery** | 7359 UDP | Auto-discovery for Jellyfin apps |
| **DLNA** | 1900 UDP | DLNA/UPnP media sharing (optional) |

## Storage

| Path | Contents |
|------|----------|
| `./config` | Jellyfin database, metadata, user accounts, and preferences |
| `./cache` | Transcode temp files and image cache (use a fast disk) |
| `/path/to/your/movies` | Movie library |
| `/path/to/your/tv` | TV show library |
| `/path/to/your/music` | Music library |

## Setup

### 1. Set media paths

Replace the placeholder paths with absolute paths to your media on the host:

```yaml
- /mnt/your-drive/movies:/movies
- /mnt/your-drive/tv:/tv
- /mnt/your-drive/music:/music
```

Add more volume entries for additional libraries (books, photos, etc.).

### 2. Set PUID / PGID

```bash
id $USER
# uid=1000 gid=1000
```

Match these to your host user so Jellyfin can read your media files.

### 3. Set your timezone

```yaml
TZ: America/New_York
```

### 4. Start

```bash
docker compose up -d
```

### 5. Complete setup wizard

Navigate to `http://your-server-ip:8096`

The first-run wizard walks you through creating an admin account and adding your media libraries. When adding libraries, use the container-side paths (`/movies`, `/tv`, `/music`).

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `jellyfin/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example` (PUID, PGID, TZ, media paths)
4. Click **Deploy the stack**

> Media library paths are set via environment variables in `.env.example`. Set them to the absolute host paths where your movies, TV, and music live.

## Hardware Transcoding

Jellyfin supports hardware-accelerated transcoding with no license required.

### Intel Quick Sync / AMD VAAPI

Uncomment the `devices` block in `docker-compose.yml`:

```yaml
devices:
  - /dev/dri:/dev/dri
```

Then in Jellyfin: **Dashboard → Playback → Transcoding** → set Hardware Acceleration to **Video Acceleration API (VAAPI)** or **Intel QuickSync**.

### NVIDIA GPU

Uncomment the NVIDIA `environment` and `deploy` blocks in `docker-compose.yml`. Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

Then in Jellyfin: **Dashboard → Playback → Transcoding** → set Hardware Acceleration to **NVENC**.

## Behind a Reverse Proxy

Set `JELLYFIN_PublishedServerUrl` to your external URL so Jellyfin reports the correct address to clients:

```yaml
JELLYFIN_PublishedServerUrl: https://jellyfin.yourdomain.com
```

Remove the DLNA port (`1900/udp`) if running behind a proxy — DLNA and reverse proxies don't mix well.

## Remote Access

Enable remote access under **Dashboard → Networking**. For direct connections outside your LAN, forward port **8096** (or **8920** for HTTPS) on your router. Alternatively, put Jellyfin behind Nginx Proxy Manager with a real SSL cert.

## Jellyfin vs Plex

| Feature | Jellyfin | Plex |
|---------|----------|------|
| Cost | Free | Free (Plex Pass for HW transcode) |
| Account required | No | Yes |
| Hardware transcoding | Free | Plex Pass required |
| Mobile apps | Free | Free (some limits) |
| Remote access | Self-managed | Via plex.tv relay |

## Backup

Back up `./config` — it contains your database, user accounts, watched history, and all metadata. Your media files should be backed up separately.
