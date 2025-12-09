#!/bin/bash
#
# Bitpunk KDE Theme Uninstaller
# Removes all theme components installed by install.sh
#

set -euo pipefail

THEME_NAME="Bitpunk"

# Colours for output
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Detect qdbus command
if command -v qdbus6 &> /dev/null; then
    QDBUS_CMD="qdbus6"
elif command -v qdbus-qt6 &> /dev/null; then
    QDBUS_CMD="qdbus-qt6"
else
    QDBUS_CMD="qdbus"
fi

# Restore Papirus folder colours to default
restore_papirus_folders() {
    print_step "Restoring Papirus folder colours..."
    if command -v papirus-folders &> /dev/null; then
        papirus-folders --restore --theme Papirus-Dark 2>/dev/null || true
        print_success "Papirus folder colours restored to default"
    else
        print_warning "papirus-folders not found, skipping folder colour restore"
    fi
}

print_header "Bitpunk Theme Uninstaller"

echo "This will remove the following:"
echo "  - KDE colour scheme: Bitpunk"
echo "  - Plasma desktop theme: Bitpunk"
echo "  - Splash screen: Bitpunk"
echo "  - Konsole theme and profile"
echo "  - GTK theme: Bitpunk"
echo "  - Kitty config"
echo "  - Ghostty config"
echo "  - Conky config and autostart"
echo "  - Wallpaper"
echo "  - Papirus folder colour (restored to default blue)"
echo ""
echo -e "${YELLOW}Note: Cursor theme (Bibata-Modern-Ice) will NOT be removed.${NC}"
echo -e "${YELLOW}Note: SDDM theme requires manual removal with sudo.${NC}"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Restore Papirus folder colours first
restore_papirus_folders

print_header "Removing Theme Files"

# Stop conky
print_step "Stopping conky..."
killall conky 2>/dev/null || true

# Remove KDE colour scheme
print_step "Removing KDE colour scheme..."
rm -f ~/.local/share/color-schemes/Bitpunk.colors
print_success "Colour scheme removed"

# Remove Plasma desktop theme
print_step "Removing Plasma desktop theme..."
rm -rf ~/.local/share/plasma/desktoptheme/Bitpunk
print_success "Desktop theme removed"

# Remove splash screen
print_step "Removing splash screen..."
rm -rf ~/.local/share/plasma/look-and-feel/com.github.bitpunk.splash
print_success "Splash screen removed"

# Remove Konsole theme
print_step "Removing Konsole theme..."
rm -f ~/.local/share/konsole/Bitpunk.colorscheme
rm -f ~/.local/share/konsole/Bitpunk.profile
print_success "Konsole theme removed"

# Remove Kitty config (backup first)
if [ -f ~/.config/kitty/kitty.conf ]; then
    print_step "Backing up and removing Kitty config..."
    cp ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.bitpunk-backup
    rm -f ~/.config/kitty/kitty.conf
    print_success "Kitty config removed (backup at kitty.conf.bitpunk-backup)"
fi

# Remove Ghostty config (backup first)
if [ -f ~/.config/ghostty/config ]; then
    print_step "Backing up and removing Ghostty config..."
    cp ~/.config/ghostty/config ~/.config/ghostty/config.bitpunk-backup
    rm -f ~/.config/ghostty/config
    print_success "Ghostty config removed (backup at config.bitpunk-backup)"
fi

# Remove GTK theme
print_step "Removing GTK theme..."
rm -rf ~/.themes/Bitpunk
print_success "GTK theme removed"

# Remove conky config
print_step "Removing conky config..."
rm -f ~/.config/conky/bitpunk.conf
rm -f ~/.config/autostart/conky-bitpunk.desktop
print_success "Conky config removed"

# Remove wallpaper
print_step "Removing wallpaper..."
rm -f ~/.config/conky/wallpaper-bitpunk.jpg
print_success "Wallpaper removed"

# Reset to default theme
print_header "Resetting to Default Theme"

print_step "Applying Breeze colour scheme..."
plasma-apply-colorscheme BreezeClassic 2>/dev/null || plasma-apply-colorscheme BreezeDark 2>/dev/null || true

print_step "Applying Breeze desktop theme..."
plasma-apply-desktoptheme breeze-dark 2>/dev/null || plasma-apply-desktoptheme default 2>/dev/null || true

print_step "Resetting splash screen to default..."
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop 2>/dev/null || true

print_step "Refreshing KWin..."
$QDBUS_CMD org.kde.KWin /KWin reconfigure 2>/dev/null || true

print_header "Uninstallation Complete"

echo "Theme removed. You may want to:"
echo ""
echo "1. Set a new wallpaper in System Settings"
echo "2. Reset Konsole to default profile"
echo "3. Remove SDDM theme manually:"
echo "   sudo rm -rf /usr/share/sddm/themes/Bitpunk"
echo "   sudo rm -f /etc/sddm.conf.d/theme.conf"
echo ""
echo "Log out and back in for all changes to take effect."
