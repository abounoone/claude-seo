# Setup Scripts

Скрипты для быстрой настройки локального окружения.

---

## Скрипт 1: Репозиторий для Bitrix-проекта

**`init-bitrix-repo.sh`** — инициализирует git в существующем Bitrix-проекте.

### Что делает:
- Проверяет что это Bitrix-проект (ищет `bitrix/modules/main`)
- Создаёт `.gitignore` (исключает `bitrix/`, `upload/`, секреты)
- Создаёт структуру `local/` если её нет
- Создаёт пустой `init.php` с примерами
- Делает первый коммит
- Подключает remote (GitHub/GitLab) по запросу

### Использование:

```bash
# Перейти в корневую папку вашего Bitrix-сайта
cd /path/to/your/bitrix/site

# Запустить
bash init-bitrix-repo.sh
```

---

## Скрипт 2: Установка claude-seo на ваш компьютер

**`install-claude-seo.sh`** — клонирует этот репозиторий и подключает навык к Claude Code.

### Требования:
- Claude Code установлен (`npm install -g @anthropic-ai/claude-code`)
- Git установлен

### Что делает:
- Клонирует репозиторий в `~/.claude/skills/claude-seo/`
- Переключается на ветку с Bitrix-навыком
- Регистрирует навык в `~/.claude/settings.json`
- Устанавливает Python-зависимости (если нужно)

### Использование:

```bash
# Скачать и запустить
curl -fsSL https://raw.githubusercontent.com/abounoone/claude-seo/main/setup/install-claude-seo.sh | bash

# Или клонировать и запустить локально
git clone https://github.com/abounoone/claude-seo.git
bash claude-seo/setup/install-claude-seo.sh
```

---

## Ручная установка (без скрипта)

### 1. Клонировать репозиторий

```bash
git clone https://github.com/abounoone/claude-seo.git ~/.claude/skills/claude-seo
cd ~/.claude/skills/claude-seo
git checkout claude/bitrix-onboarding-plan-Z7YFi
```

### 2. Зарегистрировать в Claude Code

Добавить в `~/.claude/settings.json`:
```json
{
  "plugins": [
    "~/.claude/skills/claude-seo"
  ]
}
```

### 3. Использовать

```bash
# Перейти в папку вашего Bitrix-проекта
cd /path/to/bitrix/project

# Запустить Claude Code
claude

# В чате:
/bitrix audit .
```

---

## Быстрый старт для Bitrix-проекта (всё вместе)

```bash
# Шаг 1: Установить claude-seo
bash install-claude-seo.sh

# Шаг 2: Инициализировать git в вашем Bitrix-проекте
cd /var/www/html   # или путь к вашему сайту
bash ~/init-bitrix-repo.sh   # или полный путь к скрипту

# Шаг 3: Открыть Claude Code в проекте
claude

# Шаг 4: Запустить аудит
/bitrix audit .
```
