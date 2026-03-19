# Plex Media Server

Self-hosted media server for movies, TV shows, and music. Stream to any device on your network or remotely via the Plex apps.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Plex** | 32400 | Media server (via host network) |

## Storage

| Path | Contents |
|------|----------|
| `./config` | Plex database, metadata, artwork cache, and preferences |
| `/path/to/your/movies` | Movie library (mapped to `/movies` in container) |
| `/path/to/your/tv` | TV show library (mapped to `/tv` in container) |
| `/path/to/your/music` | Music library (mapped to `/music` in container) |
| `/tmp/plex-transcode` | Temporary transcode files (fast local disk recommended) |

## Setup

### 1. Get a claim token

Go to **https://plex.tv/claim** while logged into your Plex account. Copy the token — it expires in 4 minutes.

Paste it into `docker-compose.yml`:

```yaml
PLEX_CLAIM: claim-xxxxxxxxxxxxxxxxxxxx
```

The claim token is only needed on first start to link the server to your account. You can remove it from the compose file after the server is claimed.

### 2. Set media paths

Replace the placeholder paths with absolute paths to your media on the host:

```yaml
- /mnt/your-drive/movies:/movies
- /mnt/your-drive/tv:/tv
- /mnt/your-drive/music:/music
```

Add more volume entries for additional libraries (audiobooks, photos, etc.).

### 3. Set PUID / PGID

```bash
id $USER
# uid=1000 gid=1000
```

Set these to match so Plex can read your media files.

### 4. Set your timezone

```yaml
TZ: America/New_York
```

### 5. Start

```bash
docker compose up -d
```

### 6. Access

Navigate to `http://your-server-ip:32400/web`

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `plex/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example` (PLEX_CLAIM, PUID, PGID, TZ, media paths)
4. Click **Deploy the stack**

> Get your claim token from **https://plex.tv/claim** — it expires in 4 minutes. Only needed on first deploy to link the server to your account.

## Networking

This stack uses `network_mode: host` by default. This gives Plex full LAN visibility and enables automatic device discovery (GDM), DLNA, and Bonjour without manually exposing every UDP port.

**If you prefer bridge networking**, comment out `network_mode: host` and uncomment the `ports:` block at the bottom of the compose file. Note that LAN discovery may not work reliably in bridge mode.

## Hardware Transcoding (Plex Pass required)

### Intel Quick Sync

Add to the `plex` service:

```yaml
devices:
  - /dev/dri:/dev/dri
```

### NVIDIA GPU

Uncomment the `NVIDIA_VISIBLE_DEVICES`, `NVIDIA_DRIVER_CAPABILITIES`, and `deploy` blocks in `docker-compose.yml`. Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

Then enable hardware transcoding in Plex under **Settings → Transcoder → Use hardware acceleration when available**.

## Remote Access

Plex handles remote access automatically through plex.tv relay if your server is not directly reachable. For direct connections (lower latency, no relay), forward port **32400** on your router to your server's LAN IP.

## Backup

Back up `./config` — it contains your entire Plex database, watched status, playlists, and metadata cache. Your media files themselves should be backed up separately.
