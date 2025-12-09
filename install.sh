#!/bin/bash
#
# Bitpunk KDE Theme Installer
# Installs colour scheme, Plasma theme, Konsole, Kitty, GTK, conky, wallpaper, and cursor
# SDDM theme requires separate sudo installation (instructions printed at end)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="Bitpunk"

# Parse arguments
INTERACTIVE=true
SKIP_CURSOR=false
SKIP_PAPIRUS=false
SKIP_APPLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            INTERACTIVE=false
            shift
            ;;
        --skip-cursor)
            SKIP_CURSOR=true
            shift
            ;;
        --skip-papirus)
            SKIP_PAPIRUS=true
            shift
            ;;
        --skip-apply)
            SKIP_APPLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./install.sh [options]"
            echo ""
            echo "Options:"
            echo "  -y, --yes        Non-interactive mode (accept defaults)"
            echo "  --skip-cursor    Don't download cursor theme"
            echo "  --skip-papirus   Don't configure papirus-folders"
            echo "  --skip-apply     Install files only, don't apply theme"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

backup_if_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        if cp "$file" "$backup" 2>/dev/null; then
            print_step "Backed up: $file → $backup"
        else
            print_warning "Failed to backup $file (continuing anyway)"
        fi
    fi
}

print_install_instructions() {
    local pkgs="$1"
    echo ""
    case "$PKG_MANAGER" in
        pacman) echo "  sudo pacman -S $pkgs" ;;
        dnf)    echo "  sudo dnf install $pkgs" ;;
        apt)    echo "  sudo apt install $pkgs" ;;
        zypper) echo "  sudo zypper install $pkgs" ;;
        *)      echo "  Install manually: $pkgs" ;;
    esac
    echo ""
}

print_font_instructions() {
    echo ""
    case "$PKG_MANAGER" in
        pacman) echo "  sudo pacman -S ttf-jetbrains-mono ttf-cascadia-code-nerd inter-font" ;;
        dnf)    echo "  sudo dnf install jetbrains-mono-fonts cascadia-code-nf-fonts google-inter-fonts" ;;
        apt)    echo "  # Nerd Fonts not in apt - download from https://www.nerdfonts.com/font-downloads"
                echo "  sudo apt install fonts-jetbrains-mono fonts-inter"
                echo "  # Then manually install CascadiaCode Nerd Font" ;;
        zypper) echo "  sudo zypper install jetbrains-mono-fonts inter-fonts"
                echo "  # Nerd Fonts: download from https://www.nerdfonts.com/font-downloads" ;;
        *)      echo "  Install JetBrains Mono, Cascadia Code NF (Nerd Font), and Inter fonts"
                echo "  Nerd Fonts: https://www.nerdfonts.com/font-downloads" ;;
    esac
    echo ""
    print_warning "Nerd Fonts are REQUIRED for conky icons to display correctly"
}

