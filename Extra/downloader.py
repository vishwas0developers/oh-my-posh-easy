import os
import requests
import zipfile
import shutil

# --- CONFIGURATION ---
THEMES = [
    "jandedobbeleer", "paradox", "agnoster", "amro", "half-life",
    "bubbles", "cert", "clean-detailed", "spaceship", "powerlevel10k_classic"
]

FONTS = [
    "Meslo", "CascadiaCode", "JetBrainsMono", "FiraCode", "Hack",
    "SourceCodePro", "Ubuntu", "Agave", "AnonymousPro"
]

BASE_URL_THEME = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/{}.omp.json"
BASE_URL_FONT = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/{}.zip"

THEME_DIR = "Themes"
FONT_DIR = "Fonts"

# Keywords for essential fonts
ESSENTIAL_KEYWORDS = ["Regular", "Bold", "Italic", "BoldItalic", "Nerd Font Mono"]
EXCLUDE_KEYWORDS = ["Propo", "Windows Compatible", "Thin", "ExtraLight", "Light", "SemiBold", "SemiLight", "Condensed"]

def download_file(url, dest):
    try:
        response = requests.get(url, stream=True, timeout=30)
        if response.status_code == 200:
            with open(dest, 'wb') as f:
                shutil.copyfileobj(response.raw, f)
            return True
    except Exception as e:
        print(f"Error downloading {url}: {e}")
    return False

def prune_fonts(folder):
    files = [f for f in os.listdir(folder) if f.endswith(('.ttf', '.otf'))]
    to_keep = []
    
    # Priority 1: Pick Mono versions with essential styles
    for f in files:
        if "Mono" in f:
            if any(k in f for k in ["Regular", "Bold", "Italic"]):
                if not any(ex in f for ex in EXCLUDE_KEYWORDS):
                    to_keep.append(f)
                    
    # Priority 2: If we don't have enough, pick non-mono essential styles
    if len(to_keep) < 4:
        for f in files:
            if f not in to_keep:
                if any(k in f for k in ["Regular", "Bold", "Italic"]):
                    if not any(ex in f for ex in EXCLUDE_KEYWORDS):
                        to_keep.append(f)

    # Delete others
    for f in files:
        if f not in to_keep:
            try:
                os.remove(os.path.join(folder, f))
            except:
                pass
    print(f"  Pruned {folder}: Kept {len(to_keep)} essential fonts.")

def main():
    if not os.path.exists(THEME_DIR): os.makedirs(THEME_DIR)
    if not os.path.exists(FONT_DIR): os.makedirs(FONT_DIR)

    print("--- Downloading Top 10 Themes ---")
    for theme in THEMES:
        filename = f"{theme}.omp.json"
        dest = os.path.join(THEME_DIR, filename)
        if not os.path.exists(dest):
            print(f" Downloading theme: {theme}...")
            download_file(BASE_URL_THEME.format(theme), dest)

    print("\n--- Downloading & Pruning Top 9 Font Families ---")
    for font in FONTS:
        dest_zip = os.path.join(FONT_DIR, f"{font}.zip")
        dest_folder = os.path.join(FONT_DIR, font)
        
        if not os.path.exists(dest_folder):
            print(f" Processing Font: {font}...")
            if download_file(BASE_URL_FONT.format(font), dest_zip):
                os.makedirs(dest_folder, exist_ok=True)
                with zipfile.ZipFile(dest_zip, 'r') as zip_ref:
                    zip_ref.extractall(dest_folder)
                os.remove(dest_zip)
                prune_fonts(dest_folder)
            else:
                print(f" Failed to download {font}")

    print("\nAssets collection complete.")

if __name__ == "__main__":
    main()
