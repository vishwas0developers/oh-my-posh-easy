# Oh My Posh - Windows ASCII Terminal Setup

A robust, one-click solution for configuring **Oh My Posh** on Windows, supporting both **PowerShell 5.1/7+** and **Command Prompt (CMD)** via Clink. This setup is designed with a high-contrast, 100% ASCII-only theme to ensure zero garbled characters out of the box, with an easy path to upgrade to full icon-based themes.

## 🚀 Features

- **Dual-Shell Support**: Configures both PowerShell and CMD (via Clink).
- **One-Click Installation**: Automatic installation of Oh My Posh and Clink using `winget`.
- **ASCII-Only Theme**: No special fonts required for the default setup. Uses plain `>` and `-` characters.
- **Centralized Storage**: All configuration and theme files are stored in `C:\Terminal Theme` for easy access.
- **Robust Uninstaller**: Complete cleanup of registry keys, profile lines, and configuration folders.

---

## 🛠️ Installation

1.  Download `install_omp.bat` and `uninstall_omp.bat`.
2.  Right-click `install_omp.bat` and select **Run as Administrator**.
3.  Choose your setup option:
    -   `[1]` PowerShell + CMD (Full Installation)
    -   `[2]` Only PowerShell
    -   `[3]` Only CMD
4.  **Restart your Terminal** (CMD or PowerShell) to see the changes.

---

## 🎨 Theme Customization

The default setup uses a "Plain ASCII" theme located at:
`C:\Terminal Theme\.oh-my-posh-plain.omp.json`

### Finding More Themes
Oh My Posh has an extensive gallery of built-in and community themes.
-   **Official Themes Gallery**: [ohmyposh.dev/docs/themes](https://ohmyposh.dev/docs/themes)
-   **Live Preview**: You can test any built-in theme in a live session by running:
    ```powershell
    oh-my-posh init pwsh --config ~\.oh-my-posh\themes\jandedobbeleer.omp.json | Invoke-Expression
    ```

### How to Replace the Theme
1.  Find a theme you like from the [Gallery](https://ohmyposh.dev/docs/themes).
2.  Download the `.omp.json` file.
3.  Replace the contents of `C:\Terminal Theme\.oh-my-posh-plain.omp.json` with the new JSON.
4.  Restart your terminal.

---

## 🔣 Fixing Garbled Characters (Glyphs/Icons)

If you switch to a theme that uses icons (like the `jandedobbeleer` or `paradox` themes) and see **boxes (☐)** or **question marks (?)**, it means your font does not support the required glyphs.

### The Solution: Nerd Fonts
To fix this, you must install a **Nerd Font**:
1.  Go to **[nerdfonts.com](https://www.nerdfonts.com/font-downloads)**.
2.  Download a font (Recommended: *MesloLGM NF* or *Cascadia Code NF*).
3.  Install the font on Windows.
4.  **Change Terminal Settings**:
    -   **Windows Terminal**: `Settings` > `Profiles` > `Defaults` > `Appearance` > `Font face` > Select your Nerd Font.
    -   **VS Code**: `Settings` > Search for `terminal.integrated.fontFamily` > Set to the font name (e.g., `'MesloLGM NF'`).

---

## 📄 Documentation & Links

-   **Official Documentation**: [ohmyposh.dev/docs](https://ohmyposh.dev/docs/)
-   **Installation Guide**: [ohmyposh.dev/docs/installation/windows](https://ohmyposh.dev/docs/installation/windows)
-   **Font Setup**: [ohmyposh.dev/docs/installation/fonts](https://ohmyposh.dev/docs/installation/fonts)
-   **Troubleshooting**: [Github Issues](https://github.com/JanDeDobbeleer/oh-my-posh/issues)

---

## 🗑️ Uninstallation

Run `uninstall_omp.bat` as Administrator.
-   It will provide options to remove only specific shell configurations or perform a full system wipe (uninstalling apps and deleting all theme folders).
-   If you encounter a "CMD Hang" issue, run the uninstaller first—it includes an emergency registry cleanup step.