# Detect distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|cachyos|endeavouros|manjaro|garuda|artix)
                DISTRO="arch"
                PKG_MANAGER="pacman"
                QDBUS_CMD="qdbus6"
                INITRAMFS_CMD="mkinitcpio -P"
                ;;
            fedora|nobara|ultramarine)
                DISTRO="fedora"
                PKG_MANAGER="dnf"
                QDBUS_CMD="qdbus-qt6"
                INITRAMFS_CMD="dracut --force"
                ;;
            debian|ubuntu|pop|linuxmint|zorin|elementary)
                DISTRO="debian"
                PKG_MANAGER="apt"
                QDBUS_CMD="qdbus6"
                INITRAMFS_CMD="update-initramfs -u"
                ;;
            opensuse*|suse*)
                DISTRO="suse"
                PKG_MANAGER="zypper"
                QDBUS_CMD="qdbus6"
                INITRAMFS_CMD="dracut --force"
                ;;
            *)
                DISTRO="unknown"
                PKG_MANAGER="unknown"
                # Auto-detect qdbus command
                if command -v qdbus6 &> /dev/null; then
                    QDBUS_CMD="qdbus6"
                elif command -v qdbus-qt6 &> /dev/null; then
                    QDBUS_CMD="qdbus-qt6"
                else
                    QDBUS_CMD="qdbus"
                fi
                INITRAMFS_CMD=""
                ;;
        esac
    else
        DISTRO="unknown"
        PKG_MANAGER="unknown"
        QDBUS_CMD="qdbus"
        INITRAMFS_CMD=""
    fi

    print_step "Detected: $DISTRO (pkg: $PKG_MANAGER, qdbus: $QDBUS_CMD)"
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"

    local missing_pkgs=()
    local missing_cmds=()
    local missing_fonts=()

    # Required commands (including tools used for hardware detection and theme application)
    for cmd in plasmashell conky kwriteconfig6 plasma-apply-colorscheme plasma-apply-desktoptheme plasma-apply-wallpaperimage curl lscpu lspci tar sha256sum kbuildsycoca6; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done

    # Optional but recommended commands
    local optional_missing=()
    for cmd in wget nmcli papirus-folders; do
        if ! command -v "$cmd" &> /dev/null; then
            optional_missing+=("$cmd")
        fi
    done

    # Check for Papirus icons (required for cyan folder colour feature)
    if [ ! -d "/usr/share/icons/Papirus-Dark" ] && [ ! -d "$HOME/.local/share/icons/Papirus-Dark" ]; then
        missing_pkgs+=("papirus-icon-theme")
        print_warning "Papirus-Dark icons not found - cyan folder colours will not be applied"
    fi

    # Check for required fonts (only if fc-list is available)
    if command -v fc-list &> /dev/null; then
        if ! fc-list | grep -qi "jetbrains"; then
            missing_fonts+=("JetBrains Mono")
        fi
        # Check for Nerd Font variant (required for conky icons)
        if ! fc-list | grep -qi "cascadia.*nerd\|cascadia.*nf"; then
            missing_fonts+=("Cascadia Code NF (Nerd Font)")
        fi
        if ! fc-list | grep -qi "inter"; then
            missing_fonts+=("Inter")
        fi
    else
        print_warning "fc-list not found - skipping font check (install fontconfig)"
    fi

    # Report findings
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_cmds[*]}"
        print_install_instructions "${missing_cmds[*]}"
        exit 1
    fi

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        print_warning "Missing packages: ${missing_pkgs[*]}"
        print_install_instructions "${missing_pkgs[*]}"
    fi

    if [ ${#missing_fonts[@]} -gt 0 ]; then
        print_warning "Missing fonts (theme may look incorrect): ${missing_fonts[*]}"
        print_font_instructions
    fi

    if [ ${#optional_missing[@]} -gt 0 ]; then
        print_warning "Optional tools not found: ${optional_missing[*]}"
    fi

    print_success "Dependency check complete"
}

# Auto-detect hardware sensors for conky
detect_sensors() {
    print_header "Detecting Hardware Sensors"

    # Find CPU temp sensor (k10temp, coretemp, etc.)
    CPU_HWMON=""
    HAS_CPU_SENSOR=true
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/name" ]; then
            name=$(cat "$hwmon/name")
            case "$name" in
                k10temp|coretemp|zenpower|acpitz|thinkpad|hp-wmi|dell-smm-hwmon)
                    CPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "CPU sensor: $name (hwmon$CPU_HWMON)"
                    break
                    ;;
            esac
        fi
    done

    if [ -z "$CPU_HWMON" ]; then
        # Check if running in a VM
        if command -v systemd-detect-virt &> /dev/null && systemd-detect-virt -q 2>/dev/null; then
            print_warning "Virtual machine detected - CPU temperature monitoring will be disabled"
            HAS_CPU_SENSOR=false
            CPU_HWMON="0"
        else
            print_warning "CPU sensor not found - CPU temperature section will be hidden"
            HAS_CPU_SENSOR=false
            CPU_HWMON="0"
        fi
    fi

    # Find GPU temp sensor (AMD, NVIDIA, Intel, etc.)
    GPU_HWMON=""
    HAS_GPU_SENSOR=true
    for hwmon in /sys/class/hwmon/hwmon*; do
        if [ -f "$hwmon/name" ]; then
            name=$(cat "$hwmon/name")
            case "$name" in
                amdgpu|radeon)
                    GPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "GPU sensor: $name (hwmon$GPU_HWMON) [AMD]"
                    break
                    ;;
                nvidia)
                    GPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "GPU sensor: $name (hwmon$GPU_HWMON) [NVIDIA]"
                    break
                    ;;
                nouveau)
                    GPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "GPU sensor: $name (hwmon$GPU_HWMON) [NVIDIA/nouveau]"
                    break
                    ;;
                i915|xe)
                    GPU_HWMON=$(basename "$hwmon" | sed 's/hwmon//')
                    print_success "GPU sensor: $name (hwmon$GPU_HWMON) [Intel]"
                    break
                    ;;
            esac
        fi
    done

    if [ -z "$GPU_HWMON" ]; then
        # Check if running in a VM
        if command -v systemd-detect-virt &> /dev/null && systemd-detect-virt -q 2>/dev/null; then
            print_warning "Virtual machine detected - GPU monitoring will be disabled"
            HAS_GPU_SENSOR=false
            GPU_HWMON="0"
        else
            print_warning "GPU sensor not found - GPU monitoring may not work"
            HAS_GPU_SENSOR=false
            GPU_HWMON="0"
        fi
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

    # Detect CPU model name
    CPU_NAME=$(lscpu | grep "Model name" | sed 's/.*: *//' | head -1)
    if [ -z "$CPU_NAME" ]; then
        CPU_NAME="CPU"
    fi
    print_success "CPU name: $CPU_NAME"

    # Detect GPU model name (extract bracketed part if available, e.g., "[Radeon 890M]")
    GPU_RAW=$(lspci | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //')
    # Try to extract the bracketed model name first
    GPU_NAME=$(echo "$GPU_RAW" | sed -n 's/.*\[\([^]]*\)\].*/\1/p' | head -1)
    # Fall back to truncated full string if no brackets
    if [ -z "$GPU_NAME" ]; then
        GPU_NAME=$(echo "$GPU_RAW" | cut -c1-40)
    fi
    if [ -z "$GPU_NAME" ]; then
        GPU_NAME="GPU"
    fi
    print_success "GPU name: $GPU_NAME"

    # Detect battery (for laptops)
    BATTERY=""
    for bat in /sys/class/power_supply/BAT*; do
        if [ -d "$bat" ]; then
            BATTERY=$(basename "$bat")
            print_success "Battery: $BATTERY"
            break
        fi
    done

    if [ -z "$BATTERY" ]; then
        BATTERY=""
        HAS_BATTERY=false
        print_warning "No battery detected (desktop system) - battery section will be hidden"
    else
        HAS_BATTERY=true
    fi
}

