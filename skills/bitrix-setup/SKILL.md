---
name: bitrix-setup
description: >
  1C-Bitrix development environment setup guide. Covers local dev environment (Docker),
  git workflow, license management, dev/staging/production environments, and team onboarding.
  Trigger on: bitrix setup, настройка окружения битрикс, локальная разработка битрикс.
user-invokable: true
argument-hint: ""
allowed-tools:
  - Read
  - Bash
  - WebFetch
---

# Bitrix Development Environment Setup

Guides the user through setting up a complete development workflow for 1C-Bitrix Site Management.

## Step 1: Understand Current State

Ask or determine:
- Does a local dev environment already exist?
- Is there a staging server?
- What's the current deploy process (manual FTP, git pull, CI/CD)?
- Is there a `.gitignore` already?

## Step 2: Git Repository Setup

If no git exists, initialize:
```bash
cd /path/to/project
git init
```

### Required .gitignore for Bitrix

```gitignore
# Bitrix core (updated separately via admin panel, not git)
/bitrix/

# User uploads (large files, not source code)
/upload/

# Database credentials (NEVER in git)
/local/php_interface/dbconn.php
/.settings.php
/bitrix/.settings.php
/bitrix/.settings_extra.php

# Bitrix cache
/bitrix/cache/
/bitrix/managed_cache/
/bitrix/stack_cache/
/bitrix/html_pages/

# Logs
*.log
/bitrix/modules/cluster/node_logs/

# IDE files
.idea/
.vscode/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Composer (if used)
/vendor/

# License key (optional — some teams track, some don't)
# /bitrix/license_key.php
```

### What SHOULD be in git

```
local/                          ← all custom code
  components/                   ← custom components
  modules/                      ← custom modules
  templates/                    ← site templates
  php_interface/
    init.php                    ← event handlers (NO dbconn.php!)
    include/
      sale_payment/             ← custom payment handlers
      sale_delivery/            ← custom delivery handlers
.htaccess                       ← web server config
index.php                       ← entry point (usually unchanged)
composer.json                   ← if using Composer
```

## Step 3: Local Development Environment

### Option A: Docker (Recommended)

Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:1.24-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/var/www/html:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php

  php:
    image: php:8.1-fpm-alpine
    volumes:
      - ./:/var/www/html
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/custom.ini
    environment:
      - PHP_MEMORY_LIMIT=256M

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: bitrix
      MYSQL_USER: bitrix
      MYSQL_PASSWORD: bitrix
    volumes:
      - mysql_data:/var/lib/mysql
      - ./docker/mysql/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  mysql_data:
```

### Option B: Bitrix Virtual Machine

Download official Bitrix VM: https://www.1c-bitrix.ru/download/vmbitrix.php
- VMware or VirtualBox image with pre-configured LAMP stack
- Easiest setup, official support
- Less flexible than Docker

### Option C: native LAMP (Windows/Mac)

Not recommended for team work — inconsistent environments.

## Step 4: Database Setup for Local

```bash
# Dump production database
mysqldump -u user -p bitrix_db > backup_$(date +%Y%m%d).sql

# Import to local
mysql -u bitrix -p bitrix < backup_20260101.sql

# Replace production URLs with local in DB
mysql -u bitrix -p bitrix -e "
UPDATE b_option SET VALUE = 'http://localhost' WHERE NAME = 'server_name';
UPDATE b_lang SET SERVER_NAME = 'localhost' WHERE LID = 's1';
"
```

Create local `dbconn.php` (do NOT commit!):
```php
<?php
define('DBType', 'mysql');
define('DBHost', 'mysql');       // Docker service name
define('DBLogin', 'bitrix');
define('DBPassword', 'bitrix');
define('DBName', 'bitrix');
define('DBPersistent', false);
define('DELAY_DB_CONNECT', true);
```

## Step 5: Bitrix License for Dev Domain

Bitrix license covers 2 domains: production + one more (dev).

Options:
1. **Use `localhost`** — Bitrix usually allows localhost without license validation
2. **Use `.loc` domain** — add `127.0.0.1 myproject.loc` to `/etc/hosts`, then register dev domain in Bitrix cabinet
3. **Dev license** — purchase separate development license if needed

Check current domains: `/bitrix/admin/bitrix_license.php`

## Step 6: Git Workflow

### Recommended branching strategy

```
main (production)
  ↑ merge via PR only
develop (staging/testing)
  ↑ merge via PR
feature/TASK-123-feature-name   ← new features
bugfix/TASK-456-fix-order       ← bug fixes
hotfix/critical-fix             ← urgent production fixes (from main)
```

### Commit message convention

```
feat: add CDEK delivery integration
fix: correct price calculation with discounts
refactor: migrate catalog component to D7 API
docs: add deployment guide
chore: update .gitignore
```

## Step 7: Deploy Process

### Simple: git pull on server

```bash
# On server
cd /var/www/html
git pull origin main
# Optionally: clear Bitrix cache
php -r "define('STOP_STATISTICS', true); require('/var/www/html/bitrix/modules/main/include/prolog_before.php'); \CBitrixComponent::clearComponentCache();"
```

### Better: deploy script

```bash
#!/bin/bash
# deploy.sh
set -e

REMOTE="origin"
BRANCH="main"
WEBROOT="/var/www/html"

echo "Pulling latest changes..."
cd $WEBROOT && git pull $REMOTE $BRANCH

echo "Clearing Bitrix cache..."
rm -rf $WEBROOT/bitrix/cache/*
rm -rf $WEBROOT/bitrix/managed_cache/*
rm -rf $WEBROOT/bitrix/html_pages/*

echo "Deploy complete!"
```

### Production-grade: Deployer PHP

```bash
composer require deployer/deployer --dev
```

Deployer handles: atomic deploys, zero-downtime, rollback in one command.

## Error Handling

| Issue | Solution |
|-------|---------|
| Bitrix license error on dev | Use localhost or register dev domain in cabinet |
| DB connection failed locally | Check dbconn.php credentials match docker-compose |
| Upload/ too large to copy | Use `--exclude=upload/` in rsync, restore separately |
| Git shows bitrix/ changes | Ensure .gitignore is correct and bitrix/ is not tracked |
| PHP version mismatch | Check production PHP version, match in Docker |
