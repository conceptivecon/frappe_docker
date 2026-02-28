# HSP Diamonds ERPNext v15 Production Deployment

## Prepare persistent directories

```bash
mkdir -p /home/erpnext/{sites,logs,apps,assets,mariadb,redis}
mkdir -p /home/erpnext/.ssh
```

## Start stack

```bash
cd /home/erpnext/docker/production/hspdiamonds-docker

docker compose up -d
```

## Enter backend container

```bash
docker exec -it backend bash
```

## Create site

```bash
bench new-site erp.hspdiamonds.com
```

## Install apps

```bash
bench --site erp.hspdiamonds.com install-app erpnext

bench --site erp.hspdiamonds.com install-app india_compliance

bench --site erp.hspdiamonds.com install-app india_payments

bench --site erp.hspdiamonds.com install-app hspdiamonds
```
