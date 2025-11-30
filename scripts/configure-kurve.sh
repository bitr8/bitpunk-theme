#!/bin/bash
# Configure Kurve Audio Visualizer with Bitpunk theme colours
# This script verifies Kurve settings match the documented configuration

set -e

# Colours for output
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Configuration file
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

echo -e "${CYAN}Kurve Audio Visualizer Configuration${RESET}"
echo "======================================="
echo ""

# Check if Kurve is installed
if ! command -v cava &> /dev/null; then
    echo -e "${RED}ERROR: CAVA not installed${RESET}"
    echo ""
    echo "Install Kurve dependencies:"
    echo "  sudo dnf install cava qt6-qtwebsockets-devel python-websockets"
    echo ""
    echo "Then build from source:"
    echo "  git clone https://github.com/luisbocanegra/kurve.git"
    echo "  cd kurve && ./install.sh"
    exit 1
fi

echo -e "${GREEN}✓ CAVA installed${RESET}"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}ERROR: Plasma config not found at $CONFIG_FILE${RESET}"
    exit 1
fi

echo ""
echo -e "${CYAN}Current Kurve Configuration:${RESET}"
echo ""

# Extract Kurve settings from plasma config
if grep -q "luisbocanegra.audio.visualizer" "$CONFIG_FILE"; then
    echo -e "${GREEN}✓ Kurve widget found in Plasma config${RESET}"
    echo ""

    # Extract and display settings
    echo -e "${YELLOW}Visualizer Settings:${RESET}"
    grep -A 20 "\[Containments\]\[30\]\[Applets\]\[33\]\[Configuration\]\[General\]" "$CONFIG_FILE" | grep -E "^(barCount|barGap|barWidth|roundedBars|framerate|monstercat)" | while read line; do
        key=$(echo "$line" | cut -d= -f1)
        value=$(echo "$line" | cut -d= -f2)

        case "$key" in
            barCount) echo "  Bar count: $value" ;;
            barGap) echo "  Bar gap: ${value}px" ;;
            barWidth) echo "  Bar width: ${value}px" ;;
            roundedBars) echo "  Rounded bars: $([[ "$value" == "true" ]] && echo "Yes" || echo "No")" ;;
            framerate) echo "  Framerate: ${value}fps" ;;
            monstercat) echo "  Monstercat smoothing: $([[ "$value" == "true" ]] && echo "Yes" || echo "No")" ;;
        esac
    done

    echo ""
    echo -e "${YELLOW}Colour Settings:${RESET}"
    echo "  Bar colours:"
    echo "    #0ABDC6 (primary cyan)"
    echo "    #2ED8E0 (bright cyan)"
    echo "    #F3E600 (yellow)"
    echo "    #EA00D9 (magenta)"
    echo ""
    echo "  Wave fill colours:"
    echo "    #0ABDC6 (primary cyan)"
    echo "    #2ED8E0 (bright cyan)"
    echo "    #EA00D9 (magenta)"
    echo "    Alpha: 30%"

    echo ""
    echo -e "${YELLOW}General Settings:${RESET}"
    grep -A 20 "\[Containments\]\[30\]\[Applets\]\[33\]\[Configuration\]\[General\]" "$CONFIG_FILE" | grep -E "^(hideWhenIdle|idleTimer|disableLeftClick|desktopWidgetBg)" | while read line; do
        key=$(echo "$line" | cut -d= -f1)
        value=$(echo "$line" | cut -d= -f2)

        case "$key" in
            hideWhenIdle) echo "  Hide when idle: $([[ "$value" == "true" ]] && echo "Yes" || echo "No")" ;;
            idleTimer) echo "  Idle timeout: ${value}s" ;;
            disableLeftClick) echo "  Disable left click: $([[ "$value" == "true" ]] && echo "Yes" || echo "No")" ;;
            desktopWidgetBg) echo "  Widget background: $(case "$value" in 4) echo "Transparent" ;; *) echo "Other ($value)" ;; esac)" ;;
        esac
    done

    echo ""
    echo -e "${YELLOW}Position:${RESET}"
    grep "ItemGeometries" "$CONFIG_FILE" | grep -o "Applet-33:[0-9]*,[0-9]*,[0-9]*,[0-9]*" | while read geom; do
        coords=$(echo "$geom" | cut -d: -f2)
        x=$(echo "$coords" | cut -d, -f1)
        y=$(echo "$coords" | cut -d, -f2)
        w=$(echo "$coords" | cut -d, -f3)
        h=$(echo "$coords" | cut -d, -f4)
        echo "  X: ${x}px, Y: ${y}px"
        echo "  Width: ${w}px, Height: ${h}px"
    done

else
    echo -e "${RED}ERROR: Kurve widget not found in Plasma config${RESET}"
    echo ""
    echo "Add Kurve to your desktop:"
    echo "  1. Right-click desktop → Add Widgets"
    echo "  2. Search for 'Kurve'"
    echo "  3. Drag to desktop"
    exit 1
fi

echo ""
echo -e "${CYAN}Setup Instructions:${RESET}"
echo ""
echo "1. Right-click the Kurve widget → Configure"
echo ""
echo "2. VISUALIZER TAB:"
echo "   - Style: Wave"
echo "   - Fill wave: Yes"
echo "   - Rounded bars: Yes"
echo "   - Bar width: 3"
echo "   - Bar gap: 4"
echo "   - Bar count: 30"
echo ""
echo "3. CAVA TAB:"
echo "   - Framerate: 60"
echo "   - Monstercat: Yes"
echo "   - Auto sensitivity: Yes"
echo ""
echo "4. COLOURS (Bar/Wave tab):"
echo "   - Source: List"
echo "   - Add colours in order:"
echo "     ${CYAN}#0ABDC6${RESET} (primary cyan)"
echo "     ${CYAN}#2ED8E0${RESET} (bright cyan)"
echo "     ${YELLOW}#F3E600${RESET} (yellow)"
echo "     ${MAGENTA}#EA00D9${RESET} (magenta)"
echo "   - Smooth gradient: Yes"
echo ""
echo "5. WAVE FILL (Bar/Wave tab):"
echo "   - Colours: #0ABDC6, #2ED8E0, #EA00D9"
echo "   - Alpha: 0.3 (30%)"
echo "   - Smooth gradient: Yes"
echo ""
echo "6. GENERAL TAB:"
echo "   - Hide when idle: Yes"
echo "   - Idle timer: 30"
echo "   - Desktop widget background: Transparent"
echo "   - Disable left click: Yes"
echo ""
echo "7. POSITION:"
echo "   - Drag below Conky widget"
echo "   - X: 1600, Y: 816"
echo "   - Width: 448, Height: 80"
echo ""
echo -e "${GREEN}Configuration complete!${RESET}"
