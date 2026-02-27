# Harika Solitaire Privé (HSP) Production Deployment

This repository can run as a single-server ERPNext v15 deployment with persistent bind mounts under `/home/erpnext`.

## 1) Create required directories

```bash
mkdir -p /home/erpnext/{sites,logs,assets,apps,mariadb,redis,docker,.ssh}
```

## 2) First run

Run from the repository root (typically `/home/erpnext/docker`):

```bash
docker compose up -d
```

## 3) Enter backend container

```bash
docker exec -it backend bash
```

## 4) Create site

```bash
bench new-site erp.hspdiamonds.com
```

## 5) Install ERPNext

```bash
bench --site erp.hspdiamonds.com install-app erpnext
```

## 6) Install India Compliance

```bash
bench --site erp.hspdiamonds.com install-app india_compliance
```

## 7) Install custom app

```bash
bench --site erp.hspdiamonds.com install-app hspdiamonds
```

## 8) Git-managed app updates (mutable custom app)

```bash
cd /home/erpnext/apps/hspdiamonds
git pull
docker restart backend
```

## Notes

- The stack is configured for host reverse proxy mode (`127.0.0.1:8080`) so traffic can flow via Cloudflare -> host NGINX -> Docker.
- SSH keys are mounted read-only from `/home/erpnext/.ssh` into `/home/frappe/.ssh`, allowing in-container git SSH usage.
- Persistent storage is bind-mounted under `/home/erpnext`, so `docker compose down` and `docker compose up` keep data intact.
