# KaraKeep

A self-hosted bookmark and read-later manager with full-page archiving, video downloads, AI summarization, and full-text search.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **KaraKeep** | 3000 | Main web UI |
| **Chrome** | 9222 (internal) | Headless browser for full-page crawling and archiving |
| **Meilisearch** | 7700 (internal) | Full-text search engine |

Chrome and Meilisearch have no exposed host ports — they are only reachable by KaraKeep internally.

## Setup

### 1. Generate secrets

`NEXTAUTH_SECRET` and `MEILI_MASTER_KEY` must each be a unique 64-character hex string, **and the `MEILI_MASTER_KEY` value must be identical in both the `web` and `meilisearch` services.**

```bash
openssl rand -hex 32   # run twice — one for NEXTAUTH_SECRET, one for MEILI_MASTER_KEY
```

Replace the `REPLACE_WITH_HEX_SECRET` placeholders in `docker-compose.yml` accordingly.

### 2. Set your URL

Set `NEXTAUTH_URL` to the address KaraKeep will be accessed from:

```
NEXTAUTH_URL: https://karakeep.yourdomain.com
# or for local-only access:
NEXTAUTH_URL: http://your-server-ip:3000
```

### 3. Set API key (optional)

`OPENAI_API_KEY` enables AI-powered bookmark summarization. Remove the line entirely to disable this feature and run fully offline.

### 4. Start the stack

```bash
docker compose up -d
```

### 5. Access

Navigate to `http://your-server-ip:3000` (or your `NEXTAUTH_URL`).

Signups are disabled by default (`DISABLE_SIGNUPS: true`) — create your account on first launch before disabling signups, or temporarily set it to `false`.

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `karakeep/docker-compose.yml` |

3. Under **Environment variables**, add `NEXTAUTH_SECRET`, `MEILI_MASTER_KEY`, `NEXTAUTH_URL`, and optionally `OPENAI_API_KEY`
4. Click **Deploy the stack**

> `MEILI_MASTER_KEY` must be the **same value** in both the `web` and `meilisearch` environment variables — set it once here and it applies to both.

## Data

| Path | Contents |
|------|----------|
| `./data` | KaraKeep uploads, database, and app data |
| `./meilisearch` | Meilisearch index data |

Both paths are relative to the directory where you run `docker compose`.
