# Cyberpunk 2077 KDE Theme

A complete KDE Plasma 6 theme inspired by Cyberpunk 2077's Night City UI. Cyan-dominant with magenta/yellow accents, optimised for OLED displays.

## Components

- **KDE Colour Scheme** - Window colours, selection, focus states
- **Plasma Desktop Theme** - Panel, widgets, popups, SVGs
- **Konsole Terminal** - Colour scheme and profile
- **Kitty Terminal** - Full config with matching colours
- **GTK Theme** - GTK 3/4 applications
- **Conky Widget** - System monitor with auto-detected sensors
- **Wallpaper** - Abstract neon light streams
- **Cursor** - Bibata-Modern-Ice (downloaded during install)
- **SDDM Login Theme** - Login screen (manual sudo install)

## Requirements

- KDE Plasma 6
- conky
- papirus-icon-theme
- curl (for cursor download)
- wget (for papirus-folders)

### Arch Linux

```bash
sudo pacman -S plasma conky papirus-icon-theme curl wget
```

### Fedora

```bash
sudo dnf install plasma-desktop conky papirus-icon-theme curl wget
```

## Installation

```bash
git clone git@github.com:bitr8/dotfiles-kde-cyberpunk2077.git
cd dotfiles-kde-cyberpunk2077
./install.sh
```

The installer will:
1. Detect your distro (Arch/Fedora)
2. Check for dependencies
3. Auto-detect hardware sensors for conky (CPU, GPU, network interface)
4. Install all theme files
5. Download and install Bibata-Modern-Ice cursor
6. Configure papirus-folders with cyan colour
7. Apply the theme
8. Print SDDM installation instructions

## SDDM Theme (Manual)

SDDM themes require root privileges. After running `install.sh`, run:

```bash
sudo cp -r sddm/Cyberpunk2077 /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf << 'EOF'
[Theme]
Current=Cyberpunk2077
EOF
```

Or use: System Settings > Colors & Themes > Login Screen (SDDM)

## Uninstallation

```bash
./uninstall.sh
```

This removes all user-installed components. SDDM theme requires manual removal:

```bash
sudo rm -rf /usr/share/sddm/themes/Cyberpunk2077
sudo rm -f /etc/sddm.conf.d/theme.conf
```

## Colour Palette

| Colour | Hex | Usage |
|--------|-----|-------|
| Deep background | `#050505` | Near-black, OLED optimised |
| Window background | `#0A0E14` | Base UI colour |
| Elevated surfaces | `#1C2632` | Buttons, cards |
| **Cyan** | `#0ABDC6` | Primary accent |
| **Magenta** | `#EA00D9` | Secondary accent |
| **Yellow** | `#F3E600` | Warnings |
| Primary text | `#E0E8F0` | Off-white |

## Conky Sensors

The installer auto-detects hardware sensors by scanning `/sys/class/hwmon/*/name`. Supported sensors:

- **CPU**: k10temp, coretemp, zenpower
- **GPU**: amdgpu, nvidia, nouveau
- **Network**: First wireless (wl*) or ethernet (en*, eth*) interface

To re-run sensor detection after hardware changes:

```bash
./install.sh  # Re-run installer
```

Or manually edit `~/.config/conky/cyberpunk2077.conf`.

## File Locations

After installation:

```
~/.local/share/color-schemes/Cyberpunk2077.colors
~/.local/share/plasma/desktoptheme/Cyberpunk2077/
~/.local/share/konsole/Cyberpunk2077.*
~/.themes/Cyberpunk2077/
~/.config/conky/cyberpunk2077.conf
~/.config/conky/wallpaper-cyberpunk2077.jpg
~/.config/autostart/conky-cyberpunk2077.desktop
~/.local/share/icons/Bibata-Modern-Ice/
~/.config/kitty/kitty.conf
```

## Troubleshooting

### Theme not applying

```bash
# Clear Plasma cache and restart
rm -rf ~/.cache/plasma* ~/.cache/ksvg*
kquitapp6 plasmashell && kstart plasmashell
```

### Conky not starting

```bash
# Check for errors
conky -c ~/.config/conky/cyberpunk2077.conf

# Verify sensors exist
ls /sys/class/hwmon/*/name
```

### NVIDIA GPU sensors

For NVIDIA GPUs, ensure `nvidia` or `nouveau` driver is loaded. The conky config uses hwmon for temperature. For more detailed NVIDIA stats, consider using `nvidia-smi` in conky instead.