# Install theme files
install_theme() {
    print_header "Installing Theme Files"

    # Create directories
    mkdir -p ~/.local/share/color-schemes
    mkdir -p ~/.local/share/plasma/desktoptheme
    mkdir -p ~/.local/share/plasma/look-and-feel
    mkdir -p ~/.local/share/konsole
    mkdir -p ~/.themes
    mkdir -p ~/.config/conky
    mkdir -p ~/.config/autostart
    mkdir -p ~/.local/share/icons

    # KDE Colour Scheme
    print_step "Installing KDE colour scheme..."
    cp "$SCRIPT_DIR/plasma/color-schemes/Bitpunk.colors" ~/.local/share/color-schemes/
    print_success "Colour scheme installed"

    # Plasma Desktop Theme
    print_step "Installing Plasma desktop theme..."
    cp -r "$SCRIPT_DIR/plasma/desktoptheme/Bitpunk" ~/.local/share/plasma/desktoptheme/
    print_success "Desktop theme installed"

    # Splash Screen
    if [ -d "$SCRIPT_DIR/splash" ]; then
        print_step "Installing splash screen..."
        SPLASH_DEST=~/.local/share/plasma/look-and-feel/com.github.bitpunk.splash
        # Remove existing to prevent nested directory on reinstall
        rm -rf "$SPLASH_DEST"
        cp -r "$SCRIPT_DIR/splash" "$SPLASH_DEST"
        print_success "Splash screen installed"
    fi

    # Konsole
    print_step "Installing Konsole theme..."
    cp "$SCRIPT_DIR/konsole/Bitpunk.colorscheme" ~/.local/share/konsole/
    cp "$SCRIPT_DIR/konsole/Bitpunk.profile" ~/.local/share/konsole/
    print_success "Konsole theme installed"

    # Kitty
    if [ -d "$SCRIPT_DIR/kitty" ]; then
        print_step "Installing Kitty config..."
        mkdir -p ~/.config/kitty
        backup_if_exists ~/.config/kitty/kitty.conf
        cp "$SCRIPT_DIR/kitty/kitty.conf" ~/.config/kitty/
        print_success "Kitty config installed"
    fi

    # Ghostty
    if [ -d "$SCRIPT_DIR/ghostty" ]; then
        print_step "Installing Ghostty config..."
        mkdir -p ~/.config/ghostty
        backup_if_exists ~/.config/ghostty/config
        cp "$SCRIPT_DIR/ghostty/config" ~/.config/ghostty/
        print_success "Ghostty config installed"
    fi

    # GTK Theme
    print_step "Installing GTK theme..."
    cp -r "$SCRIPT_DIR/gtk/Bitpunk" ~/.themes/
    print_success "GTK theme installed"

    # Wallpaper
    print_step "Installing wallpaper..."
    cp "$SCRIPT_DIR/wallpapers/wallpaper-bitpunk.jpg" ~/.config/conky/
    print_success "Wallpaper installed"

    # Conky (with sensor substitution)
    print_step "Installing conky config (with detected sensors)..."
    # Escape forward slashes and ampersands in names for sed replacement
    CPU_NAME_ESCAPED=$(echo "$CPU_NAME" | sed 's/[/&]/\\&/g')
    GPU_NAME_ESCAPED=$(echo "$GPU_NAME" | sed 's/[/&]/\\&/g')
    NET_IFACE_ESCAPED=$(echo "$NET_IFACE" | sed 's/[/&]/\\&/g')

    # Start with base substitutions
    sed -e "s/hwmon 8 temp 1/hwmon $CPU_HWMON temp 1/g" \
        -e "s/hwmon 7 temp 1/hwmon $GPU_HWMON temp 1/g" \
        -e "s|/sys/class/drm/card1/device/gpu_busy_percent|$GPU_BUSY_PATH|g" \
        -e "s/wlp195s0/$NET_IFACE_ESCAPED/g" \
        -e "s/__CPU_NAME__/$CPU_NAME_ESCAPED/g" \
        -e "s/__GPU_NAME__/$GPU_NAME_ESCAPED/g" \
        -e "s/__BATTERY__/$BATTERY/g" \
        "$SCRIPT_DIR/conky/bitpunk.conf" > ~/.config/conky/bitpunk.conf

    # Handle CPU section
    if [ "$HAS_CPU_SENSOR" = false ]; then
        # Remove the entire CPU temp section on VMs or unsupported hardware
        sed -i '/__CPU_SECTION_START__/,/__CPU_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        print_step "CPU temperature section removed (no sensor found)"
    else
        # Remove marker lines (keep the CPU content)
        sed -i '/__CPU_SECTION_START__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        sed -i '/__CPU_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
    fi

    # Handle GPU section
    if [ "$HAS_GPU_SENSOR" = false ]; then
        # Remove the entire GPU section on VMs or unsupported hardware
        sed -i '/__GPU_SECTION_START__/,/__GPU_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        print_step "GPU section removed (no sensor found)"
    else
        # Remove marker lines (keep the GPU content)
        sed -i '/__GPU_SECTION_START__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        sed -i '/__GPU_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
    fi

    # Handle battery section
    if [ "$HAS_BATTERY" = false ]; then
        # Remove the entire battery section on desktops
        sed -i '/__BATTERY_SECTION_START__/,/__BATTERY_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        print_step "Battery section removed (desktop system)"
    else
        # On laptops, just remove the marker lines (keep the battery content)
        sed -i '/__BATTERY_SECTION_START__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
        sed -i '/__BATTERY_SECTION_END__/d' ~/.config/conky/bitpunk.conf 2>/dev/null || true
    fi

    # Build summary of what was installed
    local sensors_summary="NET: $NET_IFACE"
    [ "$HAS_CPU_SENSOR" = true ] && sensors_summary="CPU: hwmon$CPU_HWMON, $sensors_summary"
    [ "$HAS_GPU_SENSOR" = true ] && sensors_summary="GPU: hwmon$GPU_HWMON, $sensors_summary"
    print_success "Conky config installed ($sensors_summary)"

    # Conky autostart
    print_step "Installing conky autostart..."
    cp "$SCRIPT_DIR/conky/conky-bitpunk.desktop" ~/.config/autostart/
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
    CURSOR_SHA256="a68cae60c4dc706350e194ebc91c5fe48bc7bc9d59e119555834a2a7ee5078ef"
    TEMP_DIR=$(mktemp -d)

    # Ensure cleanup on exit or interrupt
    cleanup_cursor_temp() { rm -rf "$TEMP_DIR" 2>/dev/null; }
    trap cleanup_cursor_temp EXIT

    if curl -sL "$CURSOR_URL" -o "$TEMP_DIR/cursor.tar.xz"; then
        # Verify checksum
        print_step "Verifying download..."
        ACTUAL_SHA256=$(sha256sum "$TEMP_DIR/cursor.tar.xz" | cut -d' ' -f1)
        if [ "$ACTUAL_SHA256" = "$CURSOR_SHA256" ]; then
            print_success "Checksum verified"
            # Extract and install
            tar -xf "$TEMP_DIR/cursor.tar.xz" -C "$TEMP_DIR"
            mv "$TEMP_DIR/Bibata-Modern-Ice" ~/.local/share/icons/
            print_success "Cursor theme installed"
        else
            print_error "Checksum verification failed - aborting cursor install"
            print_warning "Expected: $CURSOR_SHA256"
            print_warning "Got:      $ACTUAL_SHA256"
            print_warning "Install manually from: https://github.com/ful1e5/Bibata_Cursor/releases"
        fi
    else
        print_warning "Failed to download cursor theme. Install manually from:"
        echo "  https://github.com/ful1e5/Bibata_Cursor/releases"
    fi

    # Cleanup and remove trap
    cleanup_cursor_temp
    trap - EXIT
}

