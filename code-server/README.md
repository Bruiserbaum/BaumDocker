# code-server

Browser-based VS Code ([coder/code-server](https://github.com/coder/code-server), packaged via [LinuxServer.io](https://docs.linuxserver.io/images/docker-code-server/) to match the rest of this stack's images). Lets you pick up coding work — BaumAI, BaumAgent, BaumDocker, baumagent-clients, ai-env — from any browser, not just this box.

## Services

| Service | Port | Description |
|---------|------|-------------|
| **code-server** | 8443 (container) / `${CODE_SERVER_PORT:-8090}` (host) | Web IDE |

## Scope

Workspace mount is `~/Projects` only (`CODE_SERVER_WORKSPACE` in `.env`) — deliberately **not** the whole home directory and **not** the Obsidian vault. It also deliberately does **not** mount BaumAI's `data/repos` (the agent's own per-task sandbox checkouts, root-owned, ephemeral UUID dirs — not meant for manual editing) and does **not** mount `/var/run/docker.sock` (no Docker-outside-of-Docker access from the browser terminal, unlike BaumAI's `worker` container). Both were deliberate choices to keep this a plain dev-editing surface rather than another privileged control plane — revisit only if that becomes real friction.

Joins the ai-stack's `ai_frontend`/`ai_backend` networks so the integrated terminal can reach Ollama and the other ai-stack services by container name for testing — same networks BaumAI's `api`/`worker` containers use.

## Setup

### 1. Copy and fill in `.env`

```bash
cp .env.example .env
```

Generate a password for `CODE_SERVER_PASSWORD`:

```bash
openssl rand -base64 24
```

### 2. Start the stack

```bash
docker compose up -d
```

### 3. Direct LAN access (before Authentik/NPM are wired up)

`http://<box-ip>:8090` — prompts for `CODE_SERVER_PASSWORD`.

### 4. Wire up Authentik + NPM (same pattern as every other app in this stack)

1. In Nginx Proxy Manager, add a new Proxy Host for `code.baumwire.com` → this container's host port (`8090` by default).
2. Paste [`../authentik/snippets/code-server-npm-forward-auth.conf`](../authentik/snippets/code-server-npm-forward-auth.conf) into the Advanced tab (replace `AUTHENTIK_HOST`). Unlike the other snippets in that folder, this one adds WebSocket upgrade headers — code-server's terminal and live editing need a persistent connection.
3. In Authentik: Admin → Applications → Providers → Create → Proxy Provider (forward auth, single application, external host `https://code.baumwire.com`), then Admin → Applications → Create to link it, then add it to the embedded outpost.

This part needs an authenticated Authentik admin session + NPM login, so it isn't something that can be scripted blind — see the BaumAI README's "GitHub & Obsidian Vault Access" section for the same click-through pattern already used for `baumagent`/`anythingllm`/`automate`/`dockge`.

Once live, you end up with two gates (NPM/Authentik at the proxy, `CODE_SERVER_PASSWORD` at the app) — same defense-in-depth the rest of the ai-stack already uses.
