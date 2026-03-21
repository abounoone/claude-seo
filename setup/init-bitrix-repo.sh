#!/bin/bash
# =============================================================================
# init-bitrix-repo.sh
# Инициализирует git-репозиторий в существующем Bitrix-проекте.
# Запускать из корневой папки сайта: bash init-bitrix-repo.sh
# =============================================================================

set -e

WEBROOT="$(pwd)"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Bitrix Git Repository Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Директория: $WEBROOT"
echo ""

# Проверить что это Bitrix-проект
if [ ! -d "$WEBROOT/bitrix/modules/main" ]; then
    echo -e "${RED}ОШИБКА: Папка bitrix/modules/main не найдена.${NC}"
    echo "Запустите скрипт из корневой папки Bitrix-проекта."
    exit 1
fi

echo -e "${GREEN}✓ Bitrix-проект найден${NC}"

# 1. Определить версию Bitrix
BITRIX_VERSION=$(grep -o "'[0-9\.]*'" "$WEBROOT/bitrix/modules/main/install/version.php" 2>/dev/null | head -1 | tr -d "'")
echo -e "  Версия Bitrix: ${YELLOW}$BITRIX_VERSION${NC}"

# 2. Инициализировать git (если ещё нет)
if [ -d "$WEBROOT/.git" ]; then
    echo -e "${YELLOW}Git уже инициализирован в этой папке.${NC}"
else
    git init
    echo -e "${GREEN}✓ Git инициализирован${NC}"
fi

# 3. Создать .gitignore
echo ""
echo "Создаю .gitignore..."
cat > "$WEBROOT/.gitignore" << 'GITIGNORE'
# =============================================================================
# 1C-Bitrix .gitignore
# =============================================================================

# ---------- ЯДРО BITRIX (обновляется через admin panel, не через git) --------
/bitrix/

# ---------- ЗАГРУЖЕННЫЕ ФАЙЛЫ (большой объём, не код) -----------------------
/upload/

# ---------- СЕКРЕТЫ (НИКОГДА не коммитить) ----------------------------------
/local/php_interface/dbconn.php
/bitrix/.settings.php
/bitrix/.settings_extra.php
/local/.settings.php
/bitrix/license_key.php

# ---------- КЕШ BITRIX -------------------------------------------------------
/bitrix/cache/
/bitrix/managed_cache/
/bitrix/stack_cache/
/bitrix/html_pages/
/bitrix/modules/cluster/node_logs/

# ---------- ЛОГИ -------------------------------------------------------------
*.log
/logs/

# ---------- IDE-файлы --------------------------------------------------------
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db

# ---------- ЗАВИСИМОСТИ (если используется Composer) -----------------------
/vendor/

# ---------- ВРЕМЕННЫЕ ФАЙЛЫ --------------------------------------------------
*.bak
*.old
*.backup
*.tmp
/tmp/
GITIGNORE

echo -e "${GREEN}✓ .gitignore создан${NC}"

# 4. Создать local/ если не существует
if [ ! -d "$WEBROOT/local" ]; then
    mkdir -p "$WEBROOT/local/php_interface"
    mkdir -p "$WEBROOT/local/components"
    mkdir -p "$WEBROOT/local/templates"
    mkdir -p "$WEBROOT/local/modules"
    echo -e "${GREEN}✓ Папка local/ создана${NC}"

    # Создать пустой init.php
    cat > "$WEBROOT/local/php_interface/init.php" << 'INITPHP'
<?php
/**
 * Bitrix init.php — точка входа для кастомной логики.
 *
 * Используйте этот файл для:
 * - Регистрации обработчиков событий (EventManager)
 * - Подключения автозагрузчиков классов
 * - Глобальных констант (ID инфоблоков, настройки)
 *
 * ПРАВИЛО: Весь кастомный код — только в /local/, никогда в /bitrix/
 */

use Bitrix\Main\Loader;
use Bitrix\Main\EventManager;

// Автозагрузчик для классов в local/classes/
// spl_autoload_register(function($className) {
//     $classFile = __DIR__ . '/../classes/' . str_replace('\\', '/', $className) . '.php';
//     if (file_exists($classFile)) {
//         require_once $classFile;
//     }
// });

