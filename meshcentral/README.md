# MeshCentral

Self-hosted remote device management — remote desktop, SSH, file transfer, device inventory, and agent-based monitoring for Windows, macOS, and Linux. No cloud dependency.

**Source:** [github.com/Ylianst/MeshCentral](https://github.com/Ylianst/MeshCentral)

## Services

| Service | Port | Description |
|---------|------|-------------|
| **MeshCentral Web UI** | 4430 | Web interface, agent connections, and WebSocket relay |
| **HTTP redirect** | 80 | Redirects HTTP to HTTPS (disable if NPM handles this) |

## Setup

### 1. Configure `.env`

```bash
cp .env.example .env
```

Set at minimum:

| Variable | Description |
|----------|-------------|
| `HOSTNAME` | Your domain or server IP — must match what agents connect to |
| `REVERSE_PROXY` | IP of your Nginx/NPM container (leave blank for direct access) |
| `REVERSE_PROXY_TLS_PORT` | External HTTPS port of your reverse proxy (default: 443) |

> **Note:** Environment variables only apply on first start. After that, MeshCentral writes `config.json` to the data volume and reads from it directly. Edit `/opt/meshcentral/meshcentral-data/config.json` inside the volume for any changes after initial setup.

### 2. Start

```bash
docker compose up -d
```

On first start MeshCentral generates self-signed certificates and writes `config.json`. Allow 15-20 seconds before the UI is available.

### 3. Create your admin account

Navigate to `https://your-server:4430` and create the first account — it is automatically made an administrator. Registration is then disabled if `ALLOW_NEW_ACCOUNTS=false`.

---

## Behind Nginx Proxy Manager

MeshCentral requires WebSocket passthrough — standard proxy settings will not work without it.

### NPM Proxy Host settings

| Field | Value |
|-------|-------|
| Domain Name | `mesh.yourdomain.com` |
| Scheme | `https` |
| Forward Hostname / IP | `meshcentral` (container name) or host IP |
| Forward Port | `4430` |
| Cache Assets | Off |
| Websockets Support | **On** (required) |
| Block Common Exploits | On |

### Custom Nginx configuration (Advanced tab in NPM)

Paste into the **Custom Nginx Configuration** box:

```nginx
proxy_send_timeout 330s;
proxy_read_timeout 330s;
proxy_buffering off;
```

These prevent WebSocket connections from timing out during long-lived remote sessions.

### Set `REVERSE_PROXY` in `.env`

Find the NPM container's internal IP:

```bash
docker inspect nginx-proxy-manager | grep '"IPAddress"'
```

Set that IP as `REVERSE_PROXY` in your `.env`, then recreate the container:

```bash
docker compose up -d --force-recreate
```

MeshCentral will then accept connections from NPM and trust the forwarded client IP headers.

---

## Agent Installers

Once running, agent installers are generated and served directly by MeshCentral.

### Download from the Web UI

1. Log in to the MeshCentral web UI
2. Go to **My Devices** and open or create a **Device Group**
3. Click **Add Agent** (or the agent download icon on the group)
4. Select your platform and download the installer or copy the install one-liner

### Direct download endpoints

Replace `mesh.yourdomain.com` with your domain and `MESH_GROUP_ID` with the device group ID shown in the web UI.

| Platform | URL |
|----------|-----|
| **Windows x64** | `https://mesh.yourdomain.com/meshagents?id=4&meshid=MESH_GROUP_ID` |
| **Windows x86** | `https://mesh.yourdomain.com/meshagents?id=3&meshid=MESH_GROUP_ID` |
| **Linux x64** | `https://mesh.yourdomain.com/meshagents?id=6&meshid=MESH_GROUP_ID` |
| **Linux ARM64** | `https://mesh.yourdomain.com/meshagents?id=26&meshid=MESH_GROUP_ID` |
| **macOS** | `https://mesh.yourdomain.com/meshosxagent?id=16&meshid=MESH_GROUP_ID` |

### Windows one-liner install (PowerShell)

```powershell
$url = "https://mesh.yourdomain.com/meshagents?id=4&meshid=MESH_GROUP_ID&installflags=0"
Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\meshagent.exe"
Start-Process -FilePath "$env:TEMP\meshagent.exe" -ArgumentList "-fullinstall" -Wait
```

### Linux one-liner install

```bash
curl -L "https://mesh.yourdomain.com/meshagents?id=6&meshid=MESH_GROUP_ID&installflags=0" -o /tmp/meshagent
chmod +x /tmp/meshagent
sudo /tmp/meshagent -install
```

> The **Add Agent** dialog in the web UI generates the complete command pre-filled with your domain and group ID — use that for the most reliable result.

---

## Volumes

| Volume | Purpose |
|--------|---------|
| `meshcentral-data` | Config (`config.json`), certificates, NeDB database, user accounts |
| `meshcentral-backups` | Automated backups |
| `meshcentral-files` | Uploaded files and device file storage |
| `meshcentral-web` | Custom themes, branding, and CSS overrides |

> Do not use MeshCentral's built-in self-update feature in Docker. Update by pulling a new image: `docker compose pull && docker compose up -d`

---

## Switching to MongoDB (optional)

The default embedded NeDB database handles up to ~100 devices. For larger deployments:

1. Change the image in `docker-compose.yml` to `ghcr.io/ylianst/meshcentral:latest-mongodb`
2. Add a `mongodb` service (see the [BaumDocker conventions](../README.md))
3. Uncomment `USE_MONGODB` and `MONGO_URL` in `.env`

---

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `meshcentral/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example`
4. Click **Deploy the stack**
5. Navigate to `https://your-server:4430` to create the admin account
