# Nginx Proxy Manager

A web UI for managing Nginx reverse proxy hosts with automatic Let's Encrypt SSL — no config file editing required. The recommended front door for exposing home lab services publicly.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Nginx Proxy Manager** | 80 / 443 | Proxied HTTP and HTTPS traffic |
| **NPM Admin UI** | 81 | Web management interface |
| **MariaDB** | — (internal) | NPM configuration database |

> Port 80 must be open and reachable from the internet for Let's Encrypt HTTP-01 certificate issuance. If your ISP blocks port 80, use DNS-01 challenge instead (configured per-host in the NPM UI).

## Storage Layout

| Path | Contents |
|------|----------|
| `./data` | NPM proxy config, access lists, custom SSL certs |
| `./letsencrypt` | Let's Encrypt certificates and account keys |
| `./mysql` | MariaDB data |

## Setup

### 1. Configure `.env`

```bash
cp .env.example .env
```

Generate two passwords (one for root, one for the npm DB user):

```bash
openssl rand -hex 32   # DB_ROOT_PASSWORD
openssl rand -hex 32   # DB_PASSWORD
```

### 2. Open firewall ports

Ensure ports **80**, **443**, and **81** are reachable on your host. Port 81 should be restricted to your LAN — do not expose the admin UI to the internet.

### 3. Start

```bash
docker compose up -d
```

### 4. First login

Navigate to `http://your-server-ip:81`

Default credentials (change immediately):
- **Email:** `admin@example.com`
- **Password:** `changeme`

### 5. Add a proxy host

1. Go to **Hosts → Proxy Hosts → Add Proxy Host**
2. Enter your domain, set the forward host (container name or IP) and port
3. On the **SSL** tab, request a Let's Encrypt certificate

## Recommended Network Setup

For NPM to proxy to other Docker stacks, either:

**Option A — Use host IP:** Set the forward hostname to your server's LAN IP (`192.168.x.x`) and the exposed port.

**Option B — Shared Docker network (recommended):** Create a shared network and attach both NPM and your target containers:

```yaml
# In NPM's docker-compose.yml — add to npm service:
networks:
  - proxy

# In your other stack — add to the service you want to proxy:
networks:
  - proxy

# At the bottom of each file:
networks:
  proxy:
    external: true
```

Create the network once:
```bash
docker network create proxy
```
