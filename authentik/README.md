# Authentik

Open-source identity provider and SSO platform. Handles login, OAuth2/OIDC, SAML, LDAP, and multi-factor authentication for all your self-hosted services from a single place.

## Services

| Service | Description |
|---------|-------------|
| `server` | Web UI, API, and authentication flows — port 9100 (HTTP) / 9144 (HTTPS) |
| `worker` | Background tasks — token cleanup, email, outpost management |
| `postgresql` | Primary database |
| `redis` | Session cache and task queue |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `9100` | HTTP | Web UI and authentication (configure in `.env`) |
| `9144` | HTTPS | HTTPS version of web UI (self-signed cert by default) |

## Setup

### 1. Copy and fill in `.env`

```bash
cp .env.example .env
```

Fill in the required values:

| Variable | How to generate |
|----------|----------------|
| `AUTHENTIK_SECRET_KEY` | `openssl rand -hex 32` |
| `PG_PASS` | `openssl rand -hex 32` |
| `AUTHENTIK_TAG` | Defaults to `latest`. Pin to a specific version if needed (e.g. `2026.2.1`) |

### 2. Create local directories

Authentik expects these directories to exist for media uploads, custom templates, and managed certificates:

```bash
mkdir -p media certs custom-templates
```

### 3. Start the stack

```bash
docker compose up -d
```

The first startup takes a few minutes as Authentik runs database migrations.

### 4. Complete initial setup

Open `http://<your-server-ip>:9100/if/flow/initial-setup/` in your browser.

Create your admin account (this is a one-time setup flow — the URL stops working once complete).

After setup, the main admin panel is at `http://<your-server-ip>:9100`.

## Updating

> **⚠ Do not skip major version series.** Jumping directly from e.g. `2024.12.x` to `2026.2.x` will cause gunicorn to fail at startup because the database migration chain is broken. You must upgrade through each year's release series.

### Safe upgrade path (example: 2024.12.x → 2026.2.1)

Run each step fully before moving to the next — wait until containers are healthy:

```bash
# Step 1 — upgrade to mid-2025
# In .env: AUTHENTIK_TAG=2025.2.4
docker compose pull && docker compose up -d
# Wait for: docker compose logs server --follow  (look for "startup complete")

# Step 2 — upgrade to late-2025
# In .env: AUTHENTIK_TAG=2025.6.4
docker compose pull && docker compose up -d
# Wait for healthy

# Step 3 — upgrade to target
# In .env: AUTHENTIK_TAG=2026.2.1
docker compose pull && docker compose up -d
```

### If gunicorn failed after a bad jump

Roll back to your last working tag, let it start cleanly, then follow the step-by-step path above:

```bash
# In .env, set AUTHENTIK_TAG back to your last working version
docker compose up -d
```

### General update steps (within same major series)

1. Update `AUTHENTIK_TAG` in `.env`
2. `docker compose pull`
3. `docker compose up -d`

Authentik runs database migrations automatically on startup.

Check the [upgrade notes](https://docs.goauthentik.io/docs/releases) before upgrading.

## Reverse Proxy

Authentik is designed to sit behind a reverse proxy. When using [nginx-proxy-manager](../nginx-proxy-manager/) or a similar proxy, point it at port `9100`.

Authentik also supports acting as a **forward auth** provider so other services can delegate authentication to it, even if they don't natively support OAuth2/OIDC.

See the [Authentik proxy provider docs](https://docs.goauthentik.io/docs/providers/proxy/) for setup.

## Email (Optional)

Email is required for password reset flows. Uncomment and fill in the `EMAIL_*` variables in `.env`, then also uncomment the matching `AUTHENTIK_EMAIL__*` lines in the `server` and `worker` service blocks in `docker-compose.yml`.

## Storage

| Path | What's stored |
|------|---------------|
| `postgres` volume | All Authentik data (users, policies, applications, flows) |
| `redis` volume | Session cache and task queue (ephemeral, safe to clear) |
| `./media/` | User avatars and file uploads |
| `./certs/` | Certificates managed by Authentik outposts |
| `./custom-templates/` | Optional — override built-in email and login templates |

## Default Credentials

There are no default credentials. The first-run setup flow at `/if/flow/initial-setup/` is where you create the initial admin account.
