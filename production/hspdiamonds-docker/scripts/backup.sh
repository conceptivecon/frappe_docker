#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STAMP=$(date +%F_%H-%M-%S)
DEST="backups/erpnext-backup-${STAMP}.tar.gz"
mkdir -p backups

# Consistent backup flow requested: down -> tar -> up
docker compose --env-file .env down

tar -czf "$DEST" apps sites mariadb assets logs redis-queue redis-cache .env docker-compose.yml Dockerfile.backend apps.json

docker compose --env-file .env up -d

echo "Backup created: $DEST"
