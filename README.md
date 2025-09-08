#!/bin/bash
# Arizona RP Linux Launcher – Supra Edition
# Автор: Shade_Furry
# Версия: V0.1 Beta

set -euo pipefail
shopt -s extglob lastpipe nullglob

# ------------------ Глобальные переменные ------------------
declare -gA LAUNCHER_STATE=(
    [TEST_MODE]="ON"
    [WINE_ARCH]="win64"
    [PROTON_VERSION]="GE-Proton8-25"
    [GAME_PID]="0"
    [OBSERVER_PID]="0"
)

declare -gr CONFIG_DIR="${HOME}/.config/supra_arizona"
declare -gr LOG_FILE="${CONFIG_DIR}/supra_ai.log"
declare -gr LOCK_FILE="${CONFIG_DIR}/.lock"
declare -gr FIFO_PIPE="${CONFIG_DIR}/control.fifo"
declare -gr SAMP_DIR="${CONFIG_DIR}/samp"
declare -gr WINE_PREFIX="${CONFIG_DIR}/wineprefix"

# ------------------ Функции ------------------
_init_colors() {
    declare -gA COLORS=(
        [RED]='\033[0;31m'
        [GREEN]='\033[0;32m'
        [YELLOW]='\033[1;33m'
        [BLUE]='\033[0;34m'
        [PURPLE]='\033[0;35m'
        [CYAN]='\033[0;36m'
        [WHITE]='\033[1;37m'
        [NC]='\033[0m'
    )
}

_log() {
    local level="$1" msg="$2"
    echo -e "${COLORS[WHITE]}[$(date '+%H:%M:%S')]${COLORS[NC]} ${COLORS[${level}]}${msg}${COLORS[NC]}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${level}: ${msg}" >> "$LOG_FILE"
}

_validate_dependencies() {
    local deps=("wget" "tar" "git" "xterm" "pgrep")
    local missing=()
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    [[ ${#missing[@]} -gt 0 ]] && { _log RED "Отсутствуют зависимости: ${missing[*]}"; exit 1; }
}

_init_environment() {
    mkdir -p "$CONFIG_DIR" "$SAMP_DIR" "$WINE_PREFIX"
    touch "$LOG_FILE" "$LOCK_FILE"
    [[ ! -p "$FIFO_PIPE" ]] && mkfifo "$FIFO_PIPE"
    chmod 700 "$CONFIG_DIR"
    chmod 600 "$LOG_FILE" "$LOCK_FILE" "$FIFO_PIPE"
}

_install_proton() {
    local proton_url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${LAUNCHER_STATE[PROTON_VERSION]}/${LAUNCHER_STATE[PROTON_VERSION]}.tar.gz"
    local proton_dir="${HOME}/.steam/root/compatibilitytools.d"
    [[ ! -d "${proton_dir}/${LAUNCHER_STATE[PROTON_VERSION]}" ]] || return
    _log YELLOW "Установка Proton..."
    mkdir -p "$proton_dir"
    wget -q --show-progress -O "/tmp/${LAUNCHER_STATE[PROTON_VERSION]}.tar.gz" "$proton_url"
    tar -xzf "/tmp/${LAUNCHER_STATE[PROTON_VERSION]}.tar.gz" -C "$proton_dir"
    _log GREEN "Proton установлен"
}

_install_samp() {
    local samp_exe="${SAMP_DIR}/samp_install.exe"
    [[ -f "${SAMP_DIR}/samp.exe" ]] && return
    _log YELLOW "Установка SAMP..."
    wget -q --show-progress -O "$samp_exe" "https://files.sa-mp.com/sa-mp-0.3.7-R5-1-install.exe"
    env WINEPREFIX="$WINE_PREFIX" WINEDEBUG=-all wine "$samp_exe" /S /D="C:\\samp" &
    wait $!
    cp -r "${WINE_PREFIX}/drive_c/samp/*" "$SAMP_DIR/"
    _log GREEN "SAMP установлен"
}

_launch_game() {
    local proton_path="${HOME}/.steam/root/compatibilitytools.d/${LAUNCHER_STATE[PROTON_VERSION]}/proton"
    (
        cd "$SAMP_DIR"
        export STEAM_COMPAT_DATA_PATH="$WINE_PREFIX"
        export STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.steam/root"
        export WINEDEBUG="-all"
        export WINEPREFIX="$WINE_PREFIX"
        "$proton_path" run ./samp.exe -n "Arizona RP" -h 185.231.153.115 -p 7777 -z &
        LAUNCHER_STATE[GAME_PID]=$!
        disown
    ) > /dev/null 2>&1
}

# ------------------ Главная ------------------
_main() {
    _init_colors
    _validate_dependencies
    _init_environment
    _install_proton
    _install_samp
    _launch_game
}

[[ $EUID -eq 0 ]] && { echo "Не запускайте от root!"; exit 1; }
[[ -f "$LOCK_FILE" ]] && { echo "Лаунчер уже запущен!"; exit 1; }

touch "$LOCK_FILE"
_main "$@"
