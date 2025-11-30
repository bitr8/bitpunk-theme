#!/bin/bash
#
# Cyberpunk 2077 KDE Theme Installer
# Installs colour scheme, Plasma theme, Konsole, Kitty, GTK, conky, wallpaper, and cursor
# SDDM theme requires separate sudo installation (instructions printed at end)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="Cyberpunk2077"

# Colours for output
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${MAGENTA}▸${NC} $1"
}

print_success() {
    echo -e "${CYAN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|cachyos|endeavouros|manjaro)
                DISTRO="arch"
                PKG_MANAGER="pacman"
                QDBUS_CMD="qdbus6"
                ;;
            fedora|nobara)
                DISTRO="fedora"
                PKG_MANAGER="dnf"
                QDBUS_CMD="qdbus-qt6"
                ;;
            *)
                DISTRO="unknown"
                PKG_MANAGER="unknown"
                # Try to detect qdbus command
                if command -v qdbus6 &> /dev/null; then
                    QDBUS_CMD="qdbus6"
                elif command -v qdbus-qt6 &> /dev/null; then
                    QDBUS_CMD="qdbus-qt6"
                else
                    QDBUS_CMD="qdbus"
                fi
                ;;
        esac
    else
        DISTRO="unknown"
        PKG_MANAGER="unknown"
        QDBUS_CMD="qdbus"
    fi

    print_step "Detected distro: $DISTRO (package manager: $PKG_MANAGER, qdbus: $QDBUS_CMD)"
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"

    local missing=()

    # Check for KDE Plasma
    if ! command -v plasmashell &> /dev/null; then
        missing+=("plasma-desktop")
    fi

    # Check for conky
    if ! command -v conky &> /dev/null; then
        missing+=("conky")
    fi

    # Check for papirus icons
    if [ ! -d "/usr/share/icons/Papirus-Dark" ] && [ ! -d "$HOME/.local/share/icons/Papirus-Dark" ]; then
        missing+=("papirus-icon-theme")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing[*]}"
        echo ""
        if [ "$PKG_MANAGER" = "pacman" ]; then
            echo "Install with: sudo pacman -S ${missing[*]}"
        elif [ "$PKG_MANAGER" = "dnf" ]; then
            echo "Install with: sudo dnf install ${missing[*]}"
        fi
        echo ""
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All dependencies found"
    fi
}

# Auto-detect hardware sensors for conky
detect_sensors() {
    print_header "Detecting Hardware Sensors"

    # Find CPU temp sensor (k10temp, coretemp, etc.)
    CPU_HWMON=""
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/name" ]; then
            name=$(cat "$hwmon/name")
            case "$name" in
                k10temp|coretemp|zenpower)
                    CPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "CPU sensor: $name (hwmon$CPU_HWMON)"
                    break
                    ;;
            esac
        fi
    done

    if [ -z "$CPU_HWMON" ]; then
        print_warning "CPU sensor not found, using hwmon0"
        CPU_HWMON="0"
    fi

    # Find GPU temp sensor (amdgpu, nvidia, etc.)
    GPU_HWMON=""
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/name" ]; then
            name=$(cat "$hwmon/name")
            case "$name" in
                amdgpu|nvidia|nouveau)
                    GPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "GPU sensor: $name (hwmon$GPU_HWMON)"
                    break
                    ;;
            esac
        fi
    done

    if [ -z "$GPU_HWMON" ]; then
        print_warning "GPU sensor not found, using hwmon1"
        GPU_HWMON="1"
    fi

    # Find network interface
    NET_IFACE=""
    # Prefer wireless, fall back to ethernet
    for iface in /sys/class/net/*; do
        iface_name=$(basename "$iface")
        if [[ "$iface_name" == wl* ]]; then
            NET_IFACE="$iface_name"
            print_success "Network interface: $NET_IFACE (wireless)"
            break
        fi
    done

    if [ -z "$NET_IFACE" ]; then
        for iface in /sys/class/net/*; do
            iface_name=$(basename "$iface")
            if [[ "$iface_name" == en* ]] || [[ "$iface_name" == eth* ]]; then
                NET_IFACE="$iface_name"
                print_success "Network interface: $NET_IFACE (ethernet)"
                break
            fi
        done
    fi

    if [ -z "$NET_IFACE" ]; then
        print_warning "Network interface not found, using eth0"
        NET_IFACE="eth0"
    fi

    # Find GPU busy percent path
    GPU_BUSY_PATH=""
    for card in /sys/class/drm/card*/device/gpu_busy_percent; do
        if [ -f "$card" ]; then
            GPU_BUSY_PATH="$card"
            print_success "GPU busy path: $GPU_BUSY_PATH"
            break
        fi
    done

    if [ -z "$GPU_BUSY_PATH" ]; then
        GPU_BUSY_PATH="/sys/class/drm/card0/device/gpu_busy_percent"
        print_warning "GPU busy path not found, using default"
    fi
}

