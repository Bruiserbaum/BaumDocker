# Nextcloud

Self-hosted file sync and share — a Dropbox/Google Drive replacement. Includes PostgreSQL for the database and Redis for caching and file locking.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Nextcloud** | 8080 | Web UI and WebDAV endpoint |
| **PostgreSQL** | — (internal) | Database |
| **Redis** | — (internal) | Cache and file locking |

## Storage Layout

| Path | Contents |
|------|----------|
| `./config` | Nextcloud app files, config, installed apps |
| `./data` | User files — point to your large storage drive |
| `./postgres` | PostgreSQL data files |

## Setup

### 1. Configure `.env`

```bash
cp .env.example .env
```

Fill in:

| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | Database password — `openssl rand -hex 32` |
| `NEXTCLOUD_ADMIN_PASSWORD` | Admin account password for first login |
| `NEXTCLOUD_TRUSTED_DOMAINS` | Space-separated IPs/hostnames that can access Nextcloud |

### 2. (Optional) Move data to a large drive

Edit `docker-compose.yml` and change `./data` to an absolute path on your storage drive:

```yaml
- /mnt/your-drive/nextcloud/data:/var/www/html/data
```

### 3. Start

```bash
docker compose up -d
```

First start initializes the database and creates the admin account automatically (no web installer needed).

### 4. Access

`http://your-server-ip:8080`

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `nextcloud/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example`
4. Click **Deploy the stack**

## Behind a Reverse Proxy

If using Nginx Proxy Manager or a Traefik, add your proxy's hostname to `NEXTCLOUD_TRUSTED_DOMAINS` and set the overwrite URL in Nextcloud's `config.php`:

```php
'overwrite.cli.url' => 'https://cloud.yourdomain.com',
'overwriteprotocol' => 'https',
```

Or set via environment variable before first run:

```env
NEXTCLOUD_TRUSTED_DOMAINS=cloud.yourdomain.com
```

## Authentik SSO (Optional)

Nextcloud supports OIDC login via the **user_oidc** app (built by the Nextcloud team). There are no container-level env vars — configuration is done through the Nextcloud web UI after install.

### Setup

1. In Nextcloud, go to **Apps → Search** and install **OpenID Connect user backend**.
2. In Authentik, create an **OAuth2/OpenID Provider** and an **Application** for it.
3. Set the redirect URI to: `https://cloud.yourdomain.com/apps/user_oidc/code`
4. Back in Nextcloud, go to **Settings → OpenID Connect** and add a new provider:

| Field | Value |
|-------|-------|
| Identifier | `Authentik` (display name) |
| Client ID | From the Authentik application |
| Client Secret | From the Authentik application |
| Discovery Endpoint | `https://auth.yourdomain.com/application/o/<app-slug>/.well-known/openid-configuration` |

5. Click **Register** and test login.

> To require SSO only, disable local password login under **Settings → Administration → Security → Disable password login for local users**.

## Maintenance

Run Nextcloud's background jobs on a cron schedule (recommended over the default AJAX mode):

```bash
docker exec -u www-data nextcloud php cron.php
```

Add to your host crontab to run every 5 minutes:

```
*/5 * * * * docker exec -u www-data nextcloud php cron.php
```
