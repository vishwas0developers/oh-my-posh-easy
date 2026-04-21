import os

# Configuration
FONT_DIR = "Fonts"
# Essential styles we want to keep
ESSENTIAL_STYLES = ["Regular", "Bold", "Italic", "BoldItalic"]
# Redundant variations we want to purge
EXCLUDE_KEYWORDS = ["Propo", "Windows", "Thin", "Extra", "Light", "Semi", "Condensed", "Oblique"]

def deep_cleanup():
    if not os.path.exists(FONT_DIR):
        print(f"[ERROR] '{FONT_DIR}' folder not found in the current directory.")
        return

    print(f"--- Starting Detailed Font Cleanup in '{FONT_DIR}' ---")
    
    # Iterate through each font family folder
    for family in os.listdir(FONT_DIR):
        family_path = os.path.join(FONT_DIR, family)
        
        if not os.path.isdir(family_path):
            continue
            
        print(f"Processing Family: {family}...")
        all_items = os.listdir(family_path)
        keepers = []

        # Step 1: Identify high-quality Keepers (Nerd Font Mono + Essentials)
        # We prioritize "Mono" for terminal use as it prevents layout breakage
        for item in all_items:
            # We only care about font files
            if item.lower().endswith(('.ttf', '.otf')):
                # Check for "Mono" and the 4 essential styles
                if "Mono" in item and any(style in item for style in ESSENTIAL_STYLES):
                    # Ensure it's not a redundant variation
                    if not any(ex in item for ex in EXCLUDE_KEYWORDS):
                        keepers.append(item)

        # Step 2: Fallback if no "Mono" was found
        if not keepers:
            for item in all_items:
                if item.lower().endswith(('.ttf', '.otf')):
                    if any(style in item for style in ESSENTIAL_STYLES):
                        if not any(ex in item for ex in EXCLUDE_KEYWORDS):
                            keepers.append(item)

        # Step 3: Safety limit - Keep only unique essential styles (max ~6 per folder)
        # Sort them so we pick consistently
        keepers.sort()
        # Some families have 'Mono Regular', 'Mono Bold', etc. We keep the top ones.
        final_keepers = keepers[:8]  # Limit to 8 tops

        # Step 4: Delete everything else (Non-essential fonts AND junk files)
        deleted_count = 0
        for item in all_items:
            if item not in final_keepers:
                item_full_path = os.path.join(family_path, item)
                try:
                    if os.path.isfile(item_full_path):
                        os.remove(item_full_path)
                    elif os.path.isdir(item_full_path):
                        import shutil
                        shutil.rmtree(item_full_path)
                    deleted_count += 1
                except Exception as e:
                    print(f"  [!] Could not delete {item}: {e}")

        print(f"  Done. Kept {len(final_keepers)} essential fonts, removed {deleted_count} junk files.")

    print("\n--- Deep Cleanup Finished! ---")
    print("Folders are now clean, optimized, and ready for terminal use.")

if __name__ == "__main__":
    deep_cleanup()