# Install theme files
install_theme() {
    print_header "Installing Theme Files"

    # Create directories
    mkdir -p ~/.local/share/color-schemes
    mkdir -p ~/.local/share/plasma/desktoptheme
    mkdir -p ~/.local/share/konsole
    mkdir -p ~/.themes
    mkdir -p ~/.config/conky
    mkdir -p ~/.config/autostart
    mkdir -p ~/.local/share/icons

    # KDE Colour Scheme
    print_step "Installing KDE colour scheme..."
    cp "$SCRIPT_DIR/plasma/color-schemes/Cyberpunk2077.colors" ~/.local/share/color-schemes/
    print_success "Colour scheme installed"

    # Plasma Desktop Theme
    print_step "Installing Plasma desktop theme..."
    cp -r "$SCRIPT_DIR/plasma/desktoptheme/Cyberpunk2077" ~/.local/share/plasma/desktoptheme/
    print_success "Desktop theme installed"

    # Konsole
    print_step "Installing Konsole theme..."
    cp "$SCRIPT_DIR/konsole/Cyberpunk2077.colorscheme" ~/.local/share/konsole/
    cp "$SCRIPT_DIR/konsole/Cyberpunk2077.profile" ~/.local/share/konsole/
    print_success "Konsole theme installed"

    # Kitty
    if [ -d "$SCRIPT_DIR/kitty" ]; then
        print_step "Installing Kitty config..."
        mkdir -p ~/.config/kitty
        cp "$SCRIPT_DIR/kitty/kitty.conf" ~/.config/kitty/
        print_success "Kitty config installed"
    fi

    # GTK Theme
    print_step "Installing GTK theme..."
    cp -r "$SCRIPT_DIR/gtk/Cyberpunk2077" ~/.themes/
    print_success "GTK theme installed"

    # Wallpaper
    print_step "Installing wallpaper..."
    cp "$SCRIPT_DIR/wallpapers/wallpaper-cyberpunk2077.jpg" ~/.config/conky/
    print_success "Wallpaper installed"

    # Conky (with sensor substitution)
    print_step "Installing conky config (with detected sensors)..."
    sed -e "s/hwmon 8 temp 1/hwmon $CPU_HWMON temp 1/g" \
        -e "s/hwmon 7 temp 1/hwmon $GPU_HWMON temp 1/g" \
        -e "s|/sys/class/drm/card1/device/gpu_busy_percent|$GPU_BUSY_PATH|g" \
        -e "s/wlp195s0/$NET_IFACE/g" \
        "$SCRIPT_DIR/conky/cyberpunk2077.conf" > ~/.config/conky/cyberpunk2077.conf
    print_success "Conky config installed (CPU: hwmon$CPU_HWMON, GPU: hwmon$GPU_HWMON, NET: $NET_IFACE)"

    # Conky autostart
    print_step "Installing conky autostart..."
    cp "$SCRIPT_DIR/conky/conky-cyberpunk2077.desktop" ~/.config/autostart/
    print_success "Conky autostart installed"
}

