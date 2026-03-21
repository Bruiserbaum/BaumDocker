# BaumDocker

A collection of Docker Compose stacks for home lab use. Each stack is self-contained in its own folder with a README covering setup, ports, and any required configuration.

All sensitive values (API keys, secrets, tokens) have been replaced with `REPLACE_WITH_*` placeholders. See each stack's README for instructions on generating and filling in the required values.

---

## Stacks

| Stack | Description |
|-------|-------------|
| [ai-stack](ai-stack/) | Ollama + LibreChat + AnythingLLM + n8n + OpenHands â€” fully local AI with optional OpenAI fallback |
| [authentik](authentik/) | Open-source identity provider and SSO â€” OAuth2/OIDC, SAML, MFA, and forward auth for all your services |
| [karakeep](karakeep/) | Self-hosted bookmark manager with full-page archiving, video downloads, and AI summarization |
| [immich](immich/) | Self-hosted photo and video backup â€” Google Photos replacement with data stored on host drive |
| [heimdall](heimdall/) | Home lab application dashboard â€” pin all your services in one place with live status tiles |
| [nextcloud](nextcloud/) | Self-hosted file sync and share â€” Dropbox/Google Drive replacement with PostgreSQL and Redis |
| [nginx-proxy-manager](nginx-proxy-manager/) | Reverse proxy with web UI and automatic Let's Encrypt SSL â€” no config files needed |
| [wordpress](wordpress/) | Self-hosted WordPress with MariaDB and host-path storage for plugins, themes, and uploads |
| [calibre-web](calibre-web/) | Web UI for your Calibre ebook library with OPDS support for e-reader apps |
| [crafty](crafty/) | Web-based Minecraft server manager â€” create and run multiple Java and Bedrock servers |
| [uptime-kuma](uptime-kuma/) | Self-hosted uptime monitor with status pages and 90+ alert integrations |
| [plex](plex/) | Media server for movies, TV, and music â€” streams to any device with hardware transcode support |
| [jellyfin](jellyfin/) | Free open-source media server â€” no account or Plex Pass required, full hardware transcode support |
| [mumble](mumble/) | Self-hosted low-latency voice chat server â€” no accounts or subscriptions required |
| [vaultwarden](vaultwarden/) | Lightweight self-hosted Bitwarden-compatible password manager â€” works with all official Bitwarden clients |
| [mailcow](mailcow/) | Full self-hosted email server â€” Postfix, Dovecot, Rspamd, ClamAV, SOGo webmail, and automatic SSL in one stack |

---

## Conventions

- Secrets use `REPLACE_WITH_HEX_SECRET` â€” generate with `openssl rand -hex 32`
- API keys use `REPLACE_WITH_API_KEY`
- Optional environment variables are commented with `# optional`
- Each stack uses isolated named networks (no cross-stack communication by default)
- Persistent data uses either named Docker volumes or host path mounts (noted per stack)

---

## Usage

Each stack is independent. To bring one up:

```bash
cd ai-stack
docker compose up -d
```

To stop:

```bash
docker compose down
```

To stop and remove volumes (âš  deletes all data):

```bash
docker compose down -v
```

---

## Deploying via Portainer

Each stack can be deployed directly from this Git repository using Portainer's **Repository** stack option.

1. In Portainer, go to **Stacks → Add stack → Repository**
2. Fill in the fields:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `<stack-folder>/docker-compose.yml` (e.g. `immich/docker-compose.yml`) |

3. Under **Environment variables**, add any `REPLACE_WITH_*` values required by that stack
4. Click **Deploy the stack**

> Portainer will pull the compose file directly from GitHub. Enable **Automatic updates** in the stack settings to re-deploy on every push.

> **Note for large images (e.g. ai-stack):** Portainer may time out with a 504 error while pulling heavy images like OpenHands. If this happens, pre-pull the images manually over SSH before deploying:
> ```bash
> docker pull ghcr.io/all-hands-ai/openhands:latest
> docker pull ghcr.io/all-hands-ai/runtime:latest
> ```
> Then redeploy the stack — Portainer will use the locally cached images and won't time out.

---

## BaumLab Ecosystem

BaumDocker is part of a broader set of self-hosted homelab tools built under the BaumLab umbrella. Each project is independent but designed to work well alongside the stacks in this repo.

| Project | Description |
|---------|-------------|
| **[BaumDocker](https://github.com/Bruiserbaum/BaumDocker)** | *(this repo)* Docker Compose stacks for home lab services |
| **[BaumLabBackup](https://github.com/Bruiserbaum/BaumLabBackup)** | Self-hosted Docker backup manager — schedule backups of container volumes and databases to Backblaze B2, NAS, SFTP, or local storage. Web UI with TOTP/MFA, job history, and log viewer |
| **[BaumOllamaCoding](https://github.com/Bruiserbaum/BaumOllamaCoding)** | VS Code extension for local AI coding — streaming chat, multi-model support, file/image attachments, GitHub integration, and an OpenHands agent launcher |

### How they fit together

- Deploy your services with **BaumDocker** stacks (Ollama, Nextcloud, Immich, Vaultwarden, etc.)
- Protect your data with **BaumLabBackup** — point it at the running containers and it handles stopping, dumping, archiving, and uploading on a schedule
- Use **BaumOllamaCoding** in VS Code to chat with the Ollama instance from your ai-stack, or launch an OpenHands agent to work on your codebase

---

## License and Project Status

This repository is a personal project shared publicly for learning, reference, portfolio, and experimentation purposes.

Development may include AI-assisted ideation, drafting, refactoring, or code generation. All code and content published here were reviewed, selected, and curated before release.

This project is licensed under the Apache License 2.0. See the LICENSE file for details.

Unless explicitly stated otherwise, this repository is provided as-is, without warranty, support obligation, or guarantee of suitability for production use.

Any third-party libraries, assets, icons, fonts, models, or dependencies used by this project remain subject to their own licenses and terms.