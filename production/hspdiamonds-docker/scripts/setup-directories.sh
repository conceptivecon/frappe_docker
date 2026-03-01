#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/home/erpnext"
mkdir -p \
  "${BASE_DIR}/config" \
  "${BASE_DIR}/sites" \
  "${BASE_DIR}/apps" \
  "${BASE_DIR}/logs" \
  "${BASE_DIR}/mariadb" \
  "${BASE_DIR}/redis-cache" \
  "${BASE_DIR}/redis-queue" \
  "${BASE_DIR}/redis-socketio"

chown -R 1000:1000 "${BASE_DIR}"

echo "Directory setup complete under ${BASE_DIR}"
