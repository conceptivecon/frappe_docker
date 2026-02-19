#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 backups/erpnext-backup-YYYY-MM-DD_HH-MM-SS.tar.gz"
  exit 1
fi

ARCHIVE="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Archive not found: $ARCHIVE"
  exit 1
fi

docker compose --env-file .env down

tar -xzf "$ARCHIVE"

docker compose --env-file .env up -d --build

echo "Restore complete from: $ARCHIVE"
