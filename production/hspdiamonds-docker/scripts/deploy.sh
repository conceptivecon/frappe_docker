#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -f .env ]] || cp .env.example .env

./scripts/setup-directories.sh
cp -f config/* /home/erpnext/config/
./scripts/generate-common-site-config.sh

docker compose --env-file .env pull
docker compose --env-file .env up -d

echo "Deployment started."
echo "Next: clone apps and run bench new-site/install-app commands from README.md"
