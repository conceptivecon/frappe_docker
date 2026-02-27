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
INDIA_COMPLIANCE_REPO="${INDIA_COMPLIANCE_REPO:-git@github.com:resilient-tech/india-compliance.git}"

clone_repo() {
  local repo_url="$1"
  local branch="$2"
  local target_dir="$3"

  if GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "${branch}" "${repo_url}" "${target_dir}"; then
    return 0
  fi

  if [[ "${repo_url}" =~ ^git@github.com:(.+)\.git$ ]]; then
    local https_url="https://github.com/${BASH_REMATCH[1]}.git"
    echo "Primary clone failed, retrying via HTTPS: ${https_url}"
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "${branch}" "${https_url}" "${target_dir}"
    return 0
  fi

  return 1
}

if [[ ! -d apps/erpnext ]]; then
  clone_repo "${ERPNEXT_REPO}" "version-15" "apps/erpnext"
fi
if [[ ! -d apps/india-compliance ]]; then
  clone_repo "${INDIA_COMPLIANCE_REPO}" "version-15" "apps/india-compliance"
fi

if [[ -n "${CUSTOM_APP_REPO:-}" ]]; then
  custom_name="${CUSTOM_APP_NAME:-$(basename "${CUSTOM_APP_REPO}" .git)}"
  custom_branch="${CUSTOM_APP_BRANCH:-version-15}"

  if [[ ! -d "apps/${custom_name}/.git" ]]; then
    clone_repo "${CUSTOM_APP_REPO}" "${custom_branch}" "apps/${custom_name}"
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
