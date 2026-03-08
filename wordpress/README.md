# WordPress

Self-hosted WordPress with MariaDB. WordPress files are stored on the host so plugins, themes, and uploads persist across container rebuilds and are easy to back up.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **WordPress** | 8080 | Web UI and admin panel (`/wp-admin`) |
| **MariaDB** | — (internal) | WordPress database |

## Storage Layout

| Path | Contents |
|------|----------|
| `./wordpress` | WordPress core, plugins, themes, and `wp-content/uploads` |
| `./mysql` | MariaDB data files |

## Setup

### 1. Configure `.env`

```bash
cp .env.example .env
```

Fill in:

| Variable | Description |
|----------|-------------|
| `WORDPRESS_DB_PASSWORD` | DB password — `openssl rand -hex 32` |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password — `openssl rand -hex 32` |
| `WORDPRESS_AUTH_KEY` | Security key — `openssl rand -hex 32` (×4) |
| `WORDPRESS_SECURE_AUTH_KEY` | Security key |
| `WORDPRESS_LOGGED_IN_KEY` | Security key |
| `WORDPRESS_NONCE_KEY` | Security key |

Or generate all security keys at once from WordPress:
```
https://api.wordpress.org/secret-key/1.1/salt/
```

### 2. Start

```bash
docker compose up -d
```

### 3. Complete installation

Navigate to `http://your-server-ip:8080` and follow the WordPress setup wizard to set your site title, admin username, and admin password.

## Backup

```bash
# Files (plugins, themes, uploads)
cp -r ./wordpress ./wordpress-backup

# Database
docker exec wordpress-db mysqldump -u wordpress -p wordpress > wordpress-backup.sql
```

## Behind a Reverse Proxy

If using Nginx Proxy Manager, set your WordPress site URL correctly to avoid redirect loops. Add to `wp-config.php` (or set before first install):

```php
define('WP_HOME', 'https://yourdomain.com');
define('WP_SITEURL', 'https://yourdomain.com');
```

Or set via environment in `docker-compose.yml`:

```yaml
WORDPRESS_CONFIG_EXTRA: |
  define('WP_HOME', 'https://yourdomain.com');
  define('WP_SITEURL', 'https://yourdomain.com');
```
