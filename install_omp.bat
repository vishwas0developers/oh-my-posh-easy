@echo off
setlocal EnableDelayedExpansion

:: Set encoding to UTF-8
chcp 65001 >nul

:: ========================================
:: AUTO-ELEVATION (Request Admin Privileges)
:: ========================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

echo ========================================
echo Oh My Posh - Smart Setup ^& Auto-Updater
echo ========================================
echo.

:: Global Paths
set "BASE_DIR=%~dp0"
set "THEME_DIR=C:\Terminal Theme"

:: Step 0: Asset Discovery ^& Automated Download
set "has_assets=0"
if exist "%BASE_DIR%Themes" if exist "%BASE_DIR%Fonts" (
    for /f %%i in ('dir /b "%BASE_DIR%Themes\*.json" 2^>nul') do set "has_assets=1"
)

if "%has_assets%"=="1" goto skip_download
echo [INFO] Assets missing. Initializing automated download...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$themes = @('jandedobbeleer', 'paradox', 'agnoster', 'amro', 'half-life', 'bubbles', 'cert', 'clean-detailed', 'spaceship', 'powerlevel10k_classic'); " ^
"$fonts = @('Meslo', 'CascadiaCode', 'JetBrainsMono', 'FiraCode', 'Hack', 'SourceCodePro', 'Ubuntu', 'Agave', 'AnonymousPro'); " ^
"New-Item -ItemType Directory -Force -Path 'Themes', 'Fonts' | Out-Null; " ^
"Write-Host '--- Downloading/Refreshing Themes ---' -ForegroundColor Cyan; " ^
"foreach($t in $themes) { $url = \"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$t.omp.json\"; $dest = \"Themes/$t.omp.json\"; Write-Host \"  Fetching theme: $t\"; Invoke-WebRequest -Uri $url -OutFile $dest }; " ^
"Write-Host '--- Collecting ^& Pruning 9 Font Families ---' -ForegroundColor Cyan; " ^
"foreach($f in $fonts) { $fDir = \"Fonts/$f\"; if (!(Test-Path $fDir)) { Write-Host \"  Processing Font: $f\"; $zip = \"$f.zip\"; $url = \"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$zip\"; Invoke-WebRequest -Uri $url -OutFile $zip; New-Item -ItemType Directory -Force -Path $fDir | Out-Null; Expand-Archive -Path $zip -DestinationPath $fDir -Force; Remove-Item $zip; " ^
"  $files = Get-ChildItem -Path $fDir -Include *.ttf, *.otf -Recurse; " ^
"  $exclude = @('Propo', 'Windows Compatible', 'Thin', 'ExtraLight', 'Light', 'SemiBold', 'SemiLight', 'Condensed'); " ^
"  $keep = $files | Where-Object { ($_.Name -like '*Mono*') -and ($_.Name -match 'Regular|Bold|Italic') -and ($_.Name -notmatch ($exclude -join '|')) }; " ^
"  if ($keep.Count -lt 4) { $keep += ($files | Where-Object { ($_.Name -match 'Regular|Bold|Italic') -and ($_.Name -notmatch ($exclude -join '|')) -and ($keep -notcontains $_) }) }; " ^
"  $toDelete = $files | Where-Object { $keep -notcontains $_ }; foreach($d in $toDelete) { Remove-Item $d.FullName -Force } } }; "

:skip_download

if not exist "%THEME_DIR%" mkdir "%THEME_DIR%"

:: STEP 1: Main Menu
:menu_shell
cls
echo [STEP 1/4] Select Configuration Option:
echo [1] PowerShell + CMD (Full Installation)
echo [2] Only PowerShell
echo [3] Only CMD
echo [4] Change Theme Only
echo [5] Install Fonts Only
echo.
set /p "CHOICE_MAIN=Enter choice (1-5): "

set "DO_PS=0"
set "DO_CMD=0"
set "SKIP_APPS=0"
set "SKIP_THEMES=0"
set "SKIP_FONTS=0"

if "%CHOICE_MAIN%"=="1" ( set "DO_PS=1" & set "DO_CMD=1" )
if "%CHOICE_MAIN%"=="2" ( set "DO_PS=1" )
if "%CHOICE_MAIN%"=="3" ( set "DO_CMD=1" )
if "%CHOICE_MAIN%"=="4" ( set "DO_PS=1" & set "DO_CMD=1" & set "SKIP_APPS=1" & set "SKIP_FONTS=1" )
if "%CHOICE_MAIN%"=="5" ( set "SKIP_APPS=1" & set "SKIP_THEMES=1" )

if "%DO_PS%"=="0" if "%DO_CMD%"=="0" if "%SKIP_APPS%"=="0" goto menu_shell

if "%SKIP_APPS%"=="1" goto menu_theme

:: Smart Winget Update/Install Logic
echo [1/4] Checking for App Updates...
oh-my-posh --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Oh My Posh...
    winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements
) else (
    echo Checking for Oh My Posh updates...
    winget upgrade JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements >nul 2>&1
)

if "%DO_CMD%"=="0" goto skip_clink_update
clink --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Clink...
    winget install chrisant996.clink --accept-package-agreements --accept-source-agreements
) else (
    echo Checking for Clink updates...
    winget upgrade chrisant996.clink --accept-package-agreements --accept-source-agreements >nul 2>&1
)
:skip_clink_update