# Install papirus-folders if needed
install_papirus_folders() {
    print_header "Configuring Papirus Folders"

    if ! command -v papirus-folders &> /dev/null; then
        print_step "Installing papirus-folders..."

        # Download and verify before executing (security: no pipe to sh)
        PAPIRUS_URL="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/install.sh"
        PAPIRUS_SHA256="37d60fdf71e6d8db476309e9629ac39075b2112b1167516ed181c24ae1e22b98"
        TEMP_SCRIPT=$(mktemp)

        if curl -sL "$PAPIRUS_URL" -o "$TEMP_SCRIPT"; then
            ACTUAL_SHA256=$(sha256sum "$TEMP_SCRIPT" | cut -d' ' -f1)
            if [ "$ACTUAL_SHA256" = "$PAPIRUS_SHA256" ]; then
                print_success "Script verified"
                if env PREFIX=$HOME/.local sh "$TEMP_SCRIPT"; then
                    export PATH="$HOME/.local/bin:$PATH"
                    print_success "papirus-folders installed"
                else
                    print_warning "papirus-folders installation failed"
                    rm -f "$TEMP_SCRIPT"
                    return
                fi
            else
                print_warning "Checksum mismatch - skipping papirus-folders"
                print_warning "Expected: $PAPIRUS_SHA256"
                print_warning "Got:      $ACTUAL_SHA256"
                print_warning "Install manually: https://github.com/PapirusDevelopmentTeam/papirus-folders"
                rm -f "$TEMP_SCRIPT"
                return
            fi
            rm -f "$TEMP_SCRIPT"
        else
            print_warning "Failed to download papirus-folders. Skipping folder colour configuration."
            return
        fi
    fi

    print_step "Applying cyan folder colour..."
    if papirus-folders -C cyan --theme Papirus-Dark 2>/dev/null; then
        print_success "Cyan folder colour applied"

        # Clear icon cache to ensure changes are visible immediately
        print_step "Clearing icon cache..."
        rm -rf ~/.cache/icon-cache.kcache 2>/dev/null || true
        kbuildsycoca6 --noincremental 2>/dev/null || true

        verify_icon_theme
    else
        print_warning "Failed to apply folder colour"
    fi
}

