@echo off
setlocal EnableDelayedExpansion

:: Set encoding to UTF-8
chcp 65001 >nul

:: Elevation Check (Font install requires it)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run this script as Administrator.
    pause
    exit /b 1
)

echo ========================================
echo Oh My Posh - Dynamic Setup Wizard
echo ========================================
echo.

:: Define Global Paths
set "BASE_DIR=%~dp0"
set "THEME_DIR=C:\Terminal Theme"
set "THEMES_STORAGE=%THEME_DIR%\Themes"

:: Step 0: Ensure Directory Structure
if not exist "%THEME_DIR%" mkdir "%THEME_DIR%"
if not exist "%THEMES_STORAGE%" mkdir "%THEMES_STORAGE%"

:: Sync Local Themes to System Directory
if exist "%BASE_DIR%Themes" (
    echo Syncing local themes to %THEMES_STORAGE%...
    xcopy /Y /Q /E "%BASE_DIR%Themes\*" "%THEMES_STORAGE%\" >nul
)

:menu_shell
echo [STEP 1/3] Select Shell Configuration:
echo [1] PowerShell + CMD (Full Installation)
echo [2] Only PowerShell
echo [3] Only CMD
echo.
set /p "CHOICE_SHELL=Enter choice (1-3): "

if "%CHOICE_SHELL%"=="" set "CHOICE_SHELL=1"
if "%CHOICE_SHELL%"=="1" ( set "DO_PS=1" & set "DO_CMD=1" ) else if "%CHOICE_SHELL%"=="2" ( set "DO_PS=1" & set "DO_CMD=0" ) else if "%CHOICE_SHELL%"=="3" ( set "DO_PS=0" & set "DO_CMD=1" ) else ( echo Invalid choice. & goto menu_shell )

:: 1. Core Apps Installation
cls
echo [1/3] Checking Core Dependencies...
oh-my-posh --version >nul 2>&1
if !errorlevel! neq 0 (
    echo Installing Oh My Posh via winget...
    winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements
    timeout /t 3 /nobreak >nul
)

if "%DO_CMD%"=="1" (
    clink --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo Installing Clink via winget...
        winget install chrisant996.clink --accept-package-agreements --accept-source-agreements
    )
)

:: Step 2: Dynamic Theme Selection
cls
echo [STEP 2/3] Choose your Terminal Theme:
echo.

:: Build Dynamic Menu from C:\Terminal Theme\Themes
set "count=0"
for %%f in ("%THEMES_STORAGE%\*.json") do (
    set /a "count+=1"
    set "theme_!count!=%%~nxf"
    echo [!count!] %%~nf
)

if %count% equ 0 (
    echo [WARNING] No themes found in %THEMES_STORAGE%. 
    echo Please ensure the "Themes" folder contains .json files.
    pause
    goto finish_setup
)

echo.
set /p "CHOICE_THEME=Select theme number (1-%count%): "

if not defined theme_%CHOICE_THEME% (
    echo Invalid selection.
    pause
    goto start_install
)

set "SELECTED_THEME_FILE=!theme_%CHOICE_THEME%!"
set "ACTIVE_THEME=%THEME_DIR%\active.omp.json"
copy /Y "%THEMES_STORAGE%\%SELECTED_THEME_FILE%" "%ACTIVE_THEME%" >nul
echo Theme "!SELECTED_THEME_FILE!" activated.

:: Step 3: Font Installation Prompt
cls
echo [STEP 3/3] Font Installation:
echo.
set /p "INSTALL_FONT=Do you want to install the JetBrainsMono Nerd Font? (Y/N): "

if /i "%INSTALL_FONT%"=="Y" (
    if exist "%BASE_DIR%JetBrainsMono.zip" (
        echo Extracting and Installing Fonts...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Extracting Zip...'; $tempPath = Join-Path $env:TEMP 'OMP_Fonts'; if (Test-Path $tempPath) { Remove-Item $tempPath -Recurse -Force }; New-Item -Path $tempPath -ItemType Directory | Out-Null; Expand-Archive -Path '%BASE_DIR%JetBrainsMono.zip' -DestinationPath $tempPath -Force; $fonts = Get-ChildItem -Path $tempPath -Filter *.ttf -Recurse; $fontFolder = [System.Environment]::GetFolderPath('Fonts'); foreach($font in $fonts) { $target = Join-Path $fontFolder $font.Name; if (-not (Test-Path $target)) { Copy-Item $font.FullName $target; $keyPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'; $valueName = $font.BaseName + ' (TrueType)'; Set-ItemProperty -Path $keyPath -Name $valueName -Value $font.Name -Force; Write-Host 'Installed: ' $font.Name } else { Write-Host 'Already exists: ' $font.Name } }; Remove-Item $tempPath -Recurse -Force; Write-Host 'Font installation completed!'"
    ) else (
        echo [ERROR] JetBrainsMono.zip not found in %BASE_DIR%
        pause
    )
)

