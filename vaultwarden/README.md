# Vaultwarden

A lightweight, self-hosted Bitwarden-compatible password manager. Works with all official Bitwarden clients (browser extensions, mobile apps, desktop). Uses SQLite by default — no separate database container needed.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Vaultwarden** | 8222 | Web vault UI + API (Bitwarden-compatible) |

## Storage

| Path | Contents |
|------|----------|
| `DATA_FOLDER` | Vault database, attachments, sends, and config |

## Setup

### 1. Create the `.env` file

```bash
cp .env.example .env
```

Edit `.env` and fill in:

| Variable | Description |
|----------|-------------|
| `DATA_FOLDER` | Absolute host path to store vault data |
| `DOMAIN` | Full URL clients use to reach Vaultwarden (e.g. `https://vault.yourdomain.com`) |
| `ADMIN_TOKEN` | Admin panel password — generate with `openssl rand -base64 48` |
| `SIGNUPS_ALLOWED` | `true` to allow new registrations, `false` to lock down after setup |

### 2. Create the data directory

```bash
mkdir -p /opt/vaultwarden/data
```

### 3. Start the stack

```bash
docker compose up -d
```

### 4. Access

- **Web vault:** `http://your-server-ip:8222`
- **Admin panel:** `http://your-server-ip:8222/admin` (requires `ADMIN_TOKEN`)

Create your account on first visit. Set `SIGNUPS_ALLOWED=false` in `.env` and restart once your accounts are created.

### 5. Connect Bitwarden clients

In any Bitwarden client, go to **Settings → Server URL** and enter your Vaultwarden URL before logging in.

## Reverse Proxy

Vaultwarden is designed to run behind a reverse proxy (nginx, Traefik, nginx-proxy-manager). Set `DOMAIN` to your external HTTPS URL — this is required for correct invite links, 2FA setup, and mobile sync.

## SMTP / Email

Email is optional but recommended for password hints and organization invites. Uncomment and fill in the `SMTP_*` variables in `.env`, then restart.

## Backup

Copy `DATA_FOLDER` — it contains the SQLite database (`db.sqlite3`) and all attachments. Back this up regularly.

```bash
cp -r /opt/vaultwarden/data /your/backup/location
```

## Upgrading

```bash
docker compose pull
docker compose up -d
```

Vaultwarden is backwards compatible — upgrades are generally safe without any extra steps.
