# ⚡ Cyberpunk Niri & Waybar Dotfiles

A sleek, cohesive **Cyberpunk / Synthwave Neon** dotfiles setup for the **Niri** scrollable-tiling Wayland compositor on Arch Linux.

---

## ✨ Features

- **Niri Window Manager**:
  - Dual-tone gradient focus rings (`#ff007f` Hot Pink $\rightarrow$ `#00f0ff` Electric Cyan).
  - Ambient neon cyan drop shadows & window glow.
  - Smooth dynamic column layout with 6px gaps.
- **Waybar**:
  - Dark cyber glass aesthetics with a glowing neon border.
  - Interactive media player (MPRIS), custom battery popup, WiFi menu, control center, and formatted calendar.
- **Ghostty Terminal**:
  - Native Cyberpunk palette with subtle translucency (`0.88` opacity) and `0xProto Nerd Font`.
- **Rofi App Launcher & Quick Menus**:
  - Modern floating HUD for App search, Control Center, Network, and Power menus.
- **Mako Notification Daemon**:
  - Dark cyber glass toasts with neon cyan borders and magenta progress indicators.
- **Wallpaper Cycler Daemon**:
  - Smooth background wallpaper rotation script cycling across `~/Pictures/Wallpapers/` every 15 minutes.
- **Fastfetch**:
  - Custom neon-accented system info fetch.

---

## 📦 Dependencies

Ensure the following packages are installed on Arch Linux:

```bash
# Core Compositor & Tools
sudo pacman -S niri waybar rofi ghostty mako fastfetch swaybg

# Utilities & Audio/Brightness Backends
sudo pacman -S brightnessctl playerctl wireplumber pipewire libnotify

# Fonts & Icons (Recommended)
sudo pacman -S papirus-icon-theme ttf-jetbrains-mono-nerd
yay -S ttf-0xproto-nerd sweet-gtk-theme-dark-git
```

---

## 🚀 Quick Start & Installation

Clone this repository and run the automated installer:

```bash
git clone https://github.com/YOUR_USERNAME/niri-cyberpunk-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Back up your existing configs to `~/.config/backup_dotfiles_<date>`.
2. Copy the Niri, Waybar, Ghostty, Rofi, Mako, and Fastfetch configurations.
3. Install bundled sample wallpapers into `~/Pictures/Wallpapers/`.
4. Ensure all helper scripts are executable.

---

## ⌨️ Keybindings Quick Reference

| Keybinding | Action |
| :--- | :--- |
| **`Mod + T`** | Open Terminal (Ghostty) |
| **`Mod + Space`** | Application Launcher (Rofi) |
| **`Mod + O`** | Toggle Workspace Overview |
| **`Mod + Q`** | Close Window |
| **`Mod + M`** | Maximize Window |
| **`Mod + R`** | Cycle Column Width Preset |
| **`Mod + Left / Right`** | Focus Column Left / Right |
| **`Mod + Shift + Left / Right`** | Move Column Left / Right |
| **`Super + Alt + L`** | Lock Screen |
| **`XF86MonBrightnessUp/Down`** | Adjust Brightness with Notification |
| **`XF86AudioRaise/LowerVolume`** | Adjust Volume with Notification |
| **`XF86AudioMute`** | Toggle Mute |
| **`XF86AudioPlay / Next / Prev`** | Media Player Controls |

---

## 🖼️ Wallpaper Management

Drop any wallpapers (`.jpg`, `.png`, `.webp`) into:
```
~/Pictures/Wallpapers/
```
The rotation daemon will automatically cycle through them every 15 minutes.

To manually trigger the next wallpaper immediately:
```bash
~/.config/niri/scripts/wallpaper-cycle.sh next
```

---

## 📄 License

Distributed under the [MIT License](LICENSE).
