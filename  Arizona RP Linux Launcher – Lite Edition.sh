#!/bin/bash

# =============================================================================
# Arizona RP Linux Launcher – Lite Edition
# Версия: v0.2 Pre Release
# Автор: Shade_Furry
# GitHub: https://github.com/Mamoru90-coder-python-furry-love/Linux-Arizona-Rp-Launcher-Beta
# =============================================================================

set -euo pipefail

# Конфигурация
CONFIG_DIR="${HOME}/.arizona_launcher_light"
LOG_FILE="${CONFIG_DIR}/launcher.log"
WINE_PREFIX="${CONFIG_DIR}/wine_prefix"

# Список серверов
declare -A SERVER_LIST=(
    ["Prescott"]="185.231.153.115:7777"
    ["Tucson"]="185.231.153.116:7777" 
    ["Phoenix"]="185.231.153.117:7777"
    ["Flagstaff"]="185.231.153.118:7777"
)

# Цветовое оформление
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции логирования
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $1" >> "$LOG_FILE"
    exit 1
}

# Проверка зависимостей
check_dependencies() {
    local deps=("wget" "wine" "zenity")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            error "Отсутствует зависимость: $dep"
        fi
    done
}

# Инициализация окружения
init_environment() {
    mkdir -p "$CONFIG_DIR" "$WINE_PREFIX"
    touch "$LOG_FILE"
    
    export WINEPREFIX="$WINE_PREFIX"
    export WINEARCH="win64"
}

# Установка SAMP
install_samp() {
    local samp_url="https://files.sa-mp.com/sa-mp-0.3.7-R5-1-install.exe"
    local samp_exe="$CONFIG_DIR/samp_install.exe"

    log "Загрузка SAMP..."
    wget -q --show-progress -O "$samp_exe" "$samp_url"
    
    log "Установка SAMP..."
    wine "$samp_exe" /S /D="C:\\samp" &
    wait $!
    
    cp -r "$WINE_PREFIX/drive_c/samp" "$CONFIG_DIR/"
}

# Запуск игры
launch_game() {
    local server_info="${SERVER_LIST[$1]}"
    local server_ip="${server_info%:*}"
    local server_port="${server_info#*:}"
    
    log "Запуск игры на сервере $1..."
    cd "$CONFIG_DIR/samp"
    
    wine "$CONFIG_DIR/samp/samp.exe" \
        -n "$USER" \
        -h "$server_ip" \
        -p "$server_port" \
        -z
}

# Графический интерфейс
show_gui() {
    local choice=$(zenity --list \
        --title="Arizona RP Linux Launcher – Lite Edition" \
        --text="Добро пожаловать в Arizona RP" \
        --column="Действие" \
        --width=400 --height=300 \
        "Играть на Prescott" \
        "Играть на Tucson" \
        "Играть на Phoenix" \
        "Играть на Flagstaff" \
        "Выход")
    
    case "${choice}" in
        "Играть на Prescott") launch_game "Prescott" ;;
        "Играть на Tucson") launch_game "Tucson" ;;
        "Играть на Phoenix") launch_game "Phoenix" ;;
        "Играть на Flagstaff") launch_game "Flagstaff" ;;
        "Выхот") exit 0 ;;
    esac
}

# Основная функция
main() {
    echo -e "${GREEN}Arizona RP Linux Launcher – Lite Edition v0.2 Pre Release${NC}"
    echo -e "${YELLOW}Автор: Shade_Furry${NC}"
    echo "========================================"
    
    check_dependencies
    init_environment
    
    if [[ ! -d "$CONFIG_DIR/samp" ]]; then
        install_samp
    fi
    
    show_gui
}

# Точка входа
main "$@"
