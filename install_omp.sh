#!/bin/bash

# Oh My Posh - Smart Setup & Auto-Updater (Linux Version)
# Optimized for Bash & Zsh with Single-Theme Policy

set -e

# --- Configuration ---
THEME_DIR="$HOME/.terminal-theme"
BIN_DIR="$HOME/.local/bin"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure directories exist
mkdir -p "$THEME_DIR"
mkdir -p "$BIN_DIR"

# Add local bin to PATH for the current session if not there
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
fi

echo "========================================"
echo " Oh My Posh - Linux Smart Setup"
echo "========================================"
echo

# --- Step 0: Asset Discovery & Download ---
check_assets() {
    if [[ -d "$BASE_DIR/Themes" && -d "$BASE_DIR/Fonts" ]]; then
        return 0
    fi
    return 1
}

download_assets() {
    echo "[INFO] Assets missing. Initializing automated download..."
    mkdir -p "$BASE_DIR/Themes" "$BASE_DIR/Fonts"
    
    local themes=("jandedobbeleer" "paradox" "agnoster" "amro" "half-life" "bubbles" "cert" "clean-detailed" "spaceship" "powerlevel10k_classic")
    local fonts=("Meslo" "CascadiaCode" "JetBrainsMono" "FiraCode" "Hack" "SourceCodePro" "Ubuntu" "Agave" "AnonymousPro")

    echo "--- Downloading Themes ---"
    for t in "${themes[@]}"; do
        echo "  Fetching theme: $t..."
        curl -sL "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$t.omp.json" -o "$BASE_DIR/Themes/$t.omp.json"
    done

    echo "--- Downloading & Pruning Fonts ---"
    for f in "${fonts[@]}"; do
        local fdir="$BASE_DIR/Fonts/$f"
        if [ ! -d "$fdir" ]; then
            echo "  Processing Font: $f..."
            curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$f.zip" -o "$f.zip"
            mkdir -p "$fdir"
            unzip -q "$f.zip" -d "$fdir"
            rm "$f.zip"
            
            # Pruning logic
            find "$fdir" -type f ! -name "*Regular*" ! -name "*Bold*" ! -name "*Italic*" -delete
            find "$fdir" -type f -name "*Propo*" -delete
            find "$fdir" -type f -name "*Windows*" -delete
        fi
    done
}

if ! check_assets; then
    download_assets
fi

# --- STEP 1: Main Menu ---
show_menu() {
    echo "[STEP 1/4] Select Configuration Option:"
    echo "1) Full Installation (Bash + Zsh)"
    echo "2) Only Bash"
    echo "3) Only Zsh"
    echo "4) Change Theme Only"
    echo "5) Install Fonts Only"
    echo
    read -p "Enter choice (1-5): " CHOICE
}

show_menu

DO_BASH=0
DO_ZSH=0
SKIP_APPS=0
SKIP_THEMES=0
SKIP_FONTS=0

case $CHOICE in
    1) DO_BASH=1; DO_ZSH=1 ;;
    2) DO_BASH=1 ;;
    3) DO_ZSH=1 ;;
    4) DO_BASH=1; DO_ZSH=1; SKIP_APPS=1; SKIP_FONTS=1 ;;
    5) SKIP_APPS=1; SKIP_THEMES=1 ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# --- Step 1: Install/Update Binary ---
if [ "$SKIP_APPS" -eq 0 ]; then
    echo "[1/4] Checking for Oh My Posh updates..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$BIN_DIR"
fi

# --- STEP 2: Theme Selection ---
if [ "$SKIP_THEMES" -eq 0 ]; then
    clear
    echo "[STEP 2/4] Choose your Terminal Theme:"
    echo
    themes_list=("$BASE_DIR"/Themes/*.json)
    i=0
    for theme in "${themes_list[@]}"; do
        i=$((i+1))
        t_name=$(basename "$theme" .omp.json)
        echo "$i) $t_name"
    done
    echo
    read -p "Select theme # (1-$i): " T_SEL
    
    SEL_THEME="${themes_list[$((T_SEL-1))]}"
    
    # Single Theme Policy: Clear and Copy
    rm -f "$THEME_DIR"/*.json
    cp "$SEL_THEME" "$THEME_DIR/active.omp.json"
    echo "Applied: $(basename "$SEL_THEME")"
fi

# --- STEP 3: Font Selection ---
if [ "$SKIP_FONTS" -eq 0 ]; then
    clear
    echo "[STEP 3/4] Choose a Font Family to Install:"
    echo
    fonts_list=("$BASE_DIR"/Fonts/*)
    echo "0) Skip Font Installation"
    i=0
    for f in "${fonts_list[@]}"; do
        i=$((i+1))
        echo "$i) $(basename "$f")"
    done
    echo
    read -p "Select font family # (0-$i): " F_SEL
    
    if [ "$F_SEL" -ne 0 ]; then
        SEL_FONT="${fonts_list[$((F_SEL-1))]}"
        FONT_INSTALL_DIR="$HOME/.local/share/fonts/oh-my-posh"
        mkdir -p "$FONT_INSTALL_DIR"
        cp "$SEL_FONT"/*.ttf "$FONT_INSTALL_DIR/" || cp "$SEL_FONT"/*.otf "$FONT_INSTALL_DIR/"
        echo "Updating font cache..."
        fc-cache -f "$FONT_INSTALL_DIR"
        echo "Font Installed."
    fi
fi

# --- STEP 4: Finalize Configurations ---
if [ "$SKIP_THEMES" -eq 0 ]; then
    echo "[4/4] Updating shell profiles..."
    
    INIT_COMMAND="eval \"\$(oh-my-posh init bash --config $THEME_DIR/active.omp.json)\""
    ZSH_INIT="eval \"\$(oh-my-posh init zsh --config $THEME_DIR/active.omp.json)\""

    update_profile() {
        local file="$1"
        local cmd="$2"
        if [ -f "$file" ]; then
            # Remove old OMP lines
            sed -i '/oh-my-posh init/d' "$file"
            echo "$cmd" >> "$file"
            echo "  Updated: $file"
        fi
    }

    [ "$DO_BASH" -eq 1 ] && update_profile "$HOME/.bashrc" "$INIT_COMMAND"
    [ "$DO_ZSH" -eq 1 ] && update_profile "$HOME/.zshrc" "$ZSH_INIT"
fi

echo
echo "========================================"
echo " Setup Complete! Restart your terminal or run:"
echo " source ~/.bashrc (or ~/.zshrc)"
echo "========================================"
