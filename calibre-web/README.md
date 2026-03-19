# Calibre-Web

A web UI for browsing, reading, and downloading your Calibre ebook library. Supports OPDS for e-reader apps, send-to-Kindle, and user accounts with per-user reading lists.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Calibre-Web** | 8083 | Web UI and OPDS catalog |

## Requirements

Calibre-Web reads an existing **Calibre library** — a folder managed by the [Calibre desktop app](https://calibre-ebook.com/) that contains a `metadata.db` file. You must have this library already set up before starting the container.

## Storage

| Path | Contents |
|------|----------|
| `./config` | Calibre-Web settings and its own database |
| `/path/to/your/calibre/library` | Your Calibre library (read from host) |

## Setup

### 1. Set your library path

Edit `docker-compose.yml` and replace `/path/to/your/calibre/library` with the absolute path to your Calibre library folder on the host:

```yaml
- /mnt/your-drive/calibre-library:/books
```

The folder must contain `metadata.db`. If it doesn't, open Calibre desktop app, point it at the folder, and it will create the file.

### 2. Set your timezone and user IDs

```yaml
TZ: America/New_York
PUID: 1000   # from: id $USER
PGID: 1000
```

### 3. Start

```bash
docker compose up -d
```

### 4. First login

Navigate to `http://your-server-ip:8083`

Default credentials:
- **Username:** `admin`
- **Password:** `admin123`

Change these immediately under **Admin → Edit User**.

### 5. Point to your library

On first login, Calibre-Web will prompt for the database location. Enter:

```
/books
```

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `calibre-web/docker-compose.yml` |

3. Under **Environment variables**, add `PUID`, `PGID`, `TZ`, and `CALIBRE_LIBRARY_PATH` (absolute host path to your Calibre library folder)
4. Click **Deploy the stack**

## OPDS (E-Reader Apps)

The OPDS catalog URL for apps like KOReader, Librera, or Moon+ Reader:

```
http://your-server-ip:8083/opds
```

## Optional: Full Calibre Integration

The `DOCKER_MODS: linuxserver/mods:universal-calibre` line installs the full Calibre binary inside the container. This enables:
- E-book format conversion (epub → mobi, etc.)
- Send-to-Kindle via email

Remove the `DOCKER_MODS` line if you don't need these features (reduces image size and startup time).

## Backup

Only `./config` needs to be backed up — your actual book files and `metadata.db` live in your Calibre library folder, which you should back up separately.
