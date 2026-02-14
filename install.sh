#!/bin/bash

# --- 1. Hardware Detection ---
echo "Detecting hardware..."
CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
GPU_TYPE=$(lspci | grep -E "VGA|3D" | grep -i nvidia)

case "$CPU_VENDOR" in
    AuthenticAMD) UCODE="amd-ucode" ;;
    GenuineIntel) UCODE="intel-ucode" ;;
esac

# --- 2. Install AUR Helper (yay) ---
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd -
fi

# --- 3. Install Meta-Package & Hardware Drivers ---
echo "Installing base system and $UCODE..."
# Install ucode first
sudo pacman -S --needed "$UCODE"

# Build your custom meta-package
if [ -f "./PKGBUILD" ]; then
    makepkg -si --noconfirm
fi

# --- 4. Install AUR Packages ---
# Using the list we generated earlier
if [ -f "./aur-pkglist.txt" ]; then
    echo "Installing AUR packages..."
    yay -S --needed - < aur-pkglist.txt
fi

# --- 5. Link Dotfiles with GNU Stow ---
echo "Linking configurations..."
stow .

echo "Setup complete! Please reboot for driver changes."
