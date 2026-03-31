# AI Stack

A self-hosted AI stack running entirely on your home lab. Built around [Ollama](https://ollama.com/) as the local LLM backend, with multiple chat frontends sharing the same model server.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Ollama** | 11434 | Local LLM runtime — serves models to all other services |
| **LibreChat** | 3000 | Full-featured ChatGPT-style UI with multi-model support |
| **AnythingLLM** | 3001 | RAG-enabled workspace chat with document uploads |
| **n8n** | 5678 | Workflow automation — orchestrates Ollama and AnythingLLM via built-in nodes |
| **MongoDB** | — (internal) | Database backend for LibreChat |

## Models pulled on first start

Ollama pulls these automatically on container startup if not already present:

- `qwen2.5:7b-instruct` — general instruction-following
- `llama3.2:3b` — fast lightweight model

Edit the `entrypoint` block in `docker-compose.yml` to add or swap models.

## Networks

| Network | Purpose |
|---------|---------|
| `ai_frontend` | Services that need external port exposure |
| `ai_backend` | Internal service-to-service communication |

MongoDB is on `ai_backend` only — it has no exposed ports and is not reachable from the host.

## Setup

### 1. Create your .env file

```bash
cp .env.example .env
```

Open `.env` and fill in every blank value. Generate each secret with:

```bash
openssl rand -hex 32
```

Each secret field must have a **unique** value — do not reuse the same string across fields.

Set `OPENAI_API_KEY` if you want OpenAI as a fallback model source, or leave it blank for a fully local setup.

### 2. Configure LibreChat login

By default, email login is enabled and registration is disabled. Control this with two env vars:

| Variable | Default | Description |
|----------|---------|-------------|
| `LIBRECHAT_ALLOW_EMAIL_LOGIN` | `true` | Allow username/password login |
| `LIBRECHAT_ALLOW_REGISTRATION` | `false` | Allow new users to self-register |

Set both to `false` if using Authentik SSO (see below).

### 3. Create the LibreChat config

LibreChat requires a config file at `/opt/librechat/librechat.yaml` on the **Docker host**:

```bash
sudo mkdir -p /opt/librechat
sudo touch /opt/librechat/librechat.yaml
```

See the [LibreChat docs](https://www.librechat.ai/docs/configuration/librechat_yaml) for configuration options.

### 4. Start the stack

```bash
docker compose up -d
```

Ollama will pull models on first start — allow a few minutes depending on model size and connection speed.

### 5. Access the UIs

- LibreChat: `http://your-server-ip:3000`
- AnythingLLM: `http://your-server-ip:3001`
- n8n: `http://your-server-ip:5678`

## n8n + Ollama + AnythingLLM Integration

n8n connects to both services over the internal `ai_backend` network using their container hostnames — no external URLs needed.

### Calling Ollama from n8n

Use the built-in **Ollama Chat Model** node (under AI nodes) or an **HTTP Request** node:

- Base URL: `http://ollama:11434`
- Generate endpoint: `POST http://ollama:11434/api/generate`
- Chat endpoint: `POST http://ollama:11434/api/chat`

### Calling AnythingLLM from n8n

AnythingLLM exposes a REST API. Use the **HTTP Request** node:

- Base URL: `http://anythingllm:3001/api`
- Auth: Bearer token from AnythingLLM → Settings → API Keys
- Example — chat with a workspace:
  ```
  POST http://anythingllm:3001/api/v1/workspace/{slug}/chat
  Body: { "message": "...", "mode": "chat" }
  ```

### Example workflow ideas

- Document ingested into AnythingLLM → n8n triggers a summarisation job via Ollama → sends result to Slack/email
- Scheduled n8n workflow queries Ollama with a system prompt for daily briefings
- Webhook → n8n → AnythingLLM workspace query → return response to caller

## Deploying via Portainer

1. Go to **Stacks → Add stack → Repository**
2. Fill in:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/Bruiserbaum/BaumDocker` |
| Repository reference | `refs/heads/master` |
| Compose path | `ai-stack/docker-compose.yml` |

3. Under **Environment variables**, add every value from `.env.example`
4. Click **Deploy the stack**

## Authentik SSO for LibreChat (Optional)

LibreChat supports OpenID Connect login. To enable SSO via Authentik:

### 1. Create the provider in Authentik

- Admin → Applications → **Create with Wizard**
- Name: `LibreChat`
- Provider type: **OAuth2/OpenID Provider**
- Redirect URI: `https://librechat.yourdomain.com/oauth/openid/callback`
- Subject mode: **Based on the User's Email**
- **Encryption Key: leave blank** — do not set an encryption key. If one is set, Authentik issues JWE-encrypted ID tokens that LibreChat cannot decrypt, causing a silent "unsupported operation" error on login.
- Note the **Client ID** and **Client Secret** from the provider details page

### 2. Set these environment variables in Portainer

| Variable | Value |
|----------|-------|
| `LIBRECHAT_OPENID_ISSUER` | `http://YOUR_AUTHENTIK_HOST:9100/application/o/librechat/.well-known/openid-configuration` |
| `LIBRECHAT_OPENID_CLIENT_ID` | Client ID from Authentik |
| `LIBRECHAT_OPENID_CLIENT_SECRET` | Client Secret from Authentik |
| `LIBRECHAT_OPENID_SESSION_SECRET` | Any random secret (`openssl rand -hex 32`) |
| `LIBRECHAT_ALLOW_EMAIL_LOGIN` | `false` |
| `LIBRECHAT_ALLOW_REGISTRATION` | `false` |

Then uncomment the `OPENID_*` block in `docker-compose.yml` under the `librechat` service and redeploy.

### 3. Redeploy LibreChat

```bash
docker compose up -d librechat
```

A **"Login with Authentik"** button will appear on the LibreChat login page.

### Migrating an existing local account to SSO

If a user was previously registered with a password (local provider) and now needs to log in via Authentik, LibreChat will block the login with "user was registered with 'local' provider". Update the account in MongoDB:

```bash
docker exec librechat-mongodb mongosh LibreChat --eval \
  "db.users.updateOne({email: 'user@example.com'}, {\$set: {provider: 'openid', openidId: 'user@example.com'}})"
```

Replace `user@example.com` with the account's email. The `openidId` must match the `sub` claim from Authentik, which equals the email when Subject Mode is set to "Based on the User's Email".

## GPU Acceleration (optional)

To enable NVIDIA GPU passthrough for Ollama, add to the `ollama` service:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).
