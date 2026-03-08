# AI Stack

A self-hosted AI stack running entirely on your home lab. Built around [Ollama](https://ollama.com/) as the local LLM backend, with multiple chat frontends sharing the same model server.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **Ollama** | 11434 | Local LLM runtime — serves models to all other services |
| **LibreChat** | 3000 | Full-featured ChatGPT-style UI with multi-model support |
| **AnythingLLM** | 3001 | RAG-enabled workspace chat with document uploads |
| **OpenClaw** | 18789 / 18791 | Lightweight chat + agent gateway |
| **MongoDB** | — (internal) | Database backend for LibreChat |

## Models pulled on first start

Ollama pulls these automatically on container startup if not already present:

- `qwen2.5:7b-instruct` — general instruction-following
- `qwen2.5-coder:7b` — code generation
- `llama3.2:3b` — fast lightweight model

Edit the `entrypoint` block in `docker-compose.yml` to add or swap models.

## Networks

| Network | Purpose |
|---------|---------|
| `ai_frontend` | Services that need external port exposure |
| `ai_backend` | Internal service-to-service communication |

MongoDB is on `ai_backend` only — it has no exposed ports and is not reachable from the host.

## Setup

### 1. Generate secrets

Each secret should be a unique 64-character hex string:

```bash
openssl rand -hex 32
```

Replace all `REPLACE_WITH_HEX_SECRET` values in `docker-compose.yml` with separate generated values.

### 2. Set API keys (optional)

If you want OpenAI as a fallback model source, replace `REPLACE_WITH_API_KEY` with your key.
Remove those lines entirely if you want a fully local setup.

### 3. Create the LibreChat config

LibreChat requires a config file at `/opt/librechat/librechat.yaml` on the host:

```bash
sudo mkdir -p /opt/librechat
sudo touch /opt/librechat/librechat.yaml
```

See the [LibreChat docs](https://www.librechat.ai/docs/configuration/librechat_yaml) for configuration options.

### 4. Start the stack

```bash
docker compose up -d
```

Ollama will pull models on first start — this may take several minutes depending on your connection.

### 5. Access the UIs

- LibreChat: `http://your-server-ip:3000`
- AnythingLLM: `http://your-server-ip:3001`
- OpenClaw: `http://your-server-ip:18789`

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
