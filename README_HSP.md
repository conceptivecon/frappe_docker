# Harika Solitaire Privé - Production Deployment (HSP)

This deployment keeps all persistent ERPNext data under `/home/erpnext` and is designed for single-server production use.

## Directory layout

```bash
mkdir -p /home/erpnext/{sites,logs,assets,apps,mariadb,redis,docker,.ssh}
```

Expected structure:

- `/home/erpnext/sites`
- `/home/erpnext/logs`
- `/home/erpnext/assets`
- `/home/erpnext/apps`
- `/home/erpnext/mariadb`
- `/home/erpnext/redis`
- `/home/erpnext/.ssh`

## First run

From your repo root (`/home/erpnext/docker`):

```bash
docker compose up -d
```

## Enter backend container

```bash
docker exec -it backend bash
```

## Create default site

```bash
bench new-site erp.hspdiamonds.com
```

## Install apps

```bash
bench --site erp.hspdiamonds.com install-app erpnext
```

Install custom app (after cloning into `/home/erpnext/apps/hspdiamonds`):

```bash
bench --site erp.hspdiamonds.com install-app hspdiamonds
```

## Git-based app updates

```bash
cd /home/erpnext/apps/hspdiamonds
git pull
docker restart backend
```

If needed after updates:

```bash
docker exec -it backend bench --site erp.hspdiamonds.com migrate
```

## Cloudflare + local NGINX reverse proxy

- Point Cloudflare DNS `erp.hspdiamonds.com` to your VPS.
- Keep this stack bound on localhost (`127.0.0.1:${HTTP_PORT:-8080}`) and proxy with host NGINX.
- In host NGINX, pass `Host`, `X-Forwarded-For`, and `X-Forwarded-Proto` headers.

## Persistence guarantee

The stack uses bind mounts only (no Docker named volumes), so data survives:

```bash
docker compose down
docker compose up -d
```

as long as `/home/erpnext/*` directories are preserved.