# Install cursor theme
install_cursor() {
    print_header "Installing Cursor Theme"

    if [ -d ~/.local/share/icons/Bibata-Modern-Ice ]; then
        print_success "Bibata-Modern-Ice already installed"
        return
    fi

    print_step "Downloading Bibata-Modern-Ice cursor..."

    CURSOR_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
    TEMP_DIR=$(mktemp -d)

    if curl -sL "$CURSOR_URL" -o "$TEMP_DIR/cursor.tar.xz"; then
        tar -xf "$TEMP_DIR/cursor.tar.xz" -C "$TEMP_DIR"
        mv "$TEMP_DIR/Bibata-Modern-Ice" ~/.local/share/icons/
        rm -rf "$TEMP_DIR"
        print_success "Cursor theme installed"
    else
        print_warning "Failed to download cursor theme. Install manually from:"
        echo "  https://github.com/ful1e5/Bibata_Cursor/releases"
    fi
}

# Install papirus-folders if needed
install_papirus_folders() {
    print_header "Configuring Papirus Folders"

    if ! command -v papirus-folders &> /dev/null; then
        print_step "Installing papirus-folders..."
        if wget -qO- https://git.io/papirus-folders-install | env PREFIX=$HOME/.local sh; then
            export PATH="$HOME/.local/bin:$PATH"
            print_success "papirus-folders installed"
        else
            print_warning "Failed to install papirus-folders. Skipping folder colour configuration."
            return
        fi
    fi

    print_step "Applying cyan folder colour..."
    if papirus-folders -C cyan --theme Papirus-Dark 2>/dev/null; then
        print_success "Cyan folder colour applied"
    else
        print_warning "Failed to apply folder colour"
    fi
}

# Apply theme
apply_theme() {
    print_header "Applying Theme"

    print_step "Applying colour scheme..."
    plasma-apply-colorscheme Cyberpunk2077 2>/dev/null || print_warning "Could not apply colour scheme"

    print_step "Applying desktop theme..."
    plasma-apply-desktoptheme Cyberpunk2077 2>/dev/null || print_warning "Could not apply desktop theme"

    print_step "Applying wallpaper..."
    plasma-apply-wallpaperimage ~/.config/conky/wallpaper-cyberpunk2077.jpg 2>/dev/null || print_warning "Could not apply wallpaper"

    print_step "Setting icon theme..."
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null || true

    print_step "Setting cursor theme..."
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24 2>/dev/null || true

    print_step "Setting Konsole default profile..."
    kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Cyberpunk2077.profile 2>/dev/null || true

    print_step "Configuring GTK..."
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=Cyberpunk2077
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
EOF
    cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

    print_step "Refreshing KWin..."
    $QDBUS_CMD org.kde.KWin /KWin reconfigure 2>/dev/null || print_warning "Could not refresh KWin"

    print_step "Starting conky..."
    killall conky 2>/dev/null || true
    sleep 1
    conky -c ~/.config/conky/cyberpunk2077.conf &>/dev/null &
    disown

    print_success "Theme applied!"
}

# Print SDDM instructions
print_sddm_instructions() {
    print_header "SDDM Theme (Manual Installation Required)"

    echo -e "${YELLOW}SDDM themes require root privileges. Run these commands manually:${NC}"
    echo ""
    echo "  sudo cp -r $SCRIPT_DIR/sddm/Cyberpunk2077 /usr/share/sddm/themes/"
    echo "  sudo mkdir -p /etc/sddm.conf.d"
    echo "  sudo tee /etc/sddm.conf.d/theme.conf << 'EOF'"
    echo "  [Theme]"
    echo "  Current=Cyberpunk2077"
    echo "  EOF"
    echo ""
    echo -e "${CYAN}Or use System Settings > Colors & Themes > Login Screen (SDDM)${NC}"
}

# Main
main() {
    print_header "Cyberpunk 2077 KDE Theme Installer"
    echo "This script will install the Cyberpunk 2077 theme for KDE Plasma."
    echo ""

    detect_distro
    check_dependencies
    detect_sensors
    install_theme
    install_cursor
    install_papirus_folders
    apply_theme
    print_sddm_instructions

    print_header "Installation Complete!"
    echo -e "You may need to ${CYAN}log out and back in${NC} for all changes to take effect."
    echo ""
    echo "To restart conky manually:"
    echo "  killall conky; conky -c ~/.config/conky/cyberpunk2077.conf &"
    echo ""
    echo -e "${CYAN}Enjoy your Night City desktop!${NC}"
}

main "$@"
