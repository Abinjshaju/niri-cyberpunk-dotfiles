#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/backup_dotfiles_$(date +%Y%m%d_%H%M%S)"

echo "================================================="
echo "   Niri & Waybar Cyberpunk Dotfiles Installer   "
echo "================================================="
echo

# 1. Package check / recommendation
PACKAGES=(
    "niri"
    "waybar"
    "rofi"
    "ghostty"
    "mako"
    "fastfetch"
    "swaybg"
    "brightnessctl"
    "playerctl"
    "wireplumber"
    "pipewire"
)

echo "==> Required packages:"
echo "    ${PACKAGES[*]}"
echo

if command -v pacman >/dev/null 2>&1; then
    read -rp "Do you want to install missing packages via pacman/yay? (y/N): " INSTALL_PKGS
    if [[ "$INSTALL_PKGS" =~ ^[Yy]$ ]]; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed "${PACKAGES[@]}"
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed "${PACKAGES[@]}"
        else
            sudo pacman -S --needed "${PACKAGES[@]}"
        fi
    fi
fi

# 2. Back up existing configs
echo "==> Backing up existing configurations to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

for item in niri ghostty mako fastfetch; do
    if [ -d "$HOME/.config/$item" ] || [ -f "$HOME/.config/$item" ]; then
        mv "$HOME/.config/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# 3. Create target directories & symlink/copy configs
echo "==> Linking configuration files to ~/.config..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/Pictures/Wallpapers"

cp -r "$DOTFILES_DIR/.config/niri" "$HOME/.config/"
cp -r "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/"
cp -r "$DOTFILES_DIR/.config/mako" "$HOME/.config/"
cp -r "$DOTFILES_DIR/.config/fastfetch" "$HOME/.config/"

# 4. Copy sample wallpapers
echo "==> Copying wallpapers to ~/Pictures/Wallpapers..."
cp -n "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

# 5. Fix script permissions
echo "==> Setting executable permissions on scripts..."
chmod +x "$HOME/.config/niri/scripts/"*.sh

echo
echo "================================================="
echo "   Installation Completed Successfully!          "
echo "================================================="
echo "To apply changes in an active Niri session, run:"
echo "  niri msg action load-config-file"
echo "  killall -SIGUSR2 waybar"
echo "  makoctl reload"
echo "================================================="
