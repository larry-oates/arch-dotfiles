#!/bin/bash

# Configuration - Adjust paths if necessary
DOTFILES_DIR="$HOME/dotfiles"
NATIVE_FILE="$DOTFILES_DIR/pkglist.txt"
AUR_FILE="$DOTFILES_DIR/aur-pkglist.txt"

echo "🚀 Starting Arch setup backup..."

# 1. Update Native Package List
# -n filters for official repos only
pacman -Qqen > "$NATIVE_FILE"
echo "✅ Native packages updated."

# 2. Update AUR Package List
# -m filters for foreign (AUR) packages
yay -Qqem > "$AUR_FILE"
echo "✅ AUR packages updated."

# 3. Optional: Verify lists aren't empty
if [[ ! -s "$NATIVE_FILE" ]]; then
    echo "❌ Error: Native package list is empty. Aborting backup."
    exit 1
fi

# 4. Git Automation
cd "$DOTFILES_DIR" || exit

# Check if there are actually changes to commit
if [[ -z $(git status --porcelain) ]]; then
    echo "arch-log: No changes detected in dotfiles or package lists."
else
    echo "📦 Changes detected. Syncing to GitHub..."
    git add .
    git commit -m "System Backup: $(date '+%Y-%m-%d %H:%M:%S')"
    git push
    echo "Done! Your portable setup is now live on GitHub."
fi
