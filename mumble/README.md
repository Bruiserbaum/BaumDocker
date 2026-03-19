# Mumble Server (Murmur)

A self-hosted voice chat server. Low latency, open source, and lightweight — no accounts, no subscriptions, no cloud. Works with the [Mumble client](https://www.mumble.info/) on Windows, macOS, Linux, iOS, and Android.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Mumble** | 64738 TCP | Client connections |
| **Mumble** | 64738 UDP | Audio traffic (lower latency than TCP) |

Both TCP and UDP must be open on your firewall and forwarded on your router for external connections.

## Storage

| Path | Contents |
|------|----------|
| `./data` | SQLite database (users, channels, ACLs, bans) and server config |

## Setup

### 1. Set a SuperUser password

Replace `REPLACE_WITH_SUPERUSER_PASSWORD` in `docker-compose.yml` with a strong password. The SuperUser account gives full admin control over the server from the Mumble client.

### 2. Configure the server

Edit the environment variables in `docker-compose.yml`:

| Variable | Description |
|----------|-------------|
| `MUMBLE_SUPERUSER_PASSWORD` | SuperUser admin password |
| `MUMBLE_CONFIG_SERVERNAME` | Name shown in the server browser |
| `MUMBLE_CONFIG_WELCOMETEXT` | Message shown when users connect |
| `MUMBLE_CONFIG_USERS` | Max simultaneous users (0 = unlimited) |
| `MUMBLE_CONFIG_BANDWIDTH` | Per-user bandwidth cap in bps (72000 = 72 kbps) |
| `MUMBLE_CONFIG_REGISTERPUBLICSERVER` | Set `true` to list on the public Mumble directory |

### 3. Start

```bash
docker compose up -d
```

### 4. Connect

Open the Mumble client and add a new server:

- **Address:** your server IP or domain
- **Port:** 64738
- **Username:** anything (first user to connect with SuperUser gets admin)

### 5. Log in as SuperUser (admin)

In the Mumble client, connect with:
- **Username:** `SuperUser`
- **Password:** the password you set above

From there you can create channels, set ACLs, register users, and configure the server.

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `mumble/docker-compose.yml` |

3. Under **Environment variables**, add `MUMBLE_SUPERUSER_PASSWORD` and any other `MUMBLE_CONFIG_*` values you want to override
4. Click **Deploy the stack**

## Firewall

Open both TCP and UDP on port 64738:

```bash
ufw allow 64738/tcp
ufw allow 64738/udp
```

For external access, forward port 64738 (TCP and UDP) on your router to your server's LAN IP.

## SSL Certificate (optional)

Mumble generates a self-signed certificate automatically. Users will see a warning on first connect — they can accept and save it. To use a real certificate (e.g. from Let's Encrypt), mount it into the container:

```yaml
volumes:
  - ./data:/data
  - /etc/letsencrypt/live/yourdomain.com/fullchain.pem:/data/cert.pem:ro
  - /etc/letsencrypt/live/yourdomain.com/privkey.pem:/data/key.pem:ro
```

Then set in environment:
```yaml
MUMBLE_CONFIG_SSLCERT: /data/cert.pem
MUMBLE_CONFIG_SSLKEY: /data/key.pem
```

## Backup

Back up `./data` — it contains the server database with all users, channels, and ACL settings.
