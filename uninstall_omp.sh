#!/bin/bash

# Oh My Posh - Smart Uninstaller (Linux Version)

set -e

THEME_DIR="$HOME/.terminal-theme"
BIN_DIR="$HOME/.local/bin"
FONT_INSTALL_DIR="$HOME/.local/share/fonts/oh-my-posh"

echo "========================================"
echo " Oh My Posh - Linux Uninstaller"
echo "========================================"
echo

echo "Select uninstallation scope:"
echo "1) Full Cleanup (Apps + Configs + Themes)"
echo "2) Only Shell Profiles"
echo "3) Only Themes/Fonts"
echo
read -p "Enter choice (1-3): " CHOICE

cleanup_profiles() {
    echo "Cleaning shell profiles..."
    for file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$file" ]; then
            sed -i '/oh-my-posh init/d' "$file"
            echo "  Cleaned: $file"
        fi
    done
}

cleanup_assets() {
    echo "Removing Themes and Fonts..."
    rm -rf "$THEME_DIR"
    rm -rf "$FONT_INSTALL_DIR"
    if command -v fc-cache &> /dev/null; then
        fc-cache -f
    fi
}

cleanup_apps() {
    echo "Removing Oh My Posh binary..."
    rm -f "$BIN_DIR/oh-my-posh"
}

case $CHOICE in
    1)
        cleanup_apps
        cleanup_assets
        cleanup_profiles
        ;;
    2)
        cleanup_profiles
        ;;
    3)
        cleanup_assets
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo
echo "========================================"
echo " Cleanup Successful!"
echo "========================================"
