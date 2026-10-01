# ─────────────────────────────────────────────────────────────────────
# RED-TMUX :: ЧИСТЫЙ ЛОГ ТЕРМИНАЛА
# Снимаем ОТРИСОВАННЫЙ экран (буфер прокрутки) на каждый prompt и при
# выходе. Пишется ровно то, что видно: без цвета, без ANSI, без мусора
# автоподсказок/подсветки/таб-перебора. Никакой пост-обработки.
#
# Подключение: добавь в ~/.zshrc строкой
#   source ~/RED-TMUX/zsh/red-tmux.zsh
# (install.sh делает это сам)
#
# Логи: ~/logs/<сессия>/<окно>.<панель>-<дата_время>.log
# Папку можно переопределить переменной RED_TMUX_LOGDIR до source.
# ─────────────────────────────────────────────────────────────────────

: ${RED_TMUX_LOGDIR:=$HOME/logs}

if [[ -n "$TMUX" ]]; then
    # Файл НЕ создаём на старте шелла: иначе транзитные панели (которые
    # continuum поднимает при restore) плодят пустые огрызки. Пишем только
    # после ПЕРВОЙ реальной команды — preexec взводит флаг.
    _tmux_cleanlog_armed=0
    # путь к логу — СТРОГО локальная переменная шелла, НЕ экспортируем:
    # иначе tmux-сервер протаскивает её в окружение всех панелей и новая
    # сессия писала бы в папку старой. Имя уникальное — наследоваться нечему.
    typeset -g _tmux_cleanlog_file=
    _tmux_cleanlog_arm() { _tmux_cleanlog_armed=1 }
    _tmux_cleanlog() {
        [[ $_tmux_cleanlog_armed == 1 ]] || return   # не было команд — не логируем
        # снимок во временный файл. Если сервер умирает (kill-server/ребут),
        # capture-pane падает или отдаёт пусто — тогда НЕ трогаем готовый лог,
        # иначе пустой снимок затирал бы его в ноль.
        local _raw="$RED_TMUX_LOGDIR/.cleanlog.$$.raw"
        mkdir -p "$RED_TMUX_LOGDIR"
        if ! tmux capture-pane -t "$TMUX_PANE" -pJS - >| "$_raw" 2>/dev/null || [[ ! -s "$_raw" ]]; then
            rm -f "$_raw"; return
        fi
        if [[ -z "$_tmux_cleanlog_file" ]]; then
            # имя считаем лениво, по ФАКТИЧЕСКОЙ сессии этой панели
            local _s=$(tmux display-message -t "$TMUX_PANE" -p '#{session_name}')
            local _wp=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}.#{pane_index}')
            _s=${_s//\//_}   # на случай слэша в имени сессии
            _tmux_cleanlog_file=$RED_TMUX_LOGDIR/$_s/${_wp}-$(date +%Y%m%d_%H%M%S).log
            mkdir -p "${_tmux_cleanlog_file%/*}"
        fi
        sed -e 's/[[:space:]]\+$//' "$_raw" | cat -s >| "${_tmux_cleanlog_file}.part" \
            && mv -f "${_tmux_cleanlog_file}.part" "$_tmux_cleanlog_file"
        rm -f "$_raw"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec _tmux_cleanlog_arm   # команда вот-вот выполнится
    add-zsh-hook precmd  _tmux_cleanlog       # после команды — снимок экрана
    add-zsh-hook zshexit _tmux_cleanlog       # финальный снимок при выходе
fi
