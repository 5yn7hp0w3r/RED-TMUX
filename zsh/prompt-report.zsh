# RED-TMUX :: промпт с датой и временем (опционально)
#
# Добавляет в приглашение строку [дата время]. Поскольку лог снимает экран,
# таймстамп попадает в файл рядом с каждой командой — удобно переносить в
# отчёт (видно, когда что выполнено).
#
# Подключение: в ~/.zshrc ПОСЛЕ дефолтного prompt-блока Kali:
#   source ~/RED-TMUX/zsh/prompt-report.zsh
#
# Переопределяет configure_prompt, сохраняя переключатель Ctrl-P
# (oneline/twoline). Дата — в двухстрочном режиме (twoline).

# RED-TMUX :: Оптимальный промпт без верхней закорючки
# Подключение: source ~/RED-TMUX/zsh/prompt-report.zsh

configure_prompt() {
    prompt_symbol=㉿
    # [ "$EUID" -eq 0 ] && prompt_symbol=💀   # для root
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT=$'%F{yellow}[%D{%Y-%m-%d %H:%M:%S}] %F{%(#.blue.green)}(%B%F{%(#.red.blue)}%n'$prompt_symbol$'%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]\n└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '
            ;;
        oneline)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{%(#.red.blue)}%n@%m%b%F{reset}:%B%F{%(#.blue.green)}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
        backtrack)
            PROMPT=$'${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%B%F{red}%n@%m%b%F{reset}:%B%F{blue}%~%b%F{reset}%(#.#.$) '
            RPROMPT=
            ;;
    esac
    unset prompt_symbol
}
: ${PROMPT_ALTERNATIVE:=twoline}
configure_prompt

