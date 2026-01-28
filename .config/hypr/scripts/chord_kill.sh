#!/bin/bash
# Use RAM for instant response
STATE_DIR="/dev/shm/hypr_mouse"
mkdir -p "$STATE_DIR"

BTN=$1
ACTION=$2

if [ "$ACTION" == "dn" ]; then
    touch "$STATE_DIR/$BTN"
    # Check if Middle (274) AND Back (275) are both held
    if [ -f "$STATE_DIR/274" ] && [ -f "$STATE_DIR/275" ]; then
        hyprctl dispatch killactive ""
        # Optional: remove files immediately so it doesn't double-trigger
        rm -f "$STATE_DIR/274" "$STATE_DIR/275"
    fi
else
    rm -f "$STATE_DIR/$BTN"
fi
