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
| `ADMIN_TOKEN` | Admin panel token — must be an Argon2 PHC hash (see below) |
| `SIGNUPS_ALLOWED` | `true` to allow new registrations, `false` to lock down after setup |

#### Generating the ADMIN_TOKEN hash

Vaultwarden expects a pre-hashed **Argon2 PHC string** for `ADMIN_TOKEN`, not a plain-text password. Use the built-in hash command to generate it:

```bash
docker exec -it <vaultwarden-container-name> /vaultwarden hash
```

Enter your desired admin password when prompted. Copy the resulting `$argon2id$...` string and use that as the value of `ADMIN_TOKEN` in your `.env` or Portainer environment variables.

If the container isn't running yet, you can generate the hash with the `argon2` CLI tool on your host instead:

```bash
echo -n 'your-password' | argon2 "$(openssl rand -base64 32)" -id -t 3 -m 16 -p 4 -l 32 -e
```

This keeps the raw password out of your deployment files entirely.

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

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `vaultwarden/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example`
4. Click **Deploy the stack**

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
