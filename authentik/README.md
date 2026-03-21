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
| `AUTHENTIK_TAG` | Check [releases](https://github.com/goauthentik/authentik/releases) for the latest |

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

Authentik requires coordinated version upgrades — do not skip major versions.

1. Update `AUTHENTIK_TAG` in `.env` to the new version
2. Pull the new images: `docker compose pull`
3. Restart: `docker compose up -d`

Authentik will automatically run any required database migrations on startup.

Check the [upgrade notes](https://docs.goauthentik.io/docs/releases) before upgrading across multiple versions.

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
