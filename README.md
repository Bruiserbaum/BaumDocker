# BaumDocker

A collection of Docker Compose stacks for home lab use. Each stack is self-contained in its own folder with a README covering setup, ports, and any required configuration.

All sensitive values (API keys, secrets, tokens) have been replaced with `REPLACE_WITH_*` placeholders. See each stack's README for instructions on generating and filling in the required values.

---

## Stacks

| Stack | Description |
|-------|-------------|
| [ai-stack](ai-stack/) | Ollama + LibreChat + AnythingLLM + OpenClaw — fully local AI with optional OpenAI fallback |
| [karakeep](karakeep/) | Self-hosted bookmark manager with full-page archiving, video downloads, and AI summarization |
| [immich](immich/) | Self-hosted photo and video backup — Google Photos replacement with data stored on host drive |
| [heimdall](heimdall/) | Home lab application dashboard — pin all your services in one place with live status tiles |

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
