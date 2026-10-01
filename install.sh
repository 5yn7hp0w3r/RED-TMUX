#!/usr/bin/env bash
# =====================================================================
# RED-TMUX :: установщик
# Тема и починенный лог ставятся всегда. Остальное спрашивается
# (Enter = дефолт в CAPS). Без симлинков: tmux.conf копируется, zsh-куски
# дописываются в конец ~/.zshrc между маркерами. Оригиналы бэкапятся.
# Запуск повторно безопасен — свой блок заменяется, а не плодится.
#
#   ./install.sh            интерактивно
#   ./install.sh -y         принять все дефолты, ничего не спрашивать
#   ./install.sh --no-conf  не трогать ~/.tmux.conf
# =====================================================================
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
MARK_A="# >>> RED-TMUX >>>"
MARK_B="# <<< RED-TMUX <<<"

DO_CONF=1; ASSUME_YES=0
for a in "$@"; do
    case "$a" in
        -y|--yes)  ASSUME_YES=1 ;;
        --no-conf) DO_CONF=0 ;;
    esac
done

say()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }
backup() { [ -e "$1" ] && cp -a "$1" "$1.bak.$TS" && warn "бэкап: $1.bak.$TS"; return 0; }

# ask "Вопрос?" DEFAULT(Y|N) -> 0 если да. Enter = дефолт. -y / не-tty = дефолт.
ask() {
    local q="$1" def="${2:-Y}" ans prompt
    [ "$def" = Y ] && prompt="(Y/n)" || prompt="(y/N)"
    if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then
        ans="$def"
    else
        read -rp "    $q $prompt " ans || ans="$def"
    fi
    ans="${ans:-$def}"
    case "$ans" in [YyДд]*) return 0 ;; *) return 1 ;; esac
}

# заменить/добавить ключ в ini-секции [General]
set_ini() {
    local file="$1" key="$2" val="$3"
    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$file"
    else
        sed -i "0,/^\[General\]/s//[General]\n${key}=${val}/" "$file"
    fi
}

# --- 1. ~/logs ---
mkdir -p "$HOME/logs"
say "каталог логов: ~/logs"

# --- 2. TPM ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    say "TPM склонирован (в tmux нажми prefix + I для установки плагинов)"
else
    say "TPM уже на месте"
fi

# --- 3. tmux.conf (копия, не симлинк) — тема gruvbox внутри ---
if [ "$DO_CONF" -eq 1 ]; then
    backup "$HOME/.tmux.conf"
    cp "$REPO/tmux.conf" "$HOME/.tmux.conf"
    say "~/.tmux.conf записан (бинды, мышь, gruvbox, автосейв)"
else
    warn "--no-conf: ~/.tmux.conf не тронут"
fi

# --- 4. ~/.zshrc: чистый лог (всегда) + промпт с датой и pentest (спрашиваем) ---
DO_PROMPT=0;  ask "Ставить промпт с датой/временем?" Y && DO_PROMPT=1
DO_PENTEST=0; ask "Ставить команду pentest (быстрый старт проекта)?" Y && DO_PENTEST=1

backup "$HOME/.zshrc"
if grep -qF "$MARK_A" "$HOME/.zshrc" 2>/dev/null; then
    sed -i "/^${MARK_A}$/,/^${MARK_B}$/d" "$HOME/.zshrc"
    say "старый RED-TMUX-блок в ~/.zshrc обновляется"
elif grep -q '_tmux_cleanlog' "$HOME/.zshrc" 2>/dev/null; then
    warn "в ~/.zshrc уже есть RED-TMUX без маркеров — zsh-часть пропускаю, чтобы не задвоить"
    DO_ZSH=0
fi
if [ "${DO_ZSH:-1}" -eq 1 ]; then
    {
        echo ""
        echo "$MARK_A"
        echo "# Чистый лог терминала (и промпт с датой). Проект RED-TMUX."
        echo ""
        cat "$REPO/zsh/red-tmux.zsh"
        if [ "$DO_PROMPT" -eq 1 ]; then
            echo ""
            cat "$REPO/zsh/prompt-report.zsh"
        fi
        if [ "$DO_PENTEST" -eq 1 ]; then
            echo ""
            cat "$REPO/zsh/pentest-session.zsh"
        fi
        echo "$MARK_B"
    } >> "$HOME/.zshrc"
    say "RED-TMUX дописан в ~/.zshrc (лог$([ "$DO_PROMPT" -eq 1 ] && echo " + промпт")$([ "$DO_PENTEST" -eq 1 ] && echo " + pentest"))"
fi

# --- 5. qterminal (опционально) ---
QT="$HOME/.config/qterminal.org/qterminal.ini"
if [ -f "$QT" ]; then
    qt_backed=0
    qt_backup() { [ "$qt_backed" -eq 0 ] && backup "$QT" && qt_backed=1; return 0; }

    if ask "Чинить перехват Alt+1..9 в qterminal?" Y; then
        qt_backup
        sed -i -E 's/^([^=]*)=Alt\+[1-9]$/\1=/' "$QT"
        say "qterminal: сняты бинды Alt+1..9 (ЗАКРОЙ qterminal полностью, иначе перезапишет)"
    fi
    if ask "Ставить шрифт qterminal (Fira Code Medium, 16)?" N; then
        qt_backup
        set_ini "$QT" fontFamily "Fira Code Medium"
        set_ini "$QT" fontSize 16
        say "qterminal: Fira Code Medium / 16 (нужен установленный шрифт Fira Code)"
    fi
else
    warn "qterminal.ini не найден — вопросы по qterminal пропущены"
fi

echo
say "Готово. Новый терминал -> tmux new -s work -> prefix + I (плагины)."
