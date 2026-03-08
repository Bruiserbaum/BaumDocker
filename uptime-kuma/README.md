# Uptime Kuma

A self-hosted uptime monitoring tool with a clean dashboard, status pages, and notifications. Monitor HTTP, TCP, ping, DNS, and more — with alerts via Discord, Slack, Telegram, email, and 90+ other services.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Uptime Kuma** | 3001 | Web UI and monitoring engine |

## Storage

| Path | Contents |
|------|----------|
| `./data` | SQLite database, monitor configs, status page settings |

## Setup

### 1. Set your timezone

```yaml
TZ: America/New_York
```

### 2. Start

```bash
docker compose up -d
```

### 3. First login

Navigate to `http://your-server-ip:3001`

On first visit, Kuma prompts you to create an admin account. Do this immediately — the setup page is unauthenticated until an account exists.

### 4. Add monitors

Click **Add New Monitor** and choose a type:

| Type | Use for |
|------|---------|
| HTTP / HTTPS | Web services, APIs, dashboards |
| TCP Port | Any TCP service (SSH, databases, game servers) |
| Ping | Any host on your network |
| DNS | Domain resolution checks |
| Docker Container | Monitor containers on the same host |

## Notifications

Set up alerts under **Settings → Notifications** before adding monitors. Kuma supports Discord, Telegram, Slack, Gotify, ntfy, email (SMTP), PagerDuty, and 90+ more.

## Status Pages

Kuma can generate public-facing status pages showing the uptime of selected monitors. Useful for sharing service health with others without exposing the full dashboard.

Go to **Status Page → New Status Page** to configure one.

## Docker Container Monitoring

To monitor Docker containers directly (not just their ports), mount the Docker socket:

```yaml
volumes:
  - ./data:/app/data
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

> Only add this if you need container-level monitoring. Mounting the Docker socket gives the container elevated access to the host.

## Backup

Copy `./data` — it contains the SQLite database with all your monitors and history.