# Verify icon theme was applied correctly
verify_icon_theme() {
    if papirus-folders -l --theme Papirus-Dark 2>/dev/null | grep -q "cyan"; then
        print_success "Icon theme verified: cyan folders active"
        return 0
    else
        print_warning "Icon theme may not be applied correctly"
        return 1
    fi
}

# Apply theme
apply_theme() {
    print_header "Applying Theme"

    local apply_errors=0

    print_step "Applying colour scheme..."
    if plasma-apply-colorscheme Bitpunk >/dev/null 2>&1; then
        print_success "Colour scheme applied"
    else
        print_warning "Could not apply colour scheme - check plasma-apply-colorscheme is installed"
        ((apply_errors++)) || true
    fi

    print_step "Applying desktop theme..."
    if plasma-apply-desktoptheme Bitpunk >/dev/null 2>&1; then
        print_success "Desktop theme applied"
    else
        print_warning "Could not apply desktop theme - check plasma-apply-desktoptheme is installed"
        ((apply_errors++)) || true
    fi

    print_step "Applying splash screen..."
    if kwriteconfig6 --file ksplashrc --group KSplash --key Theme com.github.bitpunk.splash 2>/dev/null; then
        kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML 2>/dev/null || true
        print_success "Splash screen configured"
    else
        print_warning "Could not apply splash screen - check kwriteconfig6 is installed"
        ((apply_errors++)) || true
    fi

    print_step "Applying wallpaper..."
    if plasma-apply-wallpaperimage "$HOME/.config/conky/wallpaper-bitpunk.jpg" >/dev/null 2>&1; then
        print_success "Wallpaper applied"
    else
        print_warning "Could not apply wallpaper - you may need to set it manually in System Settings"
        ((apply_errors++)) || true
    fi

    print_step "Setting icon theme..."
    if kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null; then
        print_success "Icon theme set to Papirus-Dark"
    else
        print_warning "Could not set icon theme"
        ((apply_errors++)) || true
    fi

    print_step "Setting cursor theme..."
    if kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Bibata-Modern-Ice 2>/dev/null && \
       kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24 2>/dev/null; then
        print_success "Cursor theme set to Bibata-Modern-Ice"
    else
        print_warning "Could not set cursor theme"
        ((apply_errors++)) || true
    fi

    print_step "Setting Konsole default profile..."
    if kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile Bitpunk.profile 2>/dev/null; then
        print_success "Konsole profile set"
    else
        print_warning "Could not set Konsole profile"
    fi

    print_step "Configuring GTK..."
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    backup_if_exists ~/.config/gtk-3.0/settings.ini
    backup_if_exists ~/.config/gtk-4.0/settings.ini
    cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=Bitpunk
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
EOF
    cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
    print_success "GTK settings configured"

    print_step "Refreshing KWin..."
    if $QDBUS_CMD org.kde.KWin /KWin reconfigure 2>/dev/null; then
        print_success "KWin refreshed"
    else
        print_warning "Could not refresh KWin - changes may require logout to take effect"
    fi

    print_step "Starting conky..."
    killall conky 2>/dev/null || true
    sleep 1
    conky -c ~/.config/conky/bitpunk.conf &>/dev/null &
    disown
    print_success "Conky started"

    if [ "$apply_errors" -gt 0 ]; then
        print_warning "Theme applied with $apply_errors warning(s) - some components may need manual configuration"
    else
        print_success "Theme applied successfully!"
    fi
}

