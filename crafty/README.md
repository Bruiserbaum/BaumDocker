# Crafty Controller

A web-based Minecraft server management panel. Create, configure, start, stop, and monitor multiple Java and Bedrock servers from a single UI — no command line needed after initial setup.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Crafty UI** | 8443 (HTTPS) | Web management panel |
| **Crafty UI** | 8000 (HTTP) | Redirects to HTTPS |
| **Minecraft Java** | 25565–25567 | One port per server (add more as needed) |
| **Minecraft Bedrock** | 19132 UDP | Bedrock Edition (remove if not needed) |

## Storage Layout

All server files, configs, backups, and logs are stored under `./data` on the host:

| Path | Contents |
|------|----------|
| `./data/servers` | Minecraft server files (worlds, plugins, configs) |
| `./data/backups` | Automated and manual backups |
| `./data/config` | Crafty application config and user database |
| `./data/logs` | Crafty and server logs |
| `./data/import` | Drop server JARs or zips here for easy import |

## Setup

### 1. Set your timezone

Edit `TZ` in `docker-compose.yml`:

```yaml
TZ: America/New_York
```

### 2. Configure server ports

Each Minecraft server you create in Crafty needs its own host port. The compose file includes three (25565–25567). To add more, extend the port list:

```yaml
- "25568:25568"   # Server 4
- "25569:25569"   # Server 5
```

Then set the matching port in each server's Crafty config so they don't conflict.

### 3. Start

```bash
docker compose up -d
```

### 4. First login

Navigate to `https://your-server-ip:8443`

Your browser will warn about a self-signed certificate — this is expected on a local network. Accept and continue.

Crafty generates a random admin password on first start. Retrieve it from the logs:

```bash
docker logs crafty 2>&1 | grep -i "password"
```

Change the password immediately after logging in under **Config → Users**.

### 5. Create a Minecraft server

1. Go to **Servers → Create New Server**
2. Choose **Java** or **Bedrock**
3. Select a version — Crafty downloads the server JAR automatically
4. Set the port to match one of your exposed ports (e.g. `25565`)
5. Set memory allocation (RAM)
6. Click **Create** and then **Start**

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `crafty/docker-compose.yml` |

3. Under **Environment variables**, add `TZ`
4. Click **Deploy the stack**

> The random admin password is generated on first start. Retrieve it with:
> ```bash
> docker logs crafty 2>&1 | grep -i "password"
> ```

## Adding More Servers

Each server needs:
1. A unique port added to `docker-compose.yml` (left side of the mapping)
2. That same port set in the server's configuration inside Crafty

After adding new ports, restart the stack:

```bash
docker compose down && docker compose up -d
```

## Firewall / Router

To allow players to connect from outside your network:

- Forward the relevant port(s) (e.g. `25565`) on your router to your server's LAN IP
- Open the same port(s) on your host firewall (`ufw allow 25565/tcp`)
- Bedrock uses UDP: `ufw allow 19132/udp`

## Backup

Crafty has built-in scheduled backup support under **Servers → [Server] → Backups**. Backups land in `./data/backups`. Copy this folder off-host for offsite backup.

## Recommended Server Memory

| Players | RAM |
|---------|-----|
| 1–5 | 2–4 GB |
| 5–15 | 4–8 GB |
| 15–30 | 8–16 GB |

Set per-server memory in Crafty's server settings. Leave headroom for the OS and other containers.
