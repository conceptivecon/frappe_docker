# ERPNext v15 Production Stack (HSP Diamonds)

Production Docker stack for `erp.hspdiamonds.com` (ERPNext v15 + India Compliance v15), tuned for a 16 GB VPS sharing resources with Supabase GoTrue, Postgres, and Next.js.

## What this bundle includes

- `Dockerfile.backend` - backend image based on `frappe/erpnext:v15.58.4`
- `docker-compose.yml` - MariaDB 10.6 + Redis + ERP services with memory caps
- `.env.example` - runtime variables template
- `apps.json` - app manifest (`erpnext`, `india-compliance`)
- `setup.sh` - one-liner bootstrap entrypoint
- `scripts/deploy.sh` - deploy + app checkout + env sync
- `scripts/backup.sh` - backup flow (`down -> tar -> up`)
- `scripts/restore.sh` - restore flow

---

## Final deployment instructions (recommended)

### 1) Clone into VPS target path

```bash
sudo mkdir -p /home/erpnext && sudo chown -R $USER:$USER /home/erpnext
cd /home/erpnext
git clone https://github.com/yourcompany/frappe_docker.git docker
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

### 3) Deploy

```bash
./scripts/deploy.sh
```

This creates folders, checks out `erpnext` + `india-compliance` in `./apps`, updates `APPS_JSON_BASE64` from `apps.json`, and starts all services.

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
curl -sSL https://raw.githubusercontent.com/yourcompany/frappe_docker/main/production/hspdiamonds-docker/setup.sh | bash
```

---

## Hot app update

```bash
cd apps/my-custom-app
git pull
docker compose --env-file .env restart backend websocket queue-short queue-long scheduler
```

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

## Gaps in `apps.json` (important)

Current file:

```json
[
  {"url": "https://github.com/frappe/erpnext", "branch": "version-15"},
  {"url": "https://github.com/frappe/india-compliance", "branch": "version-15"}
]
```

Known gaps to address for stricter production control:

1. **No commit pinning**: branch-only references can drift. Prefer immutable SHAs/tags in your app checkout pipeline.
2. **No custom jewelry apps listed**: add your private/custom app repositories for production parity.
3. **`APPS_JSON_BASE64` not consumed by current Dockerfile build stage**: in this bundle app installation is performed at runtime (`create-site` + mounted `./apps`) rather than baked via build arg.
4. **No explicit dependency lockfile for custom apps**: if your custom apps add Python/Node deps, define and test them in CI.

If you want immutable builds, move to a build-time app-install flow (using `bench init --apps_path`) and push only fully baked images.
