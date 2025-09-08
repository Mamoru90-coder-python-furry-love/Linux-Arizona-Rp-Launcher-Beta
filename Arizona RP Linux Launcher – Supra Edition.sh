#!/bin/bash

# =============================================================================
# Arizona RP Linux Launcher – Supra Edition
# Версия: v0.2 Pre Release
# Автор: Shade_Furry
# GitHub: https://github.com/Mamoru90-coder-python-furry-love/Linux-Arizona-Rp-Launcher-Beta
# =============================================================================

set -euo pipefail
shopt -s extglob lastpipe nullglob
IFS=$'\n\t'

# Глобальные константы
declare -gr SCRIPT_NAME="Arizona RP Linux Launcher"
declare -gr SCRIPT_VERSION="Supra Edition v0.2 Pre Release"
declare -gr CONFIG_DIR="${HOME}/.config/arizona_launcher"
declare -gr LOG_FILE="${CONFIG_DIR}/launcher.log"
declare -gr LOCK_FILE="${CONFIG_DIR}/.lock"
declare -gr FIFO_PIPE="${CONFIG_DIR}/control.fifo"
declare -gr WINE_PREFIX="${CONFIG_DIR}/wine_prefix"
declare -gr PROTON_DIR="${CONFIG_DIR}/proton_ge"

# Список серверов
declare -grA SERVER_LIST=(
    ["Prescott"]="185.231.153.115:7777"
    ["Tucson"]="185.231.153.116:7777" 
    ["Phoenix"]="185.231.153.117:7777"
    ["Flagstaff"]="185.231.153.118:7777"
)

# Цветовое оформление
declare -gr RED='\033[0;31m'
declare -gr GREEN='\033[0;32m'
declare -gr YELLOW='\033[1;33m'
declare -gr BLUE='\033[0;34m'
declare -gr PURPLE='\033[0;35m'
declare -gr CYAN='\033[0;36m'
declare -gr WHITE='\033[1;37m'
declare -gr NC='\033[0m'

# Глобальные переменные состояния
declare -gA LAUNCHER_STATE=(
    ["TESTING"]="ON"
    ["CURRENT_SERVER"]="Prescott"
    ["GAME_PID"]="0"
    ["OBSERVER_PID"]="0"
    ["PROTON_VER"]="GE-Proton8-25"
)

# =============================================================================
# БАЗОВЫЕ ФУНКЦИИ
# =============================================================================

_log() {
    local level="$1" message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
    
    if [[ "${LAUNCHER_STATE[TESTING]}" == "ON" ]]; then
        case "${level}" in
            "ERROR") echo -e "${RED}[ERROR]${NC} ${message}" >&2 ;;
            "WARN") echo -e "${YELLOW}[WARN]${NC} ${message}" >&2 ;;
            "INFO") echo -e "${BLUE}[INFO]${NC} ${message}" >&2 ;;
            "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${message}" >&2 ;;
            *) echo -e "${WHITE}[DEBUG]${NC} ${message}" >&2 ;;
        esac
    fi
}

_die() {
    _log "ERROR" "Критическая ошибка: $1"
    echo -e "${RED}✗ $1${NC}" >&2
    _cleanup
    exit 1
}

_cleanup() {
    rm -rf "${LOCK_FILE}" "${FIFO_PIPE}" 2>/dev/null || true
    kill -TERM "${LAUNCHER_STATE[OBSERVER_PID]}" 2>/dev/null || true
    kill -TERM "${LAUNCHER_STATE[GAME_PID]}" 2>/dev/null || true
}

_init_dirs() {
    mkdir -p "${CONFIG_DIR}" "${WINE_PREFIX}" "${PROTON_DIR}"
    touch "${LOG_FILE}"
}

_check_dependencies() {
    local deps=("wget" "curl" "wine" "zenity")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            missing+=("${dep}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        _die "Отсутствуют зависимости: ${missing[*]}"
    fi
}

# =============================================================================
# СИСТЕМА УПРАВЛЕНИЯ ЧЕРЕЗ FIFO
# =============================================================================

_start_observer() {
    mkfifo "${FIFO_PIPE}" 2>/dev/null || true
    
    while true; do
        if read -r -t 1 cmd < "${FIFO_PIPE}"; then
            case "${cmd}" in
                "/off") LAUNCHER_STATE[TESTING]="OFF" ;;
                "/on") LAUNCHER_STATE[TESTING]="ON" ;;
                "/info") _show_system_info ;;
                "/restart") _restart_game ;;
                "/update") _update_launcher ;;
                *) _log "WARN" "Неизвестная команда: ${cmd}" ;;
            esac
        fi
        sleep 0.1
    done &
    
    LAUNCHER_STATE[OBSERVER_PID]=$!
}

_show_system_info() {
    _log "INFO" "===== СИСТЕМНАЯ ИНФОРМАЦИЯ ====="
    _log "INFO" "Версия лаунчера: ${SCRIPT_VERSION}"
    _log "INFO" "Текущий сервер: ${LAUNCHER_STATE[CURRENT_SERVER]}"
    _log "INFO" "Тестовый режим: ${LAUNCHER_STATE[TESTING]}"
    _log "INFO" "PID игры: ${LAUNCHER_STATE[GAME_PID]}"
    _log "INFO" "Версия Proton: ${LAUNCHER_STATE[PROTON_VER]}"
}

# =============================================================================
# УПРАВЛЕНИЕ WINE/PROTON
# =============================================================================

