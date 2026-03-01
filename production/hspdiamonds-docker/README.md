# Production-hardened ERPNext v15 deployment (HSP Diamonds)

This bundle provides a bind-mount-only Docker Compose deployment for Ubuntu 24.04 hosts with:
- ERPNext/Frappe v15
- Apps: `erpnext`, `payments`, `india_compliance`, `hspdiamonds`
- Exposed ports: `8000` (web) and `9001` (socket.io)
- No Traefik

## 1) Directory setup

```bash
cd /workspace/frappe_docker/production/hspdiamonds-docker
./scripts/setup-directories.sh
cp -f config/* /home/erpnext/config/
```

Creates:
- `/home/erpnext/config`
- `/home/erpnext/sites`
- `/home/erpnext/apps`
- `/home/erpnext/logs`
- `/home/erpnext/mariadb`
- `/home/erpnext/redis-cache`
- `/home/erpnext/redis-queue`
- `/home/erpnext/redis-socketio`

And applies:

```bash
chown -R 1000:1000 /home/erpnext
```

## 2) Configuration files (`/home/erpnext/config`)

Included in `config/`:
- `mariadb.cnf` (`innodb_buffer_pool_size=4G`, `max_connections=200`)
- `redis-cache.conf` (`maxmemory 512mb`, LRU)
- `redis-queue.conf` (`maxmemory 256mb`, LRU)
- `logrotate.conf` (daily, `maxsize 10M`, `rotate 5`)

To enforce log rotation on host:

```bash
sudo cp /home/erpnext/config/logrotate.conf /etc/logrotate.d/erpnext
sudo logrotate -f /etc/logrotate.d/erpnext
```

## 3) Automated `common_site_config.json`

```bash
cp .env.example .env
nano .env
./scripts/generate-common-site-config.sh
```

Generated file: `/home/erpnext/sites/common_site_config.json` with:
- `db_host: "db"`
- `redis_cache: "redis://redis-cache:6379"`
- `redis_queue: "redis://redis-queue:6379"`
- `redis_socketio: "redis://redis-socketio:6379"`
- `socketio_port: 9001`

## 4) Docker Compose deployment

```bash
docker compose --env-file .env up -d
```

Services:
- `db`
- `redis-cache`
- `redis-queue`
- `redis-socketio`
- `backend`
- `websocket`
- `worker-short`
- `worker-long`
- `scheduler`

## 5) Deployment sequence (apps + site creation)

### Pull required apps

```bash
git clone --depth 1 --branch version-15 https://github.com/frappe/erpnext /home/erpnext/apps/erpnext
git clone --depth 1 --branch version-15 https://github.com/frappe/payments /home/erpnext/apps/payments
git clone --depth 1 --branch version-15 https://github.com/frappe/india-compliance /home/erpnext/apps/india_compliance
git clone --depth 1 --branch main git@github.com:your-org/hspdiamonds.git /home/erpnext/apps/hspdiamonds
```

### Create site with your credentials

```bash
docker compose --env-file .env run --rm backend \
  bench new-site erp.hspdiamonds.com \
  --db-name "$SITE_DB_NAME" \
  --mariadb-root-password "$MYSQL_ROOT_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD"
```

### Install all apps and disable developer mode

```bash
docker compose --env-file .env run --rm backend bench --site erp.hspdiamonds.com install-app erpnext
docker compose --env-file .env run --rm backend bench --site erp.hspdiamonds.com install-app payments
docker compose --env-file .env run --rm backend bench --site erp.hspdiamonds.com install-app india_compliance
docker compose --env-file .env run --rm backend bench --site erp.hspdiamonds.com install-app hspdiamonds
docker compose --env-file .env run --rm backend bench --site erp.hspdiamonds.com set-config developer_mode 0
```

## 6) Nginx host config for Cloudflare

Use this host-level Nginx server block:

```nginx
server {
    listen 80;
    server_name erp.hspdiamonds.com;

    client_max_body_size 50m;

    location /socket.io {
        proxy_pass http://127.0.0.1:9001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 120s;
    }
}
```
