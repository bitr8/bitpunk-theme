# Bitpunk KDE Theme

A complete KDE Plasma 6 desktop theme with cyberpunk-inspired aesthetics. Cyan-dominant palette (#0ABDC6) with magenta and yellow accents, optimised for OLED displays with near-black backgrounds (#050505).

**Key differentiator**: Cohesive theming from boot splash → login screen → desktop, with auto-detected hardware sensors.

![Bitpunk Desktop](screenshots/desktop.png)

## What's Included

- **KDE Colour Scheme** - Window colours, selection, focus states
- **Plasma Desktop Theme** - Custom panel, widgets, and SVG elements
- **KDE Splash Screen** - Animated skull icon loading animation
- **Plymouth Boot Splash** - Pre-login boot theme (requires root)
- **Terminal Themes**
  - Konsole colour scheme + profile
  - Kitty terminal full config
  - Ghostty terminal full config
- **GTK Theme** - GTK 3/4 applications
- **Conky Widget** - System monitor with auto-detected CPU/GPU/network sensors
- **SDDM Login Theme** - Login screen (requires root)
- **Wallpaper & Cursor** - Custom wallpaper and Bibata-Modern-Ice cursor

## Installation

### Prerequisites

**KDE Plasma 6** on:
- Arch Linux
- Fedora
- Debian/Ubuntu
- openSUSE

#### Required Fonts

```bash
# Arch
sudo pacman -S ttf-jetbrains-mono ttf-cascadia-code-nerd inter-font

# Fedora
sudo dnf install jetbrains-mono-fonts cascadia-code-nf-fonts rsms-inter-fonts

# Debian/Ubuntu
sudo apt install fonts-jetbrains-mono fonts-inter
# Note: Cascadia Code NF must be installed from Nerd Fonts releases
```

#### Required Packages

```bash
# Arch
sudo pacman -S plasma conky papirus-icon-theme curl wget

# Fedora
sudo dnf install plasma-desktop conky papirus-icon-theme curl wget

# Debian/Ubuntu
sudo apt install plasma-desktop conky papirus-icon-theme curl wget
```

### Quick Install

```bash
git clone https://github.com/bitr8/bitpunk-theme.git
cd bitpunk-theme
./install.sh
```

The installer will:
1. Detect your distribution
2. Verify dependencies
3. Auto-detect hardware sensors for Conky (CPU, GPU, network)
4. Install all theme components
5. Download Bibata-Modern-Ice cursor
6. Apply theme to Plasma
7. Configure icon folder colours (cyan)
8. Print SDDM/Plymouth installation instructions

### SDDM Login Theme (Manual)

Requires root privilege. After running `install.sh`:

```bash
sudo cp -r sddm/Bitpunk /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf << 'EOF'
[Theme]
Current=Bitpunk
EOF
```

Or use: **System Settings** > **Colors & Themes** > **Login Screen (SDDM)**

### Plymouth Boot Splash (Manual)

Plymouth displays before SDDM during boot. Requires root and initramfs rebuild.

**Fedora:**
```bash
sudo cp -r plymouth/Bitpunk /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R Bitpunk
```

**Arch Linux:**
1. Edit `/etc/mkinitcpio.conf` and add `plymouth` after `base udev` in HOOKS
2. Install theme:
```bash
sudo cp -r plymouth/Bitpunk /usr/share/plymouth/themes/
sudo plymouth-set-default-theme Bitpunk
sudo mkinitcpio -P
```

**Debian/Ubuntu:**
```bash
sudo cp -r plymouth/Bitpunk /usr/share/plymouth/themes/
sudo plymouth-set-default-theme Bitpunk
sudo update-initramfs -u
```

**Revert to default:**
```bash
sudo plymouth-set-default-theme -R bgrt
```

## Uninstallation

```bash
./uninstall.sh
```

Manual cleanup for SDDM (if installed):
```bash
sudo rm -rf /usr/share/sddm/themes/Bitpunk
sudo rm -f /etc/sddm.conf.d/theme.conf
```

## Colour Palette

Inspired by cyberpunk aesthetics with OLED optimisation:

| Colour | Hex | Usage |
|--------|-----|-------|
| Deep Background | `#050505` | Near-black, OLED optimised |
| Window Background | `#0A0E14` | Base UI elements |
| Elevated Surfaces | `#1C2632` | Buttons, cards, panels |
| **Primary Cyan** | `#0ABDC6` | Main accent |
| **Secondary Magenta** | `#EA00D9` | Alternative accent |
| **Warning Yellow** | `#F3E600` | Alerts and warnings |
| Primary Text | `#E0E8F0` | Off-white |

## Conky Hardware Sensors

The installer auto-detects sensors by scanning `/sys/class/hwmon/*/name`.

**Supported:**
- CPU: k10temp, coretemp, zenpower
- GPU: amdgpu, nvidia, nouveau
- Network: First wireless (wl*) or ethernet (en*, eth*) interface

**Re-run detection** after hardware changes:
```bash
./install.sh
```

Or manually edit `~/.config/conky/bitpunk.conf`.

## File Locations

After installation, theme files are stored in:

```
~/.local/share/color-schemes/Bitpunk.colors
~/.local/share/plasma/desktoptheme/Bitpunk/
~/.local/share/plasma/look-and-feel/com.github.bitpunk.splash/
~/.local/share/konsole/Bitpunk.*
~/.themes/Bitpunk/
~/.config/conky/bitpunk.conf
~/.config/autostart/conky-bitpunk.desktop
~/.local/share/icons/Bibata-Modern-Ice/
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

## HiDPI Display Configuration

### Plasma Desktop

Auto-detected. Configure via:

**System Settings** → **Display and Monitor** → **Display Configuration** → **Scale**

### SDDM Login Screen

SDDM doesn't auto-scale. For high-DPI displays (>150 DPI):

```bash
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/hidpi.conf << 'EOF'
[General]
GreeterEnvironment=QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=192

[Wayland]
EnableHiDPI=true

[X11]
ServerArguments=-dpi 192
EOF
```

Adjust DPI values based on your display:

| Resolution | Screen Size | DPI | Recommended DPI |
|------------|-------------|-----|-----------------|
| 1920×1080  | 24"         | 92  | 96 (no scaling) |
| 2560×1440  | 27"         | 109 | 96 (no scaling) |
| 3840×2160  | 27"         | 163 | 144-192         |
| 3840×2160  | 32"         | 138 | 144             |
| 3840×2160  | 43"         | 103 | 96 (no scaling) |
| 2880×1800  | 13-15"      | 200 | 192-216         |
| 2560×1600  | 13-15"      | 177 | 168-192         |

### Plymouth Boot Splash

Auto-scales based on framebuffer resolution. No configuration needed.

## Troubleshooting

### Theme not applying

Clear Plasma cache and restart:
```bash
rm -rf ~/.cache/plasma* ~/.cache/ksvg*
kquitapp6 plasmashell && kstart plasmashell
```

### Conky not starting

Check for errors and verify sensors:
```bash
conky -c ~/.config/conky/bitpunk.conf
ls /sys/class/hwmon/*/name
```

### NVIDIA GPU sensors

For NVIDIA GPUs, ensure `nvidia` or `nouveau` driver is loaded. The Conky config uses hwmon. For more detailed stats, consider using `nvidia-smi` in Conky config.

## Additional Documentation

See `docs/desktop-customisation.md` for:
- Complete RGB colour values
- KDE theme file formats and locations
- Plasma widget SVG specifications
- OLED display guidelines
- Implementation notes and gotchas
