# Maintainer: Your Name <your@email.com>
pkgname=my-arch-setup
pkgver=2026.02.14
pkgrel=1
pkgdesc="Unified meta-package for my portable Arch Linux environment"
arch=('any')
url="https://github.com/yourusername/dotfiles"
license=('MIT')

_system_drivers=(
    'amd-ucode' 'linux-firmware' 'linux-firmware-nvidia' 'linux-headers'
    'nvidia-open' 'nvidia-settings' 'mesa-utils' 'xf86-video-nouveau' 
    'xf86-video-vesa' 'openrazer-daemon' 'openrgb' 'ddcutil' 'smartmontools'
)

_desktop_env=(
    'hyprland' 'waybar' 'wofi' 'swaync' 'swww' 'dunst' 'rofi' 
    'nwg-look' 'nwg-dock-hyprland' 'qt5-wayland' 'qt6-wayland' 'qt6ct'
    'xdg-desktop-portal-hyprland' 'xdg-desktop-portal-gtk' 'xdg-utils'
    'archlinux-xdg-menu' 'ly' 'brightnessctl' 'hyprsunset'
)

_term_tools=(
    'kitty' 'ghostty' 'fish' 'zsh' 'zsh-completions' 'starship' 'tmux' 
    'neovim' 'nano' 'vim' 'git' 'github-cli' 'lazygit' 'stow' 'fastfetch' 
    'btop' 'eza' 'lsd' 'bat' 'fd' 'fzf' 'jq' 'zoxide' 'thefuck' 'yazi' 
    'wget' 'reptyr' 'man-db' 'man-pages'
)

_dev_environment=(
    'base-devel' 'cmake' 'ninja' 'cargo-cache' 'rustup' 'pnpm' 'deno' 
    'python-pip' 'python-gobject' 'python-pywal' 'uv' 'docker' 'qmk'
)

_apps=(
    'firefox' 'discord' 'obsidian' 'spotify-launcher' 'libreoffice-fresh' 
    'gimp' 'inkscape' 'kdenlive' 'krita' 'reaper' 'obs-studio' 'steam' 
    'rpi-imager' 'foliate' 'nicotine+' 'qbittorrent' 'filelight' 'dolphin'
)

_utilities=(
    'blueman' 'network-manager-applet' 'nm-connection-editor' 'iwd' 
    'openvpn' 'cloudflared' 'pavucontrol' 'pipewire' 'pipewire-alsa' 
    'pipewire-jack' 'pipewire-pulse' 'wireplumber' 'qjackctl' 'timeshift' 
    'gparted' 'gnome-disk-utility' 'gnome-calculator' 'gnome-text-editor' 
    'loupe' 'flameshot' 'grim' 'slurp' 'imv' 'mpv' '7zip' 'dosfstools' 
    'zram-generator' 'power-profiles-daemon'
)

_fonts_theme=(
    'ttf-firacode-nerd' 'ttf-fira-code' 'ttf-fira-sans' 'ttf-dejavu' 
    'noto-fonts-cjk' 'noto-fonts-emoji' 'noto-fonts-extra' 'otf-font-awesome' 
    'papirus-icon-theme' 'breeze'
)

# Xorg Legacy & Compatibility (as requested in your list)
_xorg_compat=(
    'xorg-server' 'xorg-xinit' 'xorg-xinput' 'xorg-xkill' 'xorg-xhost' 
    'xorg-xev' 'xclip' 'xorg-fonts-100dpi' 'xorg-fonts-75dpi'
)

depends=(
    "${_system_drivers[@]}"
    "${_desktop_env[@]}"
    "${_term_tools[@]}"
    "${_dev_environment[@]}"
    "${_apps[@]}"
    "${_utilities[@]}"
    "${_fonts_theme[@]}"
    "${_xorg_compat[@]}"
)

package() {
    /bin/true
}
