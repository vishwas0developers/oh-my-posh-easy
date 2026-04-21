# Oh My Posh - Smart Multi-Platform Automation (Windows & Linux)

A high-performance, automated framework for setting up and managing **Oh My Posh** across different operating systems and shells. This project eliminates manual configuration by automating binary updates, font registration, and multi-version shell profile management.

---

## 🛠️ Technology Stack & Dependencies

This automation utilizes industry-standard tools to ensure the most stable terminal experience:
- **Oh My Posh**: The core engine for terminal theming.
- **Clink**: Enhances the CMD experience on Windows with shell-like features.
- **Nerd Fonts**: Specifically curated glyph-ready font families.
- **Automation Engines**:
  - **Windows**: Batch + PowerShell 5.1/7 with Registry manipulation & Multi-encoding support.
  - **Linux**: Bash + `sed` for profile injection and `fc-cache` for font management.
- **Package Management**: Uses `winget` (Windows) and `curl` (Linux) to ensure tools are always up-to-date.

---

## ✨ Automated Features

- **Auto-Elevation**: Scripts automatically detect permissions and request Admin/Sudo access when needed.
- **Single-Theme Policy**: Zero system clutter. The system partition only stores the **active** theme file (`active.omp.json`), while the project folder acts as the master source.
- **Intelligent Font Pruning**: Automatically downloads large Nerd Font families (9 top families) but discards junk files (LICENSE, Thin, ExtraLight) to keep only essential variations.
- **Config Fixes**:
  - **Lua Escaping**: Automatic double-backslash escaping for Clink configs.
  - **Multi-Profile Sync**: Supports both Windows PowerShell (5.1) and PowerShell (7.x) simultaneously.

---

## 🚀 Usage Guidance (The Menu 1-5)

Run `install_omp.bat` (Windows) or `./install_omp.sh` (Linux) and select your mode:

| Option | Mode | What happens behind the scenes? |
| :--- | :--- | :--- |
| **[1]** | **Full Installation** | Installs OMP + Clink, prunes fonts, selects theme, and updates ALL shell profiles. |
| **[2]** | **Only PowerShell** | Skips CMD setup. Focuses on PS 5.1 and PS 7 core profiles. |
| **[3]** | **Only CMD** | Sets up Clink, suppresses banners, and injects OMP into CMD via Lua. |
| **[4]** | **Change Theme** | **FAST MODE.** Skips updates/fonts entirely. Just swaps the `active.omp.json` and updates profiles. |
| **[5]** | **Install Font Only** | Downloads selected family, installs to system fonts, and updates font cache. |

---

## 🎨 Visual Configuration (Fixing Boxes/Garbled Text)

If you see boxes instead of icons, you must set your terminal font face:
1. **Windows Terminal**: `Settings` > `Profiles` > `Defaults` > `Appearance` > `Font face` > Select a **Nerd Font** (e.g., *MesloLGM NF*).
2. **VS Code**: Under `terminal.integrated.fontFamily` set it to your installed Nerd Font name.

---

## 📄 Official Resources & Links

- **Oh My Posh Engine**: [ohmyposh.dev](https://ohmyposh.dev/)
- **Official Documentation**: [docs/installation](https://ohmyposh.dev/docs/installation/windows)
- **Built-in Themes Gallery**: [docs/themes](https://ohmyposh.dev/docs/themes)
- **Nerd Fonts Repository**: [nerdfonts.com](https://www.nerdfonts.com/)
- **Troubleshooting**: [Official Github Issues](https://github.com/JanDeDobbeleer/oh-my-posh/issues)

---

## 📁 Project Directory Map

- `install_omp.bat` / `.sh`: The main "brains" of the setup.
- `uninstall_omp.bat` / `.sh`: Complete, clean-slate removal system.
- `Themes/`: Source of all premium theme JSONs.
- `Fonts/`: Staging area for font families.

---

## 🗑️ Uninstallation Logic

Running the `uninstall` script performs a deep system cleanup:
1. **Binary Removal**: Uninstalls OMP and Clink via winget/rm.
2. **Registry Reset**: Clears the `AutoRun` keys from `HKCU\Software\Microsoft\Command Processor`.
3. **Profile Extraction**: Uses `sed` or PowerShell regex to surgically remove initialization blocks from `.bashrc`, `.zshrc`, and all PowerShell profiles without touching your other custom settings.
4. **Theme Wipe**: Deletes global configuration folders (`C:\Terminal Theme` or `~/.terminal-theme`).
