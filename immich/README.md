# Immich

Self-hosted photo and video backup — a Google Photos replacement. All persistent data (photos, database, ML models) is stored on host paths so your library lives directly on your drive and is easy to access, back up, or migrate.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **immich-server** | 2283 | Main web UI + API + background jobs |
| **immich-machine-learning** | — (internal) | Face recognition, CLIP smart search, object detection |
| **Redis** | — (internal) | Job queue and cache |
| **PostgreSQL** | — (internal) | Database (pgvecto-rs image with vector extension) |

## Host Storage Layout

All data lives on your host, not in Docker-managed volumes:

| `.env` variable | Default path example | Contents |
|-----------------|---------------------|----------|
| `UPLOAD_LOCATION` | `/mnt/your-drive/immich/photos` | All photos and videos |
| `ML_MODEL_CACHE` | `/mnt/your-drive/immich/model-cache` | Downloaded ML models |
| `DB_DATA_LOCATION` | `/mnt/your-drive/immich/postgres` | PostgreSQL data files |

> **Tip:** Keep `DB_DATA_LOCATION` on a fast local SSD if possible. The photo library (`UPLOAD_LOCATION`) can be on a slower external or NAS drive without affecting app performance.

## Setup

### 1. Create the `.env` file

```bash
cp .env.example .env
```

Edit `.env` and fill in:

| Variable | Description |
|----------|-------------|
| `UPLOAD_LOCATION` | Absolute host path to store photos/videos |
| `ML_MODEL_CACHE` | Absolute host path for ML model cache |
| `DB_DATA_LOCATION` | Absolute host path for PostgreSQL data |
| `DB_PASSWORD` | Database password — generate with `openssl rand -hex 32` |
| `DB_USERNAME` | Database username (default: `immich`) |
| `DB_DATABASE_NAME` | Database name (default: `immich`) |

### 2. Create the host directories

Docker will not create these automatically on some systems:

```bash
mkdir -p /mnt/your-drive/immich/photos
mkdir -p /mnt/your-drive/immich/model-cache
mkdir -p /mnt/your-drive/immich/postgres
```

### 3. Start the stack

```bash
docker compose up -d
```

On first start, Immich will initialize the database and download ML models. This may take a few minutes.

### 4. Access

Navigate to `http://your-server-ip:2283` and create your admin account.

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `immich/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example`
4. Click **Deploy the stack**

> Create the host directories for photos, model cache, and postgres data before deploying — Docker will not create them automatically on all systems.

## Mobile App

Install the Immich app on iOS or Android. Point it at `http://your-server-ip:2283` (or your external URL if behind a reverse proxy).

## Upgrading

Immich releases frequently. To update:

```bash
docker compose pull
docker compose up -d
```

> Always check the [Immich release notes](https://github.com/immich-app/immich/releases) before upgrading — breaking changes are noted there.

## Backup

Since all data is on host paths, your backup strategy is straightforward:

| What to back up | Path |
|-----------------|------|
| Photos/videos | `UPLOAD_LOCATION` |
| Database | Use `pg_dump` (see below) or back up `DB_DATA_LOCATION` while Postgres is stopped |
| Config | Your `.env` file |

**Database dump (recommended over copying data files while running):**

```bash
docker exec immich-postgres pg_dumpall -U immich > immich-backup.sql
```

## Authentik SSO (Optional)

Immich supports OAuth2/OIDC login natively. To enable SSO via Authentik:

1. In Authentik, create an **OAuth2/OpenID Provider** and an **Application** for it.
2. Set the redirect URI to: `https://photos.yourdomain.com/auth/login/callback`
3. Copy the Client ID and Client Secret.
4. Uncomment and fill in the `OAUTH_*` variables in `.env`:

| Variable | Description |
|----------|-------------|
| `OAUTH_ENABLED` | Set to `true` to enable SSO |
| `OAUTH_ISSUER_URL` | Authentik provider URL — `https://auth.yourdomain.com/application/o/<app-slug>/` |
| `OAUTH_CLIENT_ID` | From the Authentik application |
| `OAUTH_CLIENT_SECRET` | From the Authentik application |
| `OAUTH_BUTTON_TEXT` | Label for the login button (default: `Login with Authentik`) |
| `OAUTH_AUTO_REGISTER` | `true` to auto-create Immich accounts for SSO users on first login |

Then uncomment the matching `OAUTH_*` lines in `docker-compose.yml` and restart the stack.

## Reverse Proxy

If placing Immich behind nginx or Traefik, set `IMMICH_SERVER_URL` in `.env` to your external URL and uncomment the relevant line in `docker-compose.yml`. Immich needs this for correct mobile app redirects and OAuth callbacks.
