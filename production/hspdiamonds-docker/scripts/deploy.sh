#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

start_ts=$(date +%s)

mkdir -p apps sites mariadb assets logs redis-queue redis-cache backups

if [[ ! -f .env ]]; then
  if [[ -f .env.example ]]; then
    cp .env.example .env
  else
    echo ".env not found and .env.example missing"
    exit 1
  fi
fi

set -a
# shellcheck disable=SC1091
source .env
set +a


# Use SSH for upstream app repos to avoid HTTPS credential prompts on hardened servers.
ERPNEXT_REPO="${ERPNEXT_REPO:-git@github.com:frappe/erpnext.git}"
INDIA_COMPLIANCE_REPO="${INDIA_COMPLIANCE_REPO:-git@github.com:frappe/india-compliance.git}"

if [[ ! -d apps/erpnext ]]; then
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch version-15 "${ERPNEXT_REPO}" apps/erpnext
fi
if [[ ! -d apps/india-compliance ]]; then
  GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch version-15 "${INDIA_COMPLIANCE_REPO}" apps/india-compliance
fi

if [[ -n "${CUSTOM_APP_REPO:-}" ]]; then
  custom_name="${CUSTOM_APP_NAME:-$(basename "${CUSTOM_APP_REPO}" .git)}"
  custom_branch="${CUSTOM_APP_BRANCH:-version-15}"

  if [[ ! -d "apps/${custom_name}/.git" ]]; then
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "${custom_branch}" "${CUSTOM_APP_REPO}" "apps/${custom_name}"
  else
    GIT_TERMINAL_PROMPT=0 git -C "apps/${custom_name}" fetch --depth 1 origin "${custom_branch}"
    git -C "apps/${custom_name}" checkout "${custom_branch}"
    git -C "apps/${custom_name}" pull --ff-only origin "${custom_branch}"
  fi
fi

if [[ -f apps.json ]]; then
  APPS_JSON_BASE64="$(base64 -w 0 apps.json)"
  if grep -q '^APPS_JSON_BASE64=' .env; then
    sed -i "s|^APPS_JSON_BASE64=.*|APPS_JSON_BASE64=${APPS_JSON_BASE64}|" .env
  else
    echo "APPS_JSON_BASE64=${APPS_JSON_BASE64}" >> .env
  fi
fi

# Pull+build fast path for warm cache
docker compose --env-file .env pull || true
docker compose --env-file .env up -d --build --remove-orphans

# Keep custom apps mutable: apply schema patches/code migrations after git updates
docker compose --env-file .env exec -T backend bench --site "${SITE_NAME}" migrate

if [[ -n "${CUSTOM_APP_REPO:-}" ]]; then
  custom_name="${CUSTOM_APP_NAME:-$(basename "${CUSTOM_APP_REPO}" .git)}"
  docker compose --env-file .env exec -T backend bench --site "${SITE_NAME}" install-app "${custom_name}" || true
fi

end_ts=$(date +%s)
echo "Deploy complete in $((end_ts - start_ts))s"
echo "Bench console: docker compose --env-file .env exec backend bench console"
