# Local Volumes for Easy Backup and Restore

This guide keeps all important runtime data under `./local-data` so you can back up and restore with standard filesystem tools.

## What is persisted locally

When using `overrides/compose.local-volumes.yaml` with MariaDB and Redis overrides, data is written to:

- `./local-data/sites` → sites, uploaded files, private files, site configs
- `./local-data/mariadb` → MariaDB data directory
- `./local-data/redis-queue` → Redis queue persistence data

> This does not replace image-based custom app installation. Keep custom app source declarations in your image build inputs (`apps.json`) and version control.

## Why this setup

- Easy host-level backup (`tar`, `rsync`, snapshot tools)
- Easier restore/migration to another host
- Reduced memory footprint defaults for DB/Redis suitable for small single-node installs

## Start command

Create local folders first:

```bash
mkdir -p local-data/sites local-data/mariadb local-data/redis-queue
```

Run with local persistence:

```bash
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.local-volumes.yaml \
  up -d
```

## Memory tuning knobs

The override sets conservative defaults that you can tune:

- `MARIADB_BUFFER_POOL_SIZE` (default: `256M`)
- `MARIADB_LOG_BUFFER_SIZE` (default: `32M`)
- `MARIADB_MAX_CONNECTIONS` (default: `120`)
- `REDIS_CACHE_MAXMEMORY` (default: `128mb`)
- `REDIS_QUEUE_MAXMEMORY` (default: `256mb`)

Example:

```bash
MARIADB_BUFFER_POOL_SIZE=192M \
REDIS_CACHE_MAXMEMORY=96mb \
REDIS_QUEUE_MAXMEMORY=192mb \
docker compose \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.local-volumes.yaml \
  up -d
```

## Backup and restore

### Backup

Stop writes first for consistency:

```bash
docker compose stop backend queue-short queue-long scheduler websocket frontend
```

Archive the local data:

```bash
tar -czf frappe-local-data-$(date +%F).tar.gz local-data/
```

Start services again:

```bash
docker compose start backend queue-short queue-long scheduler websocket frontend
```

### Restore

Stop stack:

```bash
docker compose down
```

Restore data:

```bash
tar -xzf frappe-local-data-YYYY-MM-DD.tar.gz
```

Start stack with the same compose files used during backup.
