#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
TARGET_FILE="/home/erpnext/sites/common_site_config.json"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy .env.example to .env first."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

mkdir -p /home/erpnext/sites
cat > "${TARGET_FILE}" <<JSON
{
  "db_host": "${DB_HOST}",
  "redis_cache": "${REDIS_CACHE}",
  "redis_queue": "${REDIS_QUEUE}",
  "redis_socketio": "${REDIS_SOCKETIO}",
  "socketio_port": ${SOCKETIO_PORT}
}
JSON

chown 1000:1000 "${TARGET_FILE}"
echo "Generated ${TARGET_FILE}"
