# BaumDocker

A collection of Docker Compose stacks for home lab use. Each stack is self-contained in its own folder with a README covering setup, ports, and any required configuration.

All sensitive values (API keys, secrets, tokens) have been replaced with `REPLACE_WITH_*` placeholders. See each stack's README for instructions on generating and filling in the required values.

---

## Stacks

| Stack | Description |
|-------|-------------|
| [ai-stack](ai-stack/) | Ollama + LibreChat + AnythingLLM + OpenClaw â€” fully local AI with optional OpenAI fallback |
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

## License and Project Status

This repository is a personal project shared publicly for learning, reference, portfolio, and experimentation purposes.

Development may include AI-assisted ideation, drafting, refactoring, or code generation. All code and content published here were reviewed, selected, and curated before release.

This project is licensed under the Apache License 2.0. See the LICENSE file for details.

Unless explicitly stated otherwise, this repository is provided as-is, without warranty, support obligation, or guarantee of suitability for production use.

Any third-party libraries, assets, icons, fonts, models, or dependencies used by this project remain subject to their own licenses and terms.