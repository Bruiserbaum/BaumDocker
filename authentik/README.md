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

## Forward Auth (unified SSO for all services)

Forward auth lets Nginx handle all authentication. Every request to a protected service is checked against Authentik first — if the user isn't logged in they're redirected to Authentik's login page, and once authenticated the request is forwarded with identity headers (`X-authentik-username`, etc.).

This works for services on **any Docker host** as long as NPM can reach them by IP/hostname. Authentik only needs to be reachable by NPM.

### Step 1 — Create a Proxy Provider in Authentik

1. **Admin → Applications → Providers → Create → Proxy Provider**
2. Name it (e.g. `BaumLab Forward Auth`)
3. **Mode:** `Forward auth (single application)`
4. **External host:** the public URL NPM exposes for that service (e.g. `https://baumlab.yourdomain.com`)
5. Save

### Step 2 — Create an Application

1. **Admin → Applications → Create**
2. Link the provider you just created
3. Save

### Step 3 — Add the app to the Embedded Outpost

1. **Admin → Outposts → authentik Embedded Outpost → Edit**
2. Move your new application to "Selected Applications"
3. Save — the outpost reconfigures itself within ~30 seconds

### Step 4 — Configure NPM

In NPM, edit the proxy host for your service:

1. Open the **Advanced** tab
2. Paste the contents of [`snippets/npm-forward-auth.conf`](snippets/npm-forward-auth.conf)
3. Replace both `http://YOUR_AUTHENTIK_HOST:9100` with the URL NPM uses to reach Authentik (LAN IP or hostname)
4. Save

### Multi-host Docker setup

Services can be on different Docker hosts. NPM reaches them by LAN IP:port in the proxy host destination. Only the NPM Advanced tab snippet changes — the Authentik setup is the same regardless of where the service is hosted.

### Header-based auto-login (BaumLab / BaumLabBackup)

Once forward auth is active, Authentik injects `X-authentik-username` into every forwarded request. BaumLab and BaumLabBackup can read this header on page load to automatically issue a local session — the user never sees a login page.

Enable in each app's `.env`:
```env
AUTHENTIK_HEADER_AUTH=true
```

See the BaumLab and BaumLabBackup READMEs for full details.

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
