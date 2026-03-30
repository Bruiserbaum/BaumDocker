# BaumDocker

A collection of Docker Compose stacks for home lab use. Each stack is self-contained in its own folder with a README covering setup, ports, and any required configuration.

All sensitive values (API keys, secrets, tokens) have been replaced with `REPLACE_WITH_*` placeholders. See each stack's README for instructions on generating and filling in the required values.

---

## Stacks

| Stack | Description | Source |
|-------|-------------|--------|
| [ai-stack](ai-stack/) | Ollama + LibreChat + AnythingLLM + n8n — fully local AI with optional OpenAI fallback | [Ollama](https://github.com/ollama/ollama) · [LibreChat](https://github.com/danny-avila/LibreChat) · [AnythingLLM](https://github.com/Mintplex-Labs/anything-llm) · [n8n](https://github.com/n8n-io/n8n) |
| [authentik](authentik/) | Open-source identity provider and SSO — OAuth2/OIDC, SAML, MFA, and forward auth for all your services | [goauthentik/authentik](https://github.com/goauthentik/authentik) |
| [automatic-ripping-machine](automatic-ripping-machine/) | Automatic CD/DVD/Blu-ray ripper — detects disc insertion, rips, transcodes, and ejects with no interaction | [automatic-ripping-machine](https://github.com/automatic-ripping-machine/automatic-ripping-machine) · [fork](https://github.com/Bruiserbaum/automatic-ripping-machine) |
| [calibre-web](calibre-web/) | Web UI for your Calibre ebook library with OPDS support for e-reader apps | [janeczku/calibre-web](https://github.com/janeczku/calibre-web) |
| [crafty](crafty/) | Web-based Minecraft server manager — create and run multiple Java and Bedrock servers | [crafty-controller/crafty-4](https://github.com/crafty-controller/crafty-4) |
| [glusterfs](glusterfs/) | Distributed filesystem for Docker Swarm shared storage — single node to start, expandable to multi-node replica with `setup.sh` | [gluster/gluster-containers](https://github.com/gluster/gluster-containers) |
| [heimdall](heimdall/) | Home lab application dashboard — pin all your services in one place with live status tiles | [linuxserver/Heimdall](https://github.com/linuxserver/Heimdall) |
| [immich](immich/) | Self-hosted photo and video backup — Google Photos replacement with data stored on host drive | [immich-app/immich](https://github.com/immich-app/immich) |
| [jellyfin](jellyfin/) | Free open-source media server — no account or Plex Pass required, full hardware transcode support | [jellyfin/jellyfin](https://github.com/jellyfin/jellyfin) |
| [karakeep](karakeep/) | Self-hosted bookmark manager with full-page archiving, video downloads, and AI summarization | [karakeep-app/karakeep](https://github.com/karakeep-app/karakeep) |
| [mailcow](mailcow/) | Full self-hosted email server — Postfix, Dovecot, Rspamd, ClamAV, SOGo webmail, and automatic SSL in one stack | [mailcow/mailcow-dockerized](https://github.com/mailcow/mailcow-dockerized) |
| [mumble](mumble/) | Self-hosted low-latency voice chat server — no accounts or subscriptions required | [mumble-voip/mumble](https://github.com/mumble-voip/mumble) |
| [nextcloud](nextcloud/) | Self-hosted file sync and share — all-in-one deployment with automatic database, cache, backup, and Talk setup | [nextcloud/all-in-one](https://github.com/nextcloud/all-in-one) |
| [nginx-proxy-manager](nginx-proxy-manager/) | Reverse proxy with web UI and automatic Let's Encrypt SSL — no config files needed | [NginxProxyManager/nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager) |
| [plex](plex/) | Media server for movies, TV, and music — streams to any device with hardware transcode support | [plexinc/pms-docker](https://github.com/plexinc/pms-docker) |
| [uptime-kuma](uptime-kuma/) | Self-hosted uptime monitor with status pages and 90+ alert integrations | [louislam/uptime-kuma](https://github.com/louislam/uptime-kuma) |
| [vaultwarden](vaultwarden/) | Lightweight self-hosted Bitwarden-compatible password manager — works with all official Bitwarden clients | [dani-garcia/vaultwarden](https://github.com/dani-garcia/vaultwarden) |
| [wordpress](wordpress/) | Self-hosted WordPress with MariaDB and host-path storage for plugins, themes, and uploads | [docker-library/wordpress](https://github.com/docker-library/wordpress) |

---

## Conventions

- Secrets use `REPLACE_WITH_HEX_SECRET` — generate with `openssl rand -hex 32`
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

To stop and remove volumes (⚠ deletes all data):

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