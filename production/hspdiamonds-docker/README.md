# ERPNext v15 Production Stack (HSP Diamonds)

Production Docker stack for `erp.hspdiamonds.com` (ERPNext v15 + India Compliance v15), tuned for a 16 GB VPS sharing resources with Supabase GoTrue, Postgres, and Next.js.

## What this bundle includes

- `Dockerfile.backend` - backend image based on `frappe/erpnext:v15`
- `docker-compose.yml` - MariaDB 10.6 + Redis + ERP services with memory caps
- `.env.example` - runtime variables template
- `apps.json` - app manifest (`erpnext`, `india-compliance`)
- `setup.sh` - one-liner bootstrap entrypoint
- `scripts/deploy.sh` - deploy + app checkout/update + migrate
- `scripts/backup.sh` - backup flow (`down -> tar -> up`)
- `scripts/restore.sh` - restore flow

---

## Final deployment instructions (recommended)

### 1) Clone into VPS target path

```bash
sudo mkdir -p /home/erpnext && sudo chown -R $USER:$USER /home/erpnext
cd /home/erpnext
git clone https://github.com/conceptivecon/frappe_docker.git docker
cd docker/production/hspdiamonds-docker
```

### 2) Prepare environment

```bash
cp .env.example .env
nano .env
```

Set at minimum:
- `CUSTOM_IMAGE`
- `CUSTOM_TAG`
- `SITE_NAME=erp.hspdiamonds.com`
- `SITE_DB_NAME`
- `ADMIN_PASSWORD`
- `DB_ROOT_PASSWORD`

For mutable custom app updates:
- Optional: `HOST_APPS_DIR=/home/erpnext/apps` (default) keeps app repos in `/home/erpnext/apps` while compose mounts `./apps` via symlink.
- `CUSTOM_APP_REPO=git@github.com:conceptivecon/jewelry-erp.git`
- `CUSTOM_APP_BRANCH=version-15`
- `CUSTOM_APP_NAME=hspdiamonds`

### 3) Deploy

```bash
./scripts/deploy.sh
```

This creates folders, checks out/updates apps in `./apps`, starts all services, runs `bench migrate`, and keeps custom app install/update workflow mutable (git-based, not image-immutable).

### 4) Validate and access bench

```bash
docker compose --env-file .env ps
docker compose --env-file .env logs -f backend
docker compose --env-file .env exec backend bench console
```

### 5) Reverse proxy/domain

Route `erp.hspdiamonds.com` -> VPS `:8080` (or `HTTP_PORT`), and terminate TLS at Nginx/Caddy/Traefik on host.

---

## One-liner bootstrap

```bash
curl -sSL https://raw.githubusercontent.com/conceptivecon/frappe_docker/feature-frappe-docker-hspdiamonds/production/hspdiamonds-docker/setup.sh | bash
```

---

## Hot app update (mutable custom app)

```bash
cd /home/erpnext/apps/hspdiamonds
git pull
./scripts/deploy.sh
```

`deploy.sh` runs migrate and restarts/updates the stack, so schema and patches apply after each app update.

---

## Backup / restore

```bash
./scripts/backup.sh
./scripts/restore.sh backups/erpnext-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
```

Cron example:

```cron
0 2 * * * cd /home/erpnext/docker/production/hspdiamonds-docker && ./scripts/backup.sh >> /var/log/erpnext-backup.log 2>&1
```

---

## Notes on app strategy

- This setup intentionally keeps custom apps mutable and git-managed under `./apps`.
- `APPS_JSON_BASE64` is retained for compatibility with existing tooling but custom app updates are designed to happen through `git pull` + `./scripts/deploy.sh`.