_install_proton_ge() {
    local proton_url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${LAUNCHER_STATE[PROTON_VER]}/${LAUNCHER_STATE[PROTON_VER]}.tar.gz"
    
    _log "INFO" "Загрузка Proton GE..."
    wget -q --show-progress -O "/tmp/proton.tar.gz" "${proton_url}"
    
    _log "INFO" "Распаковка Proton GE..."
    tar -xzf "/tmp/proton.tar.gz" -C "${PROTON_DIR}"
}

_setup_wine_prefix() {
    export WINEPREFIX="${WINE_PREFIX}"
    export WINEARCH="win64"
    
    if [[ ! -d "${WINE_PREFIX}/drive_c" ]]; then
        _log "INFO" "Инициализация Wine префикса..."
        wineboot -i 2>/dev/null
    fi
}

# =============================================================================
# УСТАНОВКА ИГРЫ
# =============================================================================

_install_samp() {
    local samp_url="https://files.sa-mp.com/sa-mp-0.3.7-R5-1-install.exe"
    local samp_exe="${CONFIG_DIR}/samp_install.exe"

    _log "INFO" "Загрузка SAMP..."
    wget -q --show-progress -O "${samp_exe}" "${samp_url}"
    
    _log "INFO" "Установка SAMP..."
    wine "${samp_exe}" /S /D="C:\\samp" &
    wait $!
    
    cp -r "${WINE_PREFIX}/drive_c/samp" "${CONFIG_DIR}/"
}

# =============================================================================
# ЗАПУСК ИГРЫ
# =============================================================================

_launch_game() {
    local server_info="${SERVER_LIST[${LAUNCHER_STATE[CURRENT_SERVER]}]}"
    local server_ip="${server_info%:*}"
    local server_port="${server_info#*:}"
    
    export WINEPREFIX="${WINE_PREFIX}"
    
    _log "INFO" "Запуск игры на сервере ${LAUNCHER_STATE[CURRENT_SERVER]}..."
    
    (
        cd "${CONFIG_DIR}/samp"
        wine "${CONFIG_DIR}/samp/samp.exe" \
            -n "${USER}" \
            -h "${server_ip}" \
            -p "${server_port}" \
            -z &
        LAUNCHER_STATE[GAME_PID]=$!
    )
}

_restart_game() {
    kill -TERM "${LAUNCHER_STATE[GAME_PID]}" 2>/dev/null || true
    sleep 2
    _launch_game
}

# =============================================================================
# ГРАФИЧЕСКИЙ ИНТЕРФЕЙС
# =============================================================================

_show_gui() {
    local choice=$(zenity --list \
        --title="${SCRIPT_NAME} ${SCRIPT_VERSION}" \
        --text="Добро пожаловать в Arizona RP" \
        --column="Действие" \
        --width=400 --height=300 \
        "Запустить игру" \
        "Выбрать сервер" \
        "Настройки" \
        "Информация о системе" \
        "Выход")
    
    case "${choice}" in
        "Запустить игру") _launch_game ;;
        "Выбрать сервер") _select_server ;;
        "Настройки") _show_settings ;;
        "Информация о системе") _show_system_info ;;
        "Выход") exit 0 ;;
    esac
}

_select_server() {
    local server_names=$(printf "%s\n" "${!SERVER_LIST[@]}")
    local current_server="${LAUNCHER_STATE[CURRENT_SERVER]}"
    
    local new_server=$(zenity --list \
        --title="Выбор сервера" \
        --text="Текущий сервер: ${current_server}" \
        --column="Сервер" ${server_names} \
        --width=300 --height=250)
    
    if [[ -n "${new_server}" ]]; then
        LAUNCHER_STATE[CURRENT_SERVER]="${new_server}"
        _log "INFO" "Выбран сервер: ${new_server}"
    fi
    
    _show_gui
}

_show_settings() {
    zenity --info --title="Настройки" --text="Настройки лаунчера" --width=200
    _show_gui
}

# =============================================================================
# ОБНОВЛЕНИЕ ЛАУНЧЕРА
# =============================================================================

_update_launcher() {
    _log "INFO" "Проверка обновлений..."
    zenity --info --title="Обновление" --text="Функция обновления будет реализована в будущих версиях" --width=250
}

# =============================================================================
# ОСНОВНАЯ ФУНКЦИЯ
# =============================================================================

_main() {
    trap '_cleanup; exit' INT TERM EXIT
    
    if [[ -f "${LOCK_FILE}" ]]; then
        _die "Лаунчер уже запущен!"
    fi
    touch "${LOCK_FILE}"
    
    _init_dirs
    _check_dependencies
    
    echo -e "${PURPLE}${SCRIPT_NAME} ${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}Административная версия с расширенным управлением${NC}"
    echo -e "${YELLOW}Для управления используйте FIFO команды: /on, /off, /info, /restart, /update${NC}"
    echo "========================================"
    
    _start_observer
    
    if [[ ! -d "${PROTON_DIR}/${LAUNCHER_STATE[PROTON_VER]}" ]]; then
        _install_proton_ge
    fi
    
    if [[ ! -d "${WINE_PREFIX}/drive_c" ]]; then
        _setup_wine_prefix
    fi
    
    if [[ ! -d "${CONFIG_DIR}/samp" ]]; then
        _install_samp
    fi
    
    _show_gui
    
    wait ${LAUNCHER_STATE[GAME_PID]}
}

# =============================================================================
# ТОЧКА ВХОДА
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _main
fi
