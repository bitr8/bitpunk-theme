#!/bin/bash
# Install Bitpunk SDDM theme
# NOTE: SDDM themes must be installed system-wide to /usr/share/sddm/themes/
# This script outputs the commands to run - execute them manually with sudo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"
DEST_DIR="/usr/share/sddm/themes/Bitpunk"

echo "============================================"
echo "Bitpunk SDDM Theme Installation"
echo "============================================"
echo ""
echo "SDDM themes must be installed system-wide."
echo "Run these commands in another terminal:"
echo ""
echo "# 1. Copy theme files to system directory:"
echo "sudo cp -r $SOURCE_DIR /usr/share/sddm/themes/"
echo ""
echo "# 2. Create SDDM config to use the theme:"
echo "sudo mkdir -p /etc/sddm.conf.d"
echo "sudo tee /etc/sddm.conf.d/theme.conf << 'EOF'"
echo "[Theme]"
echo "Current=Bitpunk"
echo "EOF"
echo ""
echo "# 3. (Optional) Test theme without logging out:"
echo "sddm-greeter-qt6 --test-mode --theme $DEST_DIR"
echo ""
echo "Theme will be active on next login/reboot."
echo "============================================"