// Пример: обработчик события при сохранении заказа
// EventManager::getInstance()->addEventHandler(
//     'sale',
//     'OnSaleOrderSaved',
//     ['\YourVendor\YourModule\OrderHandler', 'onOrderSaved']
// );

// Константы инфоблоков (замените на реальные ID из /bitrix/admin/iblock_admin.php)
// define('IBLOCK_CATALOG_ID', 10);     // ID инфоблока товаров
// define('IBLOCK_OFFERS_ID', 11);      // ID инфоблока торговых предложений (SKU)
// define('IBLOCK_NEWS_ID', 5);         // ID инфоблока новостей
INITPHP
    echo -e "${GREEN}✓ local/php_interface/init.php создан${NC}"
else
    echo -e "${GREEN}✓ Папка local/ уже существует${NC}"
fi

# 5. Создать README.md
if [ ! -f "$WEBROOT/README.md" ]; then
    cat > "$WEBROOT/README.md" << 'README'
# Bitrix Project

Проект на 1C-Bitrix Site Management.

## Структура репозитория

```
local/                  ← весь кастомный код (только сюда!)
  components/           ← кастомные компоненты
  modules/              ← кастомные модули
  templates/            ← шаблоны сайта и переопределения компонентов
  php_interface/
    init.php            ← обработчики событий, автозагрузчики, константы
.gitignore
.htaccess
index.php
README.md
```

## Что НЕ хранится в git

- `bitrix/` — ядро Bitrix (обновляется через админ-панель)
- `upload/` — загруженные файлы пользователей
- `local/php_interface/dbconn.php` — данные подключения к БД

## Полезные команды

```bash
# Посмотреть изменения
git status
git diff

# Создать ветку для новой задачи
git checkout -b feature/название-задачи

# Закоммитить изменения
git add local/
git commit -m "feat: описание изменения"
```

## Очистка кеша Bitrix

```bash
rm -rf bitrix/cache/* bitrix/managed_cache/* bitrix/html_pages/*
```
README
    echo -e "${GREEN}✓ README.md создан${NC}"
fi

# 6. Добавить файлы и первый коммит
echo ""
echo "Добавляю файлы в индекс..."
git add .gitignore README.md

# Добавить local/ если там что-то есть
if find "$WEBROOT/local" -name "*.php" -not -name "dbconn.php" | grep -q .; then
    git add local/
    echo -e "${GREEN}✓ Файлы local/ добавлены${NC}"
fi

# Добавить .htaccess и index.php если существуют
[ -f "$WEBROOT/.htaccess" ] && git add .htaccess
[ -f "$WEBROOT/index.php" ] && git add index.php

echo ""
git status

# 7. Спросить про первый коммит
echo ""
read -p "Создать первый коммит? [y/N]: " ANSWER
if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    git commit -m "chore: initial Bitrix project setup

Bitrix version: $BITRIX_VERSION
- Add .gitignore (excludes bitrix/, upload/, secrets)
- Add local/ structure with init.php
- Add README.md"
    echo -e "${GREEN}✓ Первый коммит создан!${NC}"
fi

# 8. Спросить про remote
echo ""
echo -e "${YELLOW}Хотите добавить удалённый репозиторий (GitHub/GitLab)?${NC}"
read -p "Введите URL remote (или Enter чтобы пропустить): " REMOTE_URL
if [ -n "$REMOTE_URL" ]; then
    git remote add origin "$REMOTE_URL"
    echo -e "${GREEN}✓ Remote добавлен: $REMOTE_URL${NC}"
    echo ""
    read -p "Запушить в origin/main? [y/N]: " PUSH_ANSWER
    if [[ "$PUSH_ANSWER" =~ ^[Yy]$ ]]; then
        git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || \
            echo -e "${YELLOW}Не удалось запушить. Проверьте URL и попробуйте вручную: git push -u origin main${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Репозиторий готов!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Следующие шаги:"
echo "  1. Заполни IBLOCK_ID константы в local/php_interface/init.php"
echo "  2. Проверь .gitignore — убедись что dbconn.php не трекается"
echo "  3. Создай ветку для первой задачи: git checkout -b feature/my-task"
echo ""
