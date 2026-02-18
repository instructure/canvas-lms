# Canvas LMS – Self-Hosted Docker Installation Guide

**Instance:** Gradex Classes (`lms.mygradex.com`)
**Host OS:** Debian/Ubuntu (tested on Debian 12)
**Stack:** Docker + Docker Compose, Nginx reverse proxy (host-level)

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone the Repository](#2-clone-the-repository)
3. [Configuration Files](#3-configuration-files)
4. [docker-compose.override.yml](#4-docker-composeoverrideyml)
5. [Build Docker Images](#5-build-docker-images)
6. [Initialize the Database](#6-initialize-the-database)
7. [Start All Services](#7-start-all-services)
8. [Host-Level Nginx Reverse Proxy](#8-host-level-nginx-reverse-proxy)
9. [SSL with Let's Encrypt](#9-ssl-with-lets-encrypt)
10. [Google OAuth Setup](#10-google-oauth-setup)
11. [Admin Account & Branding](#11-admin-account--branding)
12. [Ongoing Operations](#12-ongoing-operations)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Prerequisites

Install on the host machine:

```bash
# Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out and back in after this

# Docker Compose plugin (v2)
sudo apt install docker-compose-plugin

# Nginx + Certbot
sudo apt install nginx certbot python3-certbot-nginx

# Git
sudo apt install git
```

Verify:

```bash
docker --version          # Docker 24+
docker compose version    # Docker Compose v2+
nginx -v
```

---

## 2. Clone the Repository

Use your personal fork (which includes Gradex branding):

```bash
git clone git@github.com:pankajkumar3021/canvas-lms.git
cd canvas-lms
```

> The fork already contains:
> - Gradex login footer branding
>   (`app/views/login/canvas/_new_login_content.html.erb`)
> - Pre-configured `docker-compose.override.yml`
> - Pre-configured `config/domain.yml`

---

## 3. Configuration Files

These files are **already committed** in the repo and ready to use.
Review each one and update values for your environment.

### `config/domain.yml`

```yaml
production:
  domain: "lms.mygradex.com"
  ssl: true

development:
  domain: "lms.mygradex.com"
  ssl: true

test:
  domain: localhost
```

### `config/database.yml`

Uses environment variables — no edits needed.
Values are injected via `docker-compose.override.yml`.

### `config/redis.yml`

Points to the internal `redis` service — no edits needed.

### `config/security.yml`

```yaml
production: &default
  encryption_key: <%= ENV["ENCRYPTION_KEY"] %>
  jwt_encryption_keys:
    - <your-64-char-hex-key>
  lti_iss: 'https://lms.mygradex.com'

development:
  <<: *default

test:
  <<: *default
```

> **Generate a new encryption key** for a fresh install:
> ```bash
> openssl rand -hex 32
> ```

### `config/outgoing_mail.yml`

```yaml
production: &production
  address: mailcatcher   # replace with real SMTP for production
  port: 1025
  domain: canvas.docker
  outgoing_address: canvas@canvas.docker
  default_name: Instructure Canvas

development:
  <<: *production
```

> For production email, replace `mailcatcher` with your SMTP server
> (e.g., Gmail SMTP, SendGrid, AWS SES).

---

## 4. docker-compose.override.yml

This file customises the base `docker-compose.yml` for this host.
It is already committed in the repo:

```yaml
version: '2.3'
services:
  jobs: &BASE
    build:
      context: .
    volumes:
      - .:/usr/src/app
      - api_docs:/usr/src/app/public/doc/api
      - brandable_css_brands:/usr/src/app/app/stylesheets/brandable_css_brands
      - bundler:/home/docker/.bundle/
      - canvas-docker-gems:/home/docker/.gem/
      - node_modules:/usr/src/app/node_modules
      - public_dist:/usr/src/app/public/dist
      - log:/usr/src/app/log
      - tmp:/usr/src/app/tmp
      - translations:/usr/src/app/public/javascripts/translations
    environment: &BASE-ENV
      ENCRYPTION_KEY: <your-encryption-key>
      RAILS_ENV: development
      CANVAS_LMS_ADMIN_EMAIL: admin@mygradex.com
      CANVAS_LMS_ADMIN_PASSWORD: changeme123   # change this!
      CANVAS_LMS_ACCOUNT_NAME: MyGradeX LMS
      CANVAS_LMS_STATS_COLLECTION: opt_out

  web:
    <<: *BASE
    ports:
      - "3001:80"           # host port 3001 -> container port 80
    environment:
      <<: *BASE-ENV
      VIRTUAL_HOST: lms.mygradex.com
      HTTPS_METHOD: noredirect

  postgres:
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  api_docs: {}
  brandable_css_brands: {}
  bundler: {}
  canvas-docker-gems: {}
  node_modules: {}
  pg_data: {}
  public_dist: {}
  log: {}
  tmp: {}
  translations: {}
  yarn-cache: {}
```

> **Key points:**
> - Canvas web listens on host port **3001**
> - Nginx on the host proxies `lms.mygradex.com:443` -> `localhost:3001`
> - `RAILS_ENV: development` — Canvas runs in development mode
>   (functionally equivalent to production for self-hosting at small scale)

---

## 5. Build Docker Images

From the `canvas-lms` directory:

```bash
# Build all images (web, jobs, postgres, webpack)
docker compose build
```

This takes **15-30 minutes** the first time (downloads base images,
installs gems and npm packages).

Images created:

| Image | Size | Purpose |
|---|---|---|
| `canvas-lms-web` | ~1.4 GB | Rails app + Nginx (Passenger) |
| `canvas-lms-jobs` | ~1.4 GB | Delayed Job workers |
| `canvas-lms-webpack` | ~1.4 GB | Webpack asset compiler |
| `canvas-lms-postgres` | ~466 MB | PostgreSQL 14 + pgvector |

---

## 6. Initialize the Database

Run this **only on first install**. It creates the database,
runs all migrations, and seeds the admin account.

```bash
# Start only postgres and redis first
docker compose up -d postgres redis

# Wait ~10 seconds for postgres to be ready, then:
docker compose run --rm web bash -c \
  "bundle exec rake db:create db:initial_setup"
```

When prompted:
- **Admin email:** `admin@mygradex.com` (or set via env var)
- **Admin password:** your chosen password
- **Account name:** `MyGradeX LMS`
- **Stats collection:** enter `opt_out`

> If env vars are set in `docker-compose.override.yml`, the rake task
> uses them automatically without prompting.

---

## 7. Start All Services

```bash
docker compose up -d
```

Services started:

| Container | Role |
|---|---|
| `canvas-lms-web-1` | Rails app, port 3001 |
| `canvas-lms-jobs-1` | Background job worker |
| `canvas-lms-webpack-1` | Asset watcher/compiler |
| `canvas-lms-postgres-1` | Database |
| `canvas-lms-redis-1` | Cache + sessions |

Check all are running:

```bash
docker compose ps
docker compose logs -f web    # watch web logs
```

---

## 8. Host-Level Nginx Reverse Proxy

Canvas listens on `localhost:3001`. Nginx on the host proxies
HTTPS traffic to it.

Create `/etc/nginx/sites-available/canvas`:

```nginx
server {
    listen 80;
    server_name lms.mygradex.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name lms.mygradex.com;

    ssl_certificate     /etc/letsencrypt/live/lms.mygradex.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lms.mygradex.com/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 100M;

    location / {
        proxy_pass         http://localhost:3001;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
        proxy_read_timeout 120s;
    }
}
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/canvas \
           /etc/nginx/sites-enabled/canvas
sudo nginx -t
sudo systemctl reload nginx
```

---

## 9. SSL with Let's Encrypt

```bash
sudo certbot --nginx -d lms.mygradex.com
```

Certbot auto-configures Nginx with SSL. Auto-renewal is set up
automatically. Test renewal:

```bash
sudo certbot renew --dry-run
```

---

## 10. Google OAuth Setup

### 10a. Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a project (e.g., "Gradex Canvas")
3. Enable **Google People API**
4. Go to **Credentials -> Create Credentials -> OAuth 2.0 Client ID**
   - Application type: **Web application**
   - Authorised redirect URI:
     ```
     https://lms.mygradex.com/login/oauth2/callback
     ```
5. Copy **Client ID** and **Client Secret**

### 10b. Canvas Admin Configuration

1. Log in as admin at `https://lms.mygradex.com`
2. Go to **Admin -> Authentication**
3. Click **+ Google**
4. Enter Client ID and Client Secret
5. Save

### 10c. Allow Gmail Accounts (not just Google Workspace)

By default Canvas restricts Google login to Google Workspace
(corporate) accounts only. To allow regular `@gmail.com` accounts:

```bash
docker compose run --rm web rails console
```

```ruby
provider = Account.default.authentication_providers
                  .where(auth_type: "google").first
provider.update!(hosted_domain: nil)
exit
```

### 10d. Verify

- Open a private/incognito browser window
- Go to `https://lms.mygradex.com/login/canvas`
- Click "Login with Google"
- Sign in with any Google account

---

## 11. Admin Account & Branding

### Change Admin Password

After first login, go to:
**Account -> Settings -> Edit Profile -> Change Password**

Or via Rails console:

```bash
docker compose run --rm web rails console
```

```ruby
p = Pseudonym.find_by(unique_id: "admin@mygradex.com")
p.update!(password: "NewPassword123!",
          password_confirmation: "NewPassword123!")
```

### Custom Branding (Theme)

1. Go to **Admin -> Branding**
2. Upload logo, set primary colour, configure fonts
3. Click **Save & Apply**

> Branding is stored in the database and is not part of the git repo.
> Back it up with a database dump.

---

## 12. Ongoing Operations

### Start / Stop

```bash
docker compose up -d        # start all services
docker compose down         # stop (data persisted in volumes)
docker compose restart web  # restart just the web container
```

### View Logs

```bash
docker compose logs -f web      # web/Rails logs
docker compose logs -f jobs     # background job logs
docker compose logs -f webpack  # asset compilation logs
```

### Update Canvas (pull from your fork)

```bash
git pull personal master
docker compose build
docker compose run --rm web bundle exec rake db:migrate
docker compose up -d
```

### Rails Console

```bash
docker compose run --rm web rails console
```

### Shell Inside the Web Container

```bash
docker compose run --rm web bash
```

### Backup the Database

```bash
docker exec canvas-lms-postgres-1 \
  pg_dump -U postgres canvas_development \
  > canvas_backup_$(date +%Y%m%d).sql
```

### Restore the Database

```bash
cat canvas_backup_20250218.sql | \
  docker exec -i canvas-lms-postgres-1 \
  psql -U postgres canvas_development
```

---

## 13. Troubleshooting

### Container won't start

```bash
docker compose logs web
```

Common causes:
- Database not ready yet -> `docker compose restart web`
- Asset compilation not finished -> wait for webpack to complete

### Assets not loading (JS/CSS 404s)

Webpack may still be compiling on first boot. Check:

```bash
docker compose logs -f webpack
```

Wait until you see `webpack compiled successfully`.

### Google Login: "Google Apps user not received, but required"

The `hosted_domain` restriction is active. Fix:

```bash
docker compose run --rm web rails console
```

```ruby
Account.default.authentication_providers
       .where(auth_type: "google").first
       .update!(hosted_domain: nil)
```

### Google Login: redirect_uri_mismatch

The redirect URI in Google Cloud Console doesn't match.
It must be exactly:

```
https://lms.mygradex.com/login/oauth2/callback
```

### Permission denied on .git directory

Caused by Docker writing files as uid 9999:

```bash
sudo chown -R $USER:$USER /path/to/canvas-lms/.git
```

### Check disk space (images + volumes use ~5 GB+)

```bash
docker system df
docker volume ls
```

---

## Architecture Overview

```
Internet
    | HTTPS 443
    v
[Nginx on host]   lms.mygradex.com
    | HTTP proxy -> localhost:3001
    v
[canvas-lms-web]  Rails + Passenger + Nginx (inside container)
    |
    +---> [canvas-lms-postgres]  PostgreSQL 14  (pg_data volume)
    +---> [canvas-lms-redis]     Redis (sessions, cache, queues)
    +---> [canvas-lms-jobs]      Delayed::Job workers
    +---> [canvas-lms-webpack]   Webpack asset watcher/compiler
```
