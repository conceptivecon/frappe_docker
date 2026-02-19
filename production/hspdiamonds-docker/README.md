# ERPNext v15 Production Stack (HSP Diamonds)

Production-grade Docker setup for `erp.hspdiamonds.com` with ERPNext v15 and India Compliance v15, tuned for a 16 GB VPS coexisting with Supabase GoTrue, Postgres, and Next.js.

## Folder layout

- `Dockerfile.backend` - custom backend image based on `frappe/erpnext:v15.58.4`
- `docker-compose.yml` - full stack with memory caps and persistent local volumes
- `.env` - deployment runtime config + `APPS_JSON_BASE64`
- `apps.json` - app bundle (`erpnext`, `india-compliance`)
- `scripts/deploy.sh` - fast deployment
- `scripts/backup.sh` - shutdown/tar/start backup flow
- `scripts/restore.sh` - restore archive and bring stack up
- `setup.sh` - one-command VPS bootstrap

## One-line VPS bootstrap

```bash
curl -sSL https://raw.githubusercontent.com/yourcompany/frappe_docker/main/production/hspdiamonds-docker/setup.sh | bash
```

## Local test

```bash
docker compose --env-file .env up --build
```

## Bench access (no SSH inside container)

```bash
docker compose --env-file .env exec backend bench console
```

## Hot app update flow

```bash
cd apps/my-custom-app
git pull
docker compose --env-file .env restart backend websocket queue-short queue-long scheduler
```

## Backup and restore

```bash
# Backup (down -> tar -> up)
./scripts/backup.sh

# Restore from archive
./scripts/restore.sh backups/erpnext-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
```

## Daily backup cron example

```cron
0 2 * * * cd /home/erpnext/docker/production/hspdiamonds-docker && ./scripts/backup.sh >> /var/log/erpnext-backup.log 2>&1
```
