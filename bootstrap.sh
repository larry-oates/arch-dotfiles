#!/bin/bash

# Usage: ./bootstrap.sh [personal|work|core]
MODE=${1:-personal}
REPO_ROOT=$(pwd)
PRIVATE_DIR="$REPO_ROOT/private"

echo "🚀 Bootstrapping Arch Linux in [$MODE] mode..."

# 1. Install AUR Helper
if ! command -v yay &> /dev/null; then
    echo "📦 Installing yay..."
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd "$REPO_ROOT"
fi

# 2. Hardware Detection
CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
[[ "$CPU_VENDOR" == "AuthenticAMD" ]] && UCODE="amd-ucode" || UCODE="intel-ucode"
sudo pacman -S --needed "$UCODE"

# 3. Helper function for installs
install_list() {
    local NATIVE="$1"
    local AUR="$2"
    [[ -f "$NATIVE" ]] && sudo pacman -S --needed - < "$NATIVE"
    [[ -f "$AUR" ]] && yay -S --needed - < "$AUR"
}

# 4. Execution Flow
echo "--- Installing Core (Pro) Profile ---"
install_list "core-pkgs.txt" "core-aur.txt"

case $MODE in
    personal)
        echo "--- Adding Personal Profile (Games/Media) ---"
        install_list "personal-pkgs.txt" "personal-aur.txt"
        ;;
    work)
        echo "--- Adding Work Profile (Private Tools) ---"
        install_list "$PRIVATE_DIR/work-pkgs.txt" "$PRIVATE_DIR/work-aur.txt"
        ;;
    core)
        echo "🛡️ Core only. No extra profiles applied."
        ;;
esac

# 5. Config Link
echo "🔗 Symlinking dotfiles..."
stow .
echo "✅ Done!"
