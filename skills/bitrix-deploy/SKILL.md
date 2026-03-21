---
name: bitrix-deploy
description: >
  1C-Bitrix deployment guide. Covers dev→staging→production workflow, git-based deploy,
  Bitrix core update process, zero-downtime deploy strategies, and rollback procedures.
  Trigger on: bitrix deploy, деплой битрикс, обновление сайта битрикс, выкатить изменения.
user-invokable: true
argument-hint: ""
allowed-tools:
  - Read
  - Bash
---

# Bitrix Deployment Guide

Complete deployment workflow for 1C-Bitrix Site Management projects.

## Environment Architecture

```
Developer Machine (local)
        │ git push feature/xxx
        ▼
Git Repository (GitHub/GitLab/Gitea)
        │ merge to develop
        ▼
Staging Server (dev.example.com)   ← тестирование
        │ merge to main + tag
        ▼
Production Server (example.com)    ← live
```

## What Goes into Git vs What Doesn't

### In Git ✅
```
local/                    — весь кастомный код
.htaccess                 — конфиг веб-сервера
index.php                 — точка входа
composer.json             — зависимости (если есть)
deploy.sh                 — скрипт деплоя
docker-compose.yml        — локальная среда
.gitignore
README.md
```

### NOT in Git ❌
```
bitrix/                   — обновляется через admin panel, не git
upload/                   — пользовательские файлы (большой объём)
local/php_interface/dbconn.php    — пароль БД
bitrix/.settings.php      — настройки включая пароли
bitrix/cache/             — кеш
bitrix/html_pages/        — HTML кеш
*.log                     — логи
bitrix/license_key.php    — ключ лицензии (опционально)
```

## Deploy Process

### Option 1: Simple git pull (малые команды)

```bash
#!/bin/bash
# deploy.sh — базовый деплой

set -e  # остановить при ошибке

WEBROOT="/var/www/html"
BRANCH="${1:-main}"

echo "[$(date)] Starting deploy of branch: $BRANCH"

# 1. Pull latest code
cd "$WEBROOT"
git pull origin "$BRANCH"

# 2. Clear Bitrix cache
echo "Clearing cache..."
rm -rf bitrix/cache/*
rm -rf bitrix/managed_cache/*
rm -rf bitrix/html_pages/*

# 3. Fix permissions (if needed)
chown -R www-data:www-data local/
chmod -R 755 local/

echo "[$(date)] Deploy complete!"
```

Usage:
```bash
ssh user@server "cd /var/www/html && bash deploy.sh main"
```

### Option 2: Rsync deploy (точечная синхронизация)

```bash
#!/bin/bash
# rsync-deploy.sh

SERVER="user@example.com"
REMOTE_PATH="/var/www/html"

# Sync only local/ directory (custom code)
rsync -avz --delete \
  --exclude=".git/" \
  --exclude="*.log" \
  ./local/ "$SERVER:$REMOTE_PATH/local/"

# Sync root files
rsync -avz \
  .htaccess \
  index.php \
  "$SERVER:$REMOTE_PATH/"

# Clear cache on server
ssh "$SERVER" "rm -rf $REMOTE_PATH/bitrix/cache/* $REMOTE_PATH/bitrix/html_pages/*"

echo "Deploy complete!"
```

### Option 3: GitHub Actions CI/CD (для команд)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy via SSH
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/html
            git pull origin main
            rm -rf bitrix/cache/* bitrix/managed_cache/* bitrix/html_pages/*
            echo "Deploy complete: $(date)"
```

Секреты хранятся в GitHub → Settings → Secrets.

## Bitrix Core Update Process

**ВАЖНО:** Обновление ядра Bitrix делается через admin panel, НЕ через git.

```
/bitrix/admin/update_system_partner.php
```

Шаги:
1. Сделать полный бэкап: файлы + БД
2. Проверить STAGING: сначала обновить dev-сервер
3. Если staging работает → обновить production
4. Проверить сайт после обновления (главная, каталог, корзина, заказ)

Откат обновления Bitrix практически невозможен — только из бэкапа.

## Zero-Downtime Deploy

Для высоконагруженных магазинов:

### Deployer PHP (atomic deploy)

```bash
composer require deployer/deployer --dev
```

```php
// deploy.php
require 'recipe/common.php';

set('repository', 'git@github.com:your/repo.git');
set('branch', 'main');

host('production')
    ->setHostname('example.com')
    ->setDeployPath('/var/www/html');

// Bitrix-specific: shared files not in git
set('shared_files', [
    'local/php_interface/dbconn.php',
    'bitrix/.settings.php',
]);

set('shared_dirs', [
    'upload',
    'bitrix/cache',
    'bitrix/managed_cache',
    'bitrix/html_pages',
]);

// Clear Bitrix cache after deploy
after('deploy:symlink', function () {
    run('rm -rf {{release_path}}/bitrix/cache/*');
    run('rm -rf {{release_path}}/bitrix/html_pages/*');
});

after('deploy', 'deploy:cleanup');
```

```bash
dep deploy production
dep rollback production  # откат на предыдущий релиз
```

## Database Migrations

Bitrix не имеет встроенной системы миграций. Варианты:

### 1. SQL files в git

```
deploy/
  migrations/
    2026-01-15_add_custom_table.sql
    2026-02-01_add_iblock_property.sql
```

Применять вручную или через deploy script.

### 2. Bitrix updater pattern

Использовать `$updater` классы в модулях:
```php
// local/modules/vendor.module/install/index.php
class vendor_module extends CModule {
    function DoInstall() {
        global $DB;
        $DB->RunSQLBatch(dirname(__FILE__).'/db/mysql/install.sql');
    }
}
```

## Rollback Procedure

### Code rollback (git)

```bash
# Откат на предыдущий коммит
git -C /var/www/html log --oneline -5  # посмотреть историю
git -C /var/www/html reset --hard HEAD~1  # откат на 1 коммит назад
```

### DB rollback

Только из бэкапа. Поэтому:
- **Делать бэкап ПЕРЕД каждым деплоем** с изменениями схемы БД
- Хранить бэкапы минимум 7 дней

```bash
# Бэкап перед деплоем
mysqldump -u bitrix -p bitrix_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление
mysql -u bitrix -p bitrix_db < backup_20260101_120000.sql
```

## Deploy Checklist

Перед деплоем:
- [ ] Код протестирован на staging
- [ ] Бэкап БД сделан
- [ ] Бэкап файлов сделан (или git tag)
- [ ] Уведомить команду о деплое
- [ ] Выбрать время деплоя (минимум трафика)

После деплоя:
- [ ] Открыть главную страницу
- [ ] Открыть каталог, страницу товара
- [ ] Проверить корзину
- [ ] Проверить оформление заказа
- [ ] Проверить admin panel
- [ ] Проверить лог ошибок: `tail -f /var/log/nginx/error.log`