# Print SDDM instructions
print_sddm_instructions() {
    print_header "SDDM Theme (Manual Installation Required)"

    echo -e "${YELLOW}SDDM themes require root privileges. Run these commands manually:${NC}"
    echo ""
    echo "  sudo cp -r $SCRIPT_DIR/sddm/Bitpunk /usr/share/sddm/themes/"
    echo "  sudo mkdir -p /etc/sddm.conf.d"
    echo "  sudo tee /etc/sddm.conf.d/theme.conf << 'EOF'"
    echo "  [Theme]"
    echo "  Current=Bitpunk"
    echo "  EOF"
    echo ""
    echo -e "${CYAN}Or use System Settings > Colors & Themes > Login Screen (SDDM)${NC}"
}

# Main
main() {
    print_header "Bitpunk KDE Theme Installer"
    echo "This script will install the Bitpunk theme for KDE Plasma."
    echo ""

    detect_distro
    check_dependencies
    detect_sensors
    install_theme

    if [ "$SKIP_CURSOR" = false ]; then
        install_cursor
    else
        print_warning "Skipping cursor theme installation (--skip-cursor)"
    fi

    if [ "$SKIP_PAPIRUS" = false ]; then
        install_papirus_folders
    else
        print_warning "Skipping papirus-folders configuration (--skip-papirus)"
    fi

    if [ "$SKIP_APPLY" = false ]; then
        apply_theme
    else
        print_warning "Skipping theme application (--skip-apply)"
    fi

    print_sddm_instructions

    print_header "Installation Complete!"
    echo -e "You may need to ${CYAN}log out and back in${NC} for all changes to take effect."
    echo ""
    echo "To restart conky manually:"
    echo "  killall conky; conky -c ~/.config/conky/bitpunk.conf &"
    echo ""
    echo -e "${CYAN}Enjoy your Bitpunk desktop!${NC}"
}

main "$@"
