# Repository Analysis: Building a Custom Frappe Docker Image

This document summarizes how this repository supports custom image creation, what paths are available, and which practical decisions to make for production use.

## 1) What the repository already provides

### Image build strategies

The repository contains three relevant image definitions:

- `images/custom/Containerfile`: fully self-contained build (installs system dependencies, Node via nvm, bench, and app sources).
- `images/layered/Containerfile`: custom app layering on top of prebuilt `frappe/build` and `frappe/base` images.
- `images/production/Containerfile`: default ERPNext-focused production image (without `APPS_JSON_BASE64` flow).

For custom app use-cases, `custom` and `layered` are the intended paths.

### Compose wiring for custom images

`compose.yaml` uses `${CUSTOM_IMAGE}:${CUSTOM_TAG}` and `${PULL_POLICY}` via `x-customizable-image`, so all runtime services can run from your own image tag without rewriting service definitions.

### Existing docs for end-to-end workflow

`docs/02-setup/02-build-setup.md` already documents:

1. Creating `apps.json`.
2. Encoding it as `APPS_JSON_BASE64`.
3. Building images with `FRAPPE_PATH`, `FRAPPE_BRANCH`, and `APPS_JSON_BASE64`.
4. Pointing compose to your image using `CUSTOM_IMAGE`, `CUSTOM_TAG`, and `PULL_POLICY=missing`.

## 2) Custom image flow in this repo (current architecture)

### Build-time app injection

Both `images/custom/Containerfile` and `images/layered/Containerfile` support an optional build arg:

- `APPS_JSON_BASE64`

If supplied, build steps decode it to `/opt/frappe/apps.json`, and `bench init --apps_path=/opt/frappe/apps.json` installs those apps at build time.

This is aligned with Docker immutability principles used by this project: apps should be baked into the image, not installed manually after container start.

### Runtime behavior

At runtime, `compose.yaml` starts these roles from the same custom image family:

- `backend`
- `frontend`
- `websocket`
- workers (`queue-short`, `queue-long`)
- `scheduler`
- `configurator`

This means one custom image controls application code consistency across all process types.

## 3) Choosing between `custom` and `layered`

### Use `images/layered/Containerfile` when

- You want faster builds.
- You are fine with Frappe-maintained base/build dependency versions.
- You mainly need to add apps, not deeply alter OS/runtime dependencies.

### Use `images/custom/Containerfile` when

- You need strong control over Python/Node/debian-level dependencies.
- You must pin or override low-level packages.
- You are willing to accept longer builds in exchange for tighter control.

## 4) Recommended production pattern

1. Keep app declarations in version-controlled `apps.json`.
2. Build image in CI with explicit args (`FRAPPE_BRANCH`, `FRAPPE_PATH`, `APPS_JSON_BASE64`).
3. Push image to your registry with immutable tags (e.g., git SHA + release tag).
4. Set deployment env:
   - `CUSTOM_IMAGE=<registry>/<image>`
   - `CUSTOM_TAG=<immutable-tag>`
   - `PULL_POLICY=always` for remote nodes, or `missing` for local-only usage.
5. Generate final compose file with required overrides.

## 5) Gaps and opportunities observed

- `docs/02-setup/02-build-setup.md` uses `images/layered/Containerfile` in examples, but does not explicitly include a decision matrix for when to prefer `images/custom/Containerfile`.
- `compose.yaml` comments link to an older `docs/container-setup/...` path naming convention; docs now live under `docs/02-setup/...`.
- There is no single reference page that consolidates architecture-level decision guidance for custom-image strategy; this file is intended to fill that gap.

## 6) Quick-start commands (repo-aligned)

```bash
# 1) optional custom app manifest
cat > apps.json <<'JSON'
[
  {"url": "https://github.com/frappe/erpnext", "branch": "version-16"},
  {"url": "https://github.com/frappe/hrms", "branch": "version-16"}
]
JSON

# 2) encode apps manifest
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

# 3) build (layered strategy)
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=my-registry/my-frappe:version-16-001 \
  --file=images/layered/Containerfile .

# 4) deploy through compose variable indirection
echo "CUSTOM_IMAGE=my-registry/my-frappe" >> custom.env
echo "CUSTOM_TAG=version-16-001" >> custom.env
echo "PULL_POLICY=always" >> custom.env
```

## 7) Bottom line

The repository is already well-structured for custom image workflows:

- build-time app inclusion,
- compose-level image indirection,
- and separate Dockerfiles for speed (`layered`) vs control (`custom`).

For most teams, start with `layered`; move to `custom` only when dependency-level customization is required.
