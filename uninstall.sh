#!/bin/bash
#
# Cyberpunk 2077 KDE Theme Uninstaller
# Removes all theme components installed by install.sh
#

set -e

THEME_NAME="Cyberpunk2077"

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

print_header "Cyberpunk 2077 Theme Uninstaller"

echo "This will remove the following:"
echo "  - KDE colour scheme: Cyberpunk2077"
echo "  - Plasma desktop theme: Cyberpunk2077"
echo "  - Konsole theme and profile"
echo "  - GTK theme: Cyberpunk2077"
echo "  - Conky config and autostart"
echo "  - Wallpaper"
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

print_header "Removing Theme Files"

# Stop conky
print_step "Stopping conky..."
killall conky 2>/dev/null || true

# Remove KDE colour scheme
print_step "Removing KDE colour scheme..."
rm -f ~/.local/share/color-schemes/Cyberpunk2077.colors
print_success "Colour scheme removed"

# Remove Plasma desktop theme
print_step "Removing Plasma desktop theme..."
rm -rf ~/.local/share/plasma/desktoptheme/Cyberpunk2077
print_success "Desktop theme removed"

# Remove Konsole theme
print_step "Removing Konsole theme..."
rm -f ~/.local/share/konsole/Cyberpunk2077.colorscheme
rm -f ~/.local/share/konsole/Cyberpunk2077.profile
print_success "Konsole theme removed"

# Remove Kitty config (backup first)
if [ -f ~/.config/kitty/kitty.conf ]; then
    print_step "Backing up and removing Kitty config..."
    cp ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.cyberpunk-backup
    rm -f ~/.config/kitty/kitty.conf
    print_success "Kitty config removed (backup at kitty.conf.cyberpunk-backup)"
fi

# Remove GTK theme
print_step "Removing GTK theme..."
rm -rf ~/.themes/Cyberpunk2077
print_success "GTK theme removed"

# Remove conky config
print_step "Removing conky config..."
rm -f ~/.config/conky/cyberpunk2077.conf
rm -f ~/.config/autostart/conky-cyberpunk2077.desktop
print_success "Conky config removed"

# Remove wallpaper
print_step "Removing wallpaper..."
rm -f ~/.config/conky/wallpaper-cyberpunk2077.jpg
print_success "Wallpaper removed"

# Reset to default theme
print_header "Resetting to Default Theme"

print_step "Applying Breeze colour scheme..."
plasma-apply-colorscheme BreezeClassic 2>/dev/null || plasma-apply-colorscheme BreezeDark 2>/dev/null || true

print_step "Applying Breeze desktop theme..."
plasma-apply-desktoptheme breeze-dark 2>/dev/null || plasma-apply-desktoptheme default 2>/dev/null || true

print_step "Refreshing KWin..."
$QDBUS_CMD org.kde.KWin /KWin reconfigure 2>/dev/null || true

print_header "Uninstallation Complete"

echo "Theme removed. You may want to:"
echo ""
echo "1. Set a new wallpaper in System Settings"
echo "2. Reset Konsole to default profile"
echo "3. Remove SDDM theme manually:"
echo "   sudo rm -rf /usr/share/sddm/themes/Cyberpunk2077"
echo "   sudo rm -f /etc/sddm.conf.d/theme.conf"
echo ""
echo "Log out and back in for all changes to take effect."