:: Final Configuration: Profile Application
cls
echo Applying Shell Configuration...

:: 3.1 PowerShell Setup
if "%DO_PS%"=="1" (
    set "TEMP_PS=%TEMP%\omp_setup_%RANDOM%.ps1"
    echo $themePath = '%ACTIVE_THEME%' > "%TEMP_PS%"
    echo $initLine = "oh-my-posh init pwsh --config `"$themePath`" | Invoke-Expression" >> "%TEMP_PS%"
    echo $profiles = @($PROFILE, >> "%TEMP_PS%"
    echo   "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1", >> "%TEMP_PS%"
    echo   "$HOME\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1") >> "%TEMP_PS%"
    echo foreach ($p in $profiles) { >> "%TEMP_PS%"
    echo     if ($p -and (Test-Path (Split-Path $p -Parent))) { >> "%TEMP_PS%"
    echo         $dir = Split-Path $p >> "%TEMP_PS%"
    echo         if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force ^| Out-Null } >> "%TEMP_PS%"
    echo         if (-not (Test-Path $p)) { New-Item -Path $p -ItemType File -Force ^| Out-Null } >> "%TEMP_PS%"
    echo         $content = Get-Content $p -Raw -ErrorAction SilentlyContinue >> "%TEMP_PS%"
    echo         $cleaned = $content -replace '(?m)^.*oh-my-posh init.*$\r?\n?', '' >> "%TEMP_PS%"
    echo         $cleaned = $cleaned -replace '(?m)^.*Clear-Host.*$\r?\n?', '' >> "%TEMP_PS%"
    echo         Set-Content -Path $p -Value $cleaned.Trim() -Encoding UTF8 >> "%TEMP_PS%"
    echo         if (-not [string]::IsNullOrWhiteSpace($initLine)) { Add-Content -Path $p -Value "`r`n$initLine" -Encoding UTF8 } >> "%TEMP_PS%"
    echo         Add-Content -Path $p -Value "Clear-Host" -Encoding UTF8 >> "%TEMP_PS%"
    echo         Write-Host "Updated PS Profile: $p" >> "%TEMP_PS%"
    echo     } >> "%TEMP_PS%"
    echo } >> "%TEMP_PS%"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"
    if exist "%TEMP_PS%" del "%TEMP_PS%" >nul 2>&1
)

:: 3.2 CMD/Clink Setup
if "%DO_CMD%"=="1" (
    set "CMD_INIT_SCRIPT=%THEME_DIR%\init_cmd.bat"
    (
        echo @echo off
        echo cls
        echo if exist "%%ProgramFiles(x86)%%\clink\clink.bat" ^(
        echo     call "%%ProgramFiles(x86)%%\clink\clink.bat" inject --quiet --autorun
        echo ^) else if exist "%%ProgramFiles%%\clink\clink.bat" ^(
        echo     call "%%ProgramFiles%%\clink\clink.bat" inject --quiet --autorun
        echo ^) else if exist "%%LOCALAPPDATA%%\Programs\clink\clink.bat" ^(
        echo     call "%%LOCALAPPDATA%%\Programs\clink\clink.bat" inject --quiet --autorun
        echo ^)
    ) > "%CMD_INIT_SCRIPT%"
    reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "\"%CMD_INIT_SCRIPT%\"" /f >nul 2>&1
    
    :: Disable Clink Banner & AutoUpdate
    if exist "%ProgramFiles(x86)%\clink\clink.bat" (
        call "%ProgramFiles(x86)%\clink\clink.bat" set clink.logo none >nul 2>&1
        call "%ProgramFiles(x86)%\clink\clink.bat" set clink.autoupdate off >nul 2>&1
    ) else if exist "%ProgramFiles%\clink\clink.bat" (
        call "%ProgramFiles%\clink\clink.bat" set clink.logo none >nul 2>&1
        call "%ProgramFiles%\clink\clink.bat" set clink.autoupdate off >nul 2>&1
    )
    
    :: Set Clink Lua to use the active theme
    set "CLINK_DIR=%LOCALAPPDATA%\clink"
    if not exist "!CLINK_DIR!" mkdir "!CLINK_DIR!"
    echo oh-my-posh init cmd --config "%ACTIVE_THEME%" > "!CLINK_DIR!\oh-my-posh.lua" 2>nul
    echo CMD Banner Suppressed and Theme Activated.
)

:finish_setup
echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo Theme: !SELECTED_THEME_FILE!
echo Profiles updated. Please RESTART your terminal.
echo.
pause
