#!/bin/bash
# =============================================================================
# install-claude-seo.sh
# Устанавливает навык claude-seo (с Bitrix-поддержкой) в Claude Code локально.
# Запускать на вашем компьютере (не на сервере).
# =============================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="claude-seo"
SKILL_DIR="$CLAUDE_SKILLS_DIR/$SKILL_NAME"

# Определить ОС
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  claude-seo + Bitrix Skill Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "ОС: ${YELLOW}$OS${NC}"
echo -e "Папка навыков: ${YELLOW}$CLAUDE_SKILLS_DIR${NC}"
echo ""

# 1. Проверить установку Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${RED}ОШИБКА: claude не найден в PATH.${NC}"
    echo ""
    echo "Установите Claude Code:"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "После установки перезапустите этот скрипт."
    exit 1
fi

CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ Claude Code найден: $CLAUDE_VERSION${NC}"

# 2. Проверить git
if ! command -v git &> /dev/null; then
    echo -e "${RED}ОШИБКА: git не найден.${NC}"
    echo "Установите git: https://git-scm.com/downloads"
    exit 1
fi
echo -e "${GREEN}✓ Git найден: $(git --version)${NC}"

# 3. Создать папку навыков
mkdir -p "$CLAUDE_SKILLS_DIR"
echo -e "${GREEN}✓ Папка $CLAUDE_SKILLS_DIR готова${NC}"

# 4. Клонировать или обновить репозиторий
echo ""
if [ -d "$SKILL_DIR" ]; then
    echo "Репозиторий уже существует. Обновляю..."
    cd "$SKILL_DIR"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
        echo -e "${YELLOW}Не удалось обновить автоматически. Обновите вручную:${NC}"
        echo "  cd $SKILL_DIR && git pull"
    }
    echo -e "${GREEN}✓ Обновлено${NC}"
else
    echo "Клонирую репозиторий..."
    # Используем публичный GitHub-репозиторий
    REPO_URL="https://github.com/abounoone/claude-seo.git"

    if git clone "$REPO_URL" "$SKILL_DIR" 2>/dev/null; then
        echo -e "${GREEN}✓ Репозиторий клонирован${NC}"
    else
        echo -e "${YELLOW}Не удалось клонировать с GitHub. Пробую альтернативный URL...${NC}"
        REPO_URL="https://github.com/AgriciDaniel/claude-seo.git"
        if git clone "$REPO_URL" "$SKILL_DIR" 2>/dev/null; then
            echo -e "${GREEN}✓ Репозиторий клонирован (альтернативный URL)${NC}"
        else
            echo -e "${RED}Не удалось клонировать репозиторий.${NC}"
            echo ""
            echo "Скачайте вручную и распакуйте в: $SKILL_DIR"
            echo "Или укажите путь к уже скачанной папке:"
            read -p "Путь к папке claude-seo (или Enter для пропуска): " MANUAL_PATH
            if [ -n "$MANUAL_PATH" ] && [ -d "$MANUAL_PATH" ]; then
                cp -r "$MANUAL_PATH" "$SKILL_DIR"
                echo -e "${GREEN}✓ Скопировано из $MANUAL_PATH${NC}"
            else
                echo -e "${RED}Установка прервана.${NC}"
                exit 1
            fi
        fi
    fi
fi

# 5. Переключиться на ветку с Bitrix-навыком
cd "$SKILL_DIR"
git fetch origin 2>/dev/null || true

if git show-ref --verify --quiet refs/remotes/origin/claude/bitrix-onboarding-plan-Z7YFi; then
    git checkout -b claude/bitrix-onboarding-plan-Z7YFi \
        origin/claude/bitrix-onboarding-plan-Z7YFi 2>/dev/null || \
    git checkout claude/bitrix-onboarding-plan-Z7YFi 2>/dev/null || true
    echo -e "${GREEN}✓ Ветка с Bitrix-навыком активна${NC}"
elif git show-ref --verify --quiet refs/remotes/origin/main; then
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
fi

# 6. Настроить Claude Code — добавить навык в конфиг
CLAUDE_CONFIG="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

if [ ! -f "$CLAUDE_CONFIG" ]; then
    cat > "$CLAUDE_CONFIG" << CLAUDECONFIG
{
  "plugins": [
    "$SKILL_DIR"
  ]
}
CLAUDECONFIG
    echo -e "${GREEN}✓ Конфиг Claude Code создан: $CLAUDE_CONFIG${NC}"
else
    # Проверить что путь уже есть
    if grep -q "$SKILL_DIR" "$CLAUDE_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓ Навык уже зарегистрирован в конфиге${NC}"
    else
        echo -e "${YELLOW}Добавьте вручную в $CLAUDE_CONFIG:${NC}"
        echo "  \"plugins\": [\"$SKILL_DIR\"]"
    fi
fi

# 7. Установить Python зависимости (для скриптов SEO)
echo ""
echo "Проверяю Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "${GREEN}✓ $PYTHON_VERSION${NC}"

    if [ -f "$SKILL_DIR/requirements.txt" ]; then
        echo "Создаю виртуальное окружение..."
        python3 -m venv "$HOME/.claude/skills/seo/.venv" 2>/dev/null || true
        source "$HOME/.claude/skills/seo/.venv/bin/activate" 2>/dev/null || true
        pip install -r "$SKILL_DIR/requirements.txt" --quiet 2>/dev/null || true
        echo -e "${GREEN}✓ Python-зависимости установлены${NC}"
    fi
else
    echo -e "${YELLOW}Python3 не найден — некоторые SEO-скрипты не будут работать.${NC}"
fi

# 8. Итог
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Установка завершена!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Расположение навыка: $SKILL_DIR"
echo ""
echo -e "${YELLOW}Доступные команды в Claude Code:${NC}"
echo ""
echo "  Bitrix:"
echo "    /bitrix audit /path/to/project  ← полный аудит проекта"
echo "    /bitrix onboard                 ← пошаговый онбординг"
echo "    /bitrix explain <тема>          ← объяснение концепций"
echo "    /bitrix setup                   ← настройка окружения"
echo "    /bitrix security /path          ← аудит безопасности"
echo "    /bitrix ecommerce /path         ← анализ магазина"
echo ""
echo "  SEO:"
echo "    /seo audit <url>                ← SEO-аудит сайта"
echo "    /seo technical <url>            ← технический SEO"
echo ""
echo -e "${YELLOW}Как использовать:${NC}"
echo "  1. Откройте Claude Code в папке вашего проекта:"
echo "     cd /path/to/your/project && claude"
echo "  2. Введите: /bitrix audit ."
echo ""
