# Portainer

Stack manager for every other compose project on this host, deployed once via `docker compose up -d` here and then used to GitOps-sync the rest: ai-stack, code-server, baumai, showlister, and arm-docker are each registered in Portainer as a "stack from repository," pointed at their own GitHub repo/subfolder, polling for changes on an interval so `git push` is enough to redeploy - no manual `docker compose up -d` on the host needed for those five anymore.

Portainer itself is the one exception: it's started directly here, not managed as a GitOps stack of itself, to avoid a chicken-and-egg bootstrap problem.

## Setup

```
docker compose up -d
```

Then open `https://<host>:9443`, create the admin account (first-run window is short - if you miss it, restart the container), and add each of the other repos as a stack:

**Settings > add each repo's SSH deploy key first**, or under each stack's own Git auth. The deploy key used here is `~/.ssh/portainer-gitops` (ed25519, read-only, added as a deploy key to BaumDocker, BaumAI, show-lister, and Baum-AutoRipper on GitHub - see `gh repo deploy-key list <repo>` to check).

| Stack name | Repo | Branch | Compose path |
|---|---|---|---|
| ai-stack | Bruiserbaum/BaumDocker | master | ai-stack/docker-compose.yml |
| code-server | Bruiserbaum/BaumDocker | master | code-server/docker-compose.yml |
| baumai | Bruiserbaum/BaumAI | master | docker-compose.yml |
| showlister | Bruiserbaum/show-lister | main | docker-compose.yml |
| arm-docker | Bruiserbaum/Baum-AutoRipper | main | docker-compose.yml |

The stack **name** in Portainer has to match the existing compose project name exactly (left column above) - that's what makes Portainer adopt the already-running containers in place instead of standing up duplicates alongside them.
