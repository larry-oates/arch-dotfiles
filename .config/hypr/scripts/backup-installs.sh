#!/bin/bash

# Files
CORE_NATIVE="core-pkgs.txt"
CORE_AUR="core-aur.txt"
PERS_NATIVE="personal-pkgs.txt"
PERS_AUR="personal-aur.txt"
WORK_NATIVE="private/work-pkgs.txt"
WORK_AUR="private/work-aur.txt"

echo "🔍 Scanning system for changes..."

# Temporary master lists
ALL_NATIVE=$(mktemp)
ALL_AUR=$(mktemp)
pacman -Qqen > "$ALL_NATIVE"
yay -Qqem > "$ALL_AUR"

# Function to refresh lists without losing their category
refresh_list() {
    local FILE="$1"
    local MASTER="$2"
    if [[ -f "$FILE" ]]; then
        grep -Fxf "$FILE" "$MASTER" > "${FILE}.tmp"
        mv "${FILE}.tmp" "$FILE"
    fi
}

# 1. Update existing containers
refresh_list "$CORE_NATIVE" "$ALL_NATIVE"
refresh_list "$PERS_NATIVE" "$ALL_NATIVE"
refresh_list "$WORK_NATIVE" "$ALL_NATIVE"
refresh_list "$CORE_AUR" "$ALL_AUR"
refresh_list "$PERS_AUR" "$ALL_AUR"
refresh_list "$WORK_AUR" "$ALL_AUR"

# 2. Detect NEW packages (anything not in any list)
# New Native -> Personal
NEW_NATIVE=$(comm -23 <(sort "$ALL_NATIVE") <(sort "$CORE_NATIVE" "$PERS_NATIVE" "$WORK_NATIVE" | sort -u))
if [[ -n "$NEW_NATIVE" ]]; then
    echo "➕ New native apps detected: $NEW_NATIVE"
    echo "$NEW_NATIVE" >> "$PERS_NATIVE"
fi

# New AUR -> Personal
NEW_AUR=$(comm -23 <(sort "$ALL_AUR") <(sort "$CORE_AUR" "$PERS_AUR" "$WORK_AUR" | sort -u))
if [[ -n "$NEW_AUR" ]]; then
    echo "✨ New AUR apps detected: $NEW_AUR"
    echo "$NEW_AUR" >> "$PERS_AUR"
fi

# 3. Final cleanup
sort -u -o "$CORE_NATIVE" "$CORE_NATIVE"
sort -u -o "$PERS_NATIVE" "$PERS_NATIVE"
sort -u -o "$CORE_AUR" "$CORE_AUR"
sort -u -o "$PERS_AUR" "$PERS_AUR"

# 4. Git Push
git add .
git commit -m "Auto-backup: $(date +%Y-%m-%d)"
git push
echo "✅ Remote repository updated!"
