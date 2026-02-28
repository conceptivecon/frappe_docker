#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-.env}"
FORCE="${FORCE:-0}"
PURGE_IMAGES="${PURGE_IMAGES:-0}"
PURGE_DATA="${PURGE_DATA:-0}"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--force] [--purge-images] [--purge-data]

Safely reset the HSP Docker stack so you can start fresh.

Options:
  --force         Skip interactive confirmation.
  --purge-images  Remove local images after stopping the stack.
  --purge-data    Remove persistent data directories under /home/erpnext.

Examples:
  ./scripts/cleanup_fresh_start.sh --force
  ./scripts/cleanup_fresh_start.sh --force --purge-images --purge-data
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --purge-images) PURGE_IMAGES=1 ;;
    --purge-data) PURGE_DATA=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $arg"
      usage
      exit 1
      ;;
  esac
done

if [[ "$FORCE" != "1" ]]; then
  echo "This will stop and remove HSP containers/networks."
  if [[ "$PURGE_IMAGES" == "1" ]]; then
    echo "It will also remove local Docker images."
  fi
  if [[ "$PURGE_DATA" == "1" ]]; then
    echo "It will also delete persistent directories under /home/erpnext."
  fi
  read -r -p "Continue? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

echo "[1/5] Stopping compose stack"
docker compose --env-file "$ENV_FILE" down --remove-orphans || true

echo "[2/5] Removing stopped containers"
docker container prune -f >/dev/null || true

echo "[3/5] Removing unused networks"
docker network prune -f >/dev/null || true

if [[ "$PURGE_IMAGES" == "1" ]]; then
  echo "[4/5] Removing unused images"
  docker image prune -a -f >/dev/null || true
else
  echo "[4/5] Skipping image purge (use --purge-images to enable)"
fi

if [[ "$PURGE_DATA" == "1" ]]; then
  echo "[5/5] Deleting persistent data under /home/erpnext"
  rm -rf /home/erpnext/sites \
         /home/erpnext/logs \
         /home/erpnext/assets \
         /home/erpnext/apps \
         /home/erpnext/mariadb \
         /home/erpnext/redis
  mkdir -p /home/erpnext/{sites,logs,assets,apps,mariadb,redis,docker,.ssh}
  echo "Recreated empty directory structure under /home/erpnext"
else
  echo "[5/5] Skipping data wipe (use --purge-data to enable)"
fi

echo "Done. Start fresh with: docker compose --env-file $ENV_FILE up -d"
