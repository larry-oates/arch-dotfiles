#!/bin/bash
# Startup Menu - Navigate with arrow keys, press key shortcut, or Esc to skip
# Xbox guide button selects Steam in Big Picture Mode

OPTIONS=("Update (u)" "Steam (s)" "Browser (b)" "Terminal (t)")
COMMANDS=("$HOME/.config/ml4w/scripts/installupdates.sh" "steam" "firefox" "exit")
KEYS=("u" "s" "b" "t")
SELECTED=0
TOTAL=${#OPTIONS[@]}

# Start gamepad guide button monitor in background
GAMEPAD_PID=""
GAMEPAD_FLAG="/tmp/.gamepad_guide"
rm -f "$GAMEPAD_FLAG"
python3 "$HOME/.config/ml4w/scripts/gamepad-monitor.py" "$GAMEPAD_FLAG" &>/dev/null &
GAMEPAD_PID=$!

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
clear_line() { printf '\r\033[K'; }

cleanup() {
    show_cursor
    [ -n "$GAMEPAD_PID" ] && kill "$GAMEPAD_PID" 2>/dev/null
    rm -f "$GAMEPAD_FLAG"
}
trap 'cleanup; exit 0' INT TERM EXIT

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
    printf '\n  \033[90m↑↓ Navigate  ↵ Select  Esc Skip  🎮 Guide→Steam\033[0m\n'
}

hide_cursor

while true; do
    draw_menu

    # Check for gamepad guide button via flag file
    if [ -f "$GAMEPAD_FLAG" ]; then
        rm -f "$GAMEPAD_FLAG"
        show_cursor
        clear
        setsid steam steam://open/bigpicture &
        sleep 0.1
        kill -9 $PPID 2>/dev/null
        exit 0
    fi

    # Non-blocking check for keyboard input using timeout
    if read -rsn1 -t 0.1 key 2>/dev/null; then
        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') [ "$SELECTED" -gt 0 ] && SELECTED=$((SELECTED - 1)) ;;
                    '[B') [ "$SELECTED" -lt $((TOTAL - 1)) ] && SELECTED=$((SELECTED + 1)) ;;
                    '') cleanup; exit 0 ;;
                esac
                ;;
            '')
                show_cursor
                clear
                if [ "${COMMANDS[$SELECTED]}" = "exit" ]; then
                    exit 0
                elif [ "${COMMANDS[$SELECTED]}" = "$HOME/.config/ml4w/scripts/installupdates.sh" ]; then
                    exec ${COMMANDS[$SELECTED]}
                else
                    setsid ${COMMANDS[$SELECTED]} &
                    sleep 0.1
                    kill -9 $PPID 2>/dev/null
                    exit 0
                fi
                ;;
            u|s|b|t)
                for i in "${!KEYS[@]}"; do
                    if [ "$key" = "${KEYS[$i]}" ]; then
                        show_cursor
                        clear
                        if [ "${COMMANDS[$i]}" = "exit" ]; then
                            exit 0
                        elif [ "${COMMANDS[$i]}" = "$HOME/.config/ml4w/scripts/installupdates.sh" ]; then
                            exec ${COMMANDS[$i]}
                        else
                            setsid ${COMMANDS[$i]} &
                            sleep 0.1
                            kill -9 $PPID 2>/dev/null
                            exit 0
                        fi
                    fi
                done
                ;;
        esac
    fi
done