:: STEP 2: Dynamic Theme Selection
:menu_theme
if "%SKIP_THEMES%"=="1" goto menu_font
cls
echo [STEP 2/4] Choose your Terminal Theme:
echo.
set "t_count=0"
for %%f in ("%BASE_DIR%Themes\*.json") do (
    set /a "t_count+=1"
    set "theme_!t_count!=%%~nxf"
    echo [!t_count!] %%~nf
)
echo.
set /p "T_SEL=Select theme (1-%t_count%): "
if not defined theme_%T_SEL% goto menu_theme

set "SEL_THEME_FILE=!theme_%T_SEL%!"
set "ACTIVE_THEME=%THEME_DIR%\active.omp.json"

if exist "%THEME_DIR%\*.json" del /Q /F "%THEME_DIR%\*.json" >nul 2>&1
copy /Y "%BASE_DIR%Themes\%SEL_THEME_FILE%" "%ACTIVE_THEME%" >nul

:: STEP 3: Dynamic Font Family Selection
:menu_font
if "%SKIP_FONTS%"=="1" goto step_final
cls
echo [STEP 3/4] Choose a Font Family to Install:
echo.
set "f_count=0"
echo [0] Skip Font Installation
for /d %%d in ("%BASE_DIR%Fonts\*") do (
    set /a "f_count+=1"
    set "font_!f_count!=%%~nxd"
    echo [!f_count!] %%~nxd
)
echo.
set /p "F_SEL=Select font family (0-%f_count%): "
if "%F_SEL%"=="0" goto step_final
if not defined font_%F_SEL% goto menu_font

set "SEL_FONT_DIR=!font_%F_SEL%!"
set "SRC_FONT_PATH=%BASE_DIR%Fonts\!SEL_FONT_DIR!"
echo Installing %SEL_FONT_DIR% variations...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$fDir = '%SRC_FONT_PATH%'; $fonts = Get-ChildItem -Path $fDir -Filter *.ttf -Recurse; $fontFolder = [System.Environment]::GetFolderPath('Fonts'); foreach($font in $fonts) { $target = Join-Path $fontFolder $font.Name; if (-not (Test-Path $target)) { Copy-Item $font.FullName $target; $keyPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'; $valueName = $font.BaseName + ' (TrueType)'; Set-ItemProperty -Path $keyPath -Name $valueName -Value $font.Name -Force } }"

:: STEP 4: Finalize
:step_final
set "ACTIVE_THEME=%THEME_DIR%\active.omp.json"
:: Emergency Fix: If active theme is missing, copy a default one
if not exist "%ACTIVE_THEME%" (
    if exist "%BASE_DIR%Themes\jandedobbeleer.omp.json" (
        copy /Y "%BASE_DIR%Themes\jandedobbeleer.omp.json" "%ACTIVE_THEME%" >nul
    )
)

if "%SKIP_THEMES%"=="1" if "%SKIP_FONTS%"=="0" goto finish
cls
echo [STEP 4/4] Finalizing Configurations...

:: PowerShell (Multi-Version: Supports 5.1 and 7)
if "%DO_PS%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$themePath = '%ACTIVE_THEME%'; $initLine = 'oh-my-posh init pwsh --config \"' + $themePath + '\" | Invoke-Expression'; $profiles = @($PROFILE, \"$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\"); foreach ($p in $profiles) { if ($p -and (Test-Path (Split-Path $p -Parent))) { if (-not (Test-Path $p)) { New-Item -Path $p -ItemType File -Force }; $content = Get-Content $p -Raw; $cleaned = $content -replace '(?m)^.*oh-my-posh init.*$\r?\n?', '' -replace '(?m)^.*Clear-Host.*$\r?\n?', ''; Set-Content -Path $p -Value $cleaned.Trim() -Encoding UTF8; Add-Content -Path $p -Value \"`r`n$initLine`r`nClear-Host\" -Encoding UTF8; } }"
)

:: CMD
if "%DO_CMD%"=="1" (
    set "CMD_INIT=%THEME_DIR%\init_cmd.bat"
    echo @echo off > "!CMD_INIT!"
    echo cls >> "!CMD_INIT!"
    echo if exist "%%ProgramFiles(x86)%%\clink\clink.bat" ( >> "!CMD_INIT!"
    echo     call "%%ProgramFiles(x86)%%\clink\clink.bat" inject --quiet --autorun >> "!CMD_INIT!"
    echo ) else if exist "%%ProgramFiles%%\clink\clink.bat" ( >> "!CMD_INIT!"
    echo     call "%%ProgramFiles%%\clink\clink.bat" inject --quiet --autorun >> "!CMD_INIT!"
    echo ) >> "!CMD_INIT!"

    reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "if exist \"!CMD_INIT!\" call \"!CMD_INIT!\"" /f >nul 2>&1

    set "CLINK_EXE="
    if exist "%ProgramFiles(x86)%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles(x86)%\clink\clink.bat"
    if exist "%ProgramFiles%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles%\clink\clink.bat"
    if defined CLINK_EXE (
        call "%CLINK_EXE%" set clink.logo none >nul 2>&1
        call "%CLINK_EXE%" set clink.autoupdate off >nul 2>&1
    )

    set "CLINK_LUA_DIR=%LOCALAPPDATA%\clink"
    if not exist "!CLINK_LUA_DIR!" mkdir "!CLINK_LUA_DIR!"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$luaPath = Join-Path $env:LOCALAPPDATA 'clink\oh-my-posh.lua'; $themePath = '%ACTIVE_THEME%'.Replace('\', '\\'); $content = 'oh-my-posh init cmd --config \"' + $themePath + '\"'; [System.IO.File]::WriteAllText($luaPath, $content)"
)

:finish
echo.
echo ========================================
echo Operation Complete! Theme successfully linked.
echo ========================================
pause
