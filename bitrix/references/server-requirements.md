# 1C-Bitrix: Требования к серверу и окружению

*Обновлено: 2026-03-21*

---

## Операционная система

| Параметр | Рекомендовано | Допустимо |
|----------|--------------|-----------|
| ОС | Ubuntu 22.04 LTS / Debian 12 | CentOS 8, AlmaLinux 9 |
| Arch | x86_64 | — |
| Windows | Только для разработки (Docker) | Не для production |

---

## Веб-сервер

### Nginx (рекомендован для production)

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/html;
    index index.php;

    charset utf-8;
    client_max_body_size 50M;

    # Bitrix: запрет прямого доступа к /bitrix/
    location ~* ^/bitrix/(?!pub/)(.*)$ {
        deny all;
    }

    # PHP обработка
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    # Статика — прямо, без PHP
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        access_log off;
    }

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}
```

### Apache (альтернатива)
- `mod_rewrite` должен быть включён
- `.htaccess` Bitrix уже настраивает rewrite rules
- Хуже по производительности, чем nginx+fpm

---

## PHP

### Версия

| Версия | Статус |
|--------|--------|
| PHP 8.1 | **Рекомендован** (лучший баланс совместимости и производительности) |
| PHP 8.2 | Поддерживается |
| PHP 8.0 | Поддерживается, но устаревает |
| PHP 7.4 | Устарел, уязвимости |
| PHP 8.3+ | Может быть несовместим с некоторыми модулями |

### Обязательные расширения

```
mbstring       ← работа с Unicode строками
gd             ← обработка изображений (ресайз)
curl           ← HTTP-запросы к внешним API
zip            ← установка обновлений Bitrix
pdo_mysql      ← подключение к MySQL через PDO
mysqli         ← подключение к MySQL (legacy)
json           ← встроен с PHP 8
openssl        ← HTTPS, шифрование
opcache        ← кеш байт-кода PHP (критично для производительности)
soap           ← SOAP веб-сервисы
intl           ← интернационализация
fileinfo       ← определение MIME-типов
```

### Рекомендуемые настройки php.ini

```ini
memory_limit = 256M          ; минимум 128M, рекомендовано 256M+
max_execution_time = 300     ; длинные операции (импорт 1С, обновления)
upload_max_filesize = 50M    ; загрузка файлов
post_max_size = 50M
max_input_vars = 10000       ; большие формы с SKU

; OPcache (критично для скорости)
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 10000
opcache.validate_timestamps = 1   ; в dev=1, в prod=0 для скорости

; Сессии
session.save_handler = redis  ; или memcached (для кластера)
session.save_path = "tcp://127.0.0.1:6379"
```

---

## База данных

### MySQL / MariaDB

| Параметр | Значение |
|---------|---------|
| Версия MySQL | 5.7.x или 8.0.x |
| Версия MariaDB | 10.4+ (рекомендован 10.6 LTS) |
| Кодировка | `utf8mb4` (НЕ `utf8`) |
| Collation | `utf8mb4_unicode_ci` |
| Движок | InnoDB |

### Настройки MySQL (`my.cnf`)

```ini
[mysqld]
innodb_buffer_pool_size = 512M    ; 50-70% RAM для чистого DB-сервера
innodb_log_file_size = 256M
max_connections = 300
query_cache_type = 0              ; в MySQL 8.0 удалён
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2               ; запросы медленнее 2с логируются
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

### Конфиг подключения Bitrix (`/local/php_interface/dbconn.php`)

```php
<?php
define('DBType', 'mysql');
define('DBHost', 'localhost');
define('DBLogin', 'bitrix_user');
define('DBPassword', 'secret_password');  // НЕ в git!
define('DBName', 'bitrix_db');
define('DBPersistent', false);
define('DELAY_DB_CONNECT', true);
```

**ВАЖНО:** `dbconn.php` должен быть в `.gitignore`. Хранить пароли в переменных окружения или Vault.

---

## Кеш: Redis (рекомендован)

```ini
# Redis для managed cache и сессий
redis-server >= 6.0
maxmemory 512mb
maxmemory-policy allkeys-lru
```

Настройка в Bitrix (`.settings.php`):
```php
'cache' => [
    'value' => [
        'type' => ['redis'],
        'redis' => [
            'host' => '127.0.0.1',
            'port' => 6379,
        ],
    ],
],
'session' => [
    'value' => [
        'mode' => 'default',
        'handlers' => ['value' => ['type' => 'redis', 'host' => '127.0.0.1', 'port' => '6379']],
    ],
],
```

---

## Требования к дискам и файловой системе

| Путь | Требования |
|------|-----------|
| `/` (корень) | Минимум 20GB SSD |
| `/upload/` | 50–200GB+ (зависит от каталога) |
| Права на `upload/` | `www-data:www-data 755` |
| Права на `bitrix/` | `www-data:www-data 644/755` |
| `/tmp/` | Не должен быть `noexec` |

---

## Окружение разработки (локально)

### Docker (рекомендован)

```yaml
# docker-compose.yml (упрощённый)
services:
  nginx:
    image: nginx:1.24
    volumes:
      - ./:/var/www/html
      - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf
    ports: ["80:80"]

  php:
    image: php:8.1-fpm
    volumes:
      - ./:/var/www/html
    environment:
      PHP_MEMORY_LIMIT: 256M

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: bitrix_db
      MYSQL_USER: bitrix
      MYSQL_PASSWORD: secret
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
```

### Готовые решения
- **Bitrix VM** — официальная виртуальная машина от Bitrix (VMware/VirtualBox)
- **Bitrix Docker** — неофициальные образы (например, `8bit/bitrix-docker`)
- **Docksal / Lando** — универсальные локальные среды с Bitrix-пресетами

---

## Лицензия Bitrix

- Одна лицензия = **2 домена**: один для production, один для dev/staging
- Лицензии привязаны к домену (не к IP)
- Проверка лицензии: `/bitrix/admin/bitrix_license.php`
- Ключ лицензии хранится в `/bitrix/license_key.php` (НЕ в git, или с осторожностью)
- Обновления доступны только при активной лицензии

---

## Checklist проверки сервера

```bash
# Версия PHP
php -v

# Модули PHP
php -m | grep -E "mbstring|gd|curl|zip|pdo_mysql|mysqli|opcache|soap|intl"

# Версия MySQL
mysql --version

# Версия Redis
redis-cli --version

# Свободное место
df -h /var/www

# Права на upload/
ls -la /var/www/html/upload/

# Открытые порты
ss -tlnp | grep -E "80|443|3306|6379"
```
