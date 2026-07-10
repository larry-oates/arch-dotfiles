#!/bin/bash
# Startup Menu - Navigate with arrow keys, press key shortcut, or Esc to skip

OPTIONS=("Update (u)" "Steam (s)" "Browser (b)" "Terminal (t)")
COMMANDS=("$HOME/.config/ml4w/scripts/installupdates.sh" "steam" "firefox" "exit")
BACKGROUND=(false false true false)
KEYS=("u" "s" "b" "t")
SELECTED=0
TOTAL=${#OPTIONS[@]}

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
clear_line() { printf '\r\033[K'; }

draw_menu() {
    printf '\033[2J\033[H'
    printf '\n  \033[1;36m═══ Startup Menu ═══\033[0m\n\n'
    for i in "${!OPTIONS[@]}"; do
        if [ "$i" -eq "$SELECTED" ]; then
            printf '  \033[1;32m► %s\033[0m\n' "${OPTIONS[$i]}"
        else
            printf '    %s\n' "${OPTIONS[$i]}"
        fi
    done
    printf '\n  \033[90m↑↓ Navigate  ↵ Select  Esc Skip\033[0m\n'
}

hide_cursor
trap 'show_cursor; exit 0' INT TERM

while true; do
    draw_menu
    read -rsn1 key

    case "$key" in
        $'\x1b')
            read -rsn2 key
            case "$key" in
                '[A') [ "$SELECTED" -gt 0 ] && SELECTED=$((SELECTED - 1)) ;;
                '[B') [ "$SELECTED" -lt $((TOTAL - 1)) ] && SELECTED=$((SELECTED + 1)) ;;
                '') show_cursor; exit 0 ;;
            esac
            ;;
        '') 
            show_cursor
            clear
            if [ "${COMMANDS[$SELECTED]}" != "exit" ]; then
                if [ "${BACKGROUND[$SELECTED]}" = true ]; then
                    setsid ${COMMANDS[$SELECTED]} &>/dev/null &
                else
                    ${COMMANDS[$SELECTED]}
                fi
            fi
            exit 0
            ;;
        u|s|b|t)
            for i in "${!KEYS[@]}"; do
                if [ "$key" = "${KEYS[$i]}" ]; then
                    show_cursor
                    clear
                    if [ "${COMMANDS[$i]}" != "exit" ]; then
                        if [ "${BACKGROUND[$i]}" = true ]; then
                            setsid ${COMMANDS[$i]} &>/dev/null &
                        else
                            ${COMMANDS[$i]}
                        fi
                    fi
                    exit 0
                fi
            done
            ;;
    esac
done