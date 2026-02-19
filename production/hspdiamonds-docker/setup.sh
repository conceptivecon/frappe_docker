#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="/home/erpnext/docker"
REPO_URL="${REPO_URL:-https://github.com/yourcompany/frappe_docker.git}"
BRANCH="${BRANCH:-main}"

sudo mkdir -p /home/erpnext
sudo chown -R "$USER":"$USER" /home/erpnext

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
fi

if docker compose version >/dev/null 2>&1; then
  :
else
  sudo apt-get update && sudo apt-get install -y docker-compose-plugin
fi

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
else
  git -C "$TARGET_DIR" fetch origin "$BRANCH"
  git -C "$TARGET_DIR" checkout "$BRANCH"
  git -C "$TARGET_DIR" pull --ff-only
fi

cd "$TARGET_DIR/production/hspdiamonds-docker"
mkdir -p apps sites mariadb assets logs redis-queue redis-cache backups

./scripts/deploy.sh

echo "Live URL (through host reverse proxy): https://erp.hspdiamonds.com"
