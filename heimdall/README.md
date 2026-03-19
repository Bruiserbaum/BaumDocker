# Heimdall

A clean, simple application dashboard for your home lab. Pin links to all your self-hosted services in one place — with icons, custom colors, and optional live status indicators for supported apps.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Heimdall** | 80 / 443 | Web dashboard (HTTP + HTTPS with self-signed cert) |

## Storage

Config, the SQLite app database, and any custom icons are stored in `./config` relative to the `docker-compose.yml`. This folder is created automatically on first start.

## Setup

### 1. Set your timezone

Edit `TZ` in `docker-compose.yml` to match your timezone.
Full list: [tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

```yaml
TZ: America/New_York
```

### 2. Set PUID / PGID (Linux hosts)

These tell the container which host user owns the config files, avoiding permission issues.

```bash
id $USER
# uid=1000(yourname) gid=1000(yourname) ...
```

Set `PUID` and `PGID` to match. On Windows/Mac with Docker Desktop, leave them at `1000`.

### 3. Start

```bash
docker compose up -d
```

### 4. Access

- HTTP:  `http://your-server-ip`
- HTTPS: `https://your-server-ip` (browser will warn about the self-signed cert — safe to accept on a local network)

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `heimdall/docker-compose.yml` |

3. Under **Environment variables**, add `PUID`, `PGID`, and `TZ`
4. Click **Deploy the stack**

## Adding Apps

1. Open Heimdall in your browser
2. Click **Add an application**
3. Enter the name, URL, and pick an app type (Heimdall has built-in enhanced tiles for ~400 apps including Proxmox, Portainer, Grafana, Pi-hole, etc.)
4. Enhanced tiles show live stats pulled directly from the app's API

## Ports

If port 80 or 443 is already in use on your host, change the left side of the mapping:

```yaml
ports:
  - "8080:80"
  - "8443:443"
```

## Backup

The entire `./config` folder is your backup. Copy it and you have everything — all apps, icons, and settings.

```bash
cp -r ./config ./config-backup
```
