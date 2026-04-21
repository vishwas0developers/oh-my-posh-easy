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
set "SYSTEM_THEMES=%THEME_DIR%\Themes"
set "SYSTEM_FONTS=%THEME_DIR%\Fonts"

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
"foreach($t in $themes) { $url = \"https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$t.omp.json\"; $dest = \"Themes/$t.omp.json\"; if (!(Test-Path $dest)) { Invoke-WebRequest -Uri $url -OutFile $dest } }; " ^
"foreach($f in $fonts) { $fDir = \"Fonts/$f\"; if (!(Test-Path $fDir)) { $zip = \"$f.zip\"; $url = \"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$zip\"; Invoke-WebRequest -Uri $url -OutFile $zip; Expand-Archive -Path $zip -DestinationPath $fDir -Force; Remove-Item $zip; " ^
"  $files = Get-ChildItem -Path $fDir -Include *.ttf, *.otf -Recurse; " ^
"  $exclude = @('Propo', 'Windows Compatible', 'Thin', 'ExtraLight', 'Light', 'SemiBold', 'SemiLight', 'Condensed'); " ^
"  $keep = $files | Where-Object { ($_.Name -like '*Mono*') -and ($_.Name -match 'Regular|Bold|Italic') -and ($_.Name -notmatch ($exclude -join '|')) }; " ^
"  if ($keep.Count -lt 4) { $keep += ($files | Where-Object { ($_.Name -match 'Regular|Bold|Italic') -and ($_.Name -notmatch ($exclude -join '|')) -and ($keep -notcontains $_) }) }; " ^
"  $toDelete = $files | Where-Object { $keep -notcontains $_ }; foreach($d in $toDelete) { Remove-Item $d.FullName -Force } } }; "

:skip_download

:: Sync to C:\Terminal Theme
if not exist "%THEME_DIR%" mkdir "%THEME_DIR%"
if not exist "%SYSTEM_THEMES%" mkdir "%SYSTEM_THEMES%"
if not exist "%SYSTEM_FONTS%" mkdir "%SYSTEM_FONTS%"

echo Syncing assets to system storage...
xcopy /Y /Q /E "%BASE_DIR%Themes\*" "%SYSTEM_THEMES%\" >nul 2>&1
xcopy /Y /Q /E "%BASE_DIR%Fonts\*" "%SYSTEM_FONTS%\" >nul 2>&1

:: STEP 1: Shell Selection
:menu_shell
cls
echo [STEP 1/4] Select Shell Configuration:
echo [1] PowerShell + CMD (Full Installation)
echo [2] Only PowerShell
echo [3] Only CMD
echo.
set /p "CHOICE_SHELL=Enter choice (1-3): "

set "DO_PS=0"
set "DO_CMD=0"
if "%CHOICE_SHELL%"=="1" ( set "DO_PS=1" & set "DO_CMD=1" )
if "%CHOICE_SHELL%"=="2" ( set "DO_PS=1" )
if "%CHOICE_SHELL%"=="3" ( set "DO_CMD=1" )
if "%DO_PS%"=="0" if "%DO_CMD%"=="0" goto menu_shell

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
cls
echo [STEP 2/4] Choose your Terminal Theme:
echo.
set "t_count=0"
for %%f in ("%SYSTEM_THEMES%\*.json") do (
    set /a "t_count+=1"
    set "theme_!t_count!=%%~nxf"
    echo [!t_count!] %%~nf
)
echo.
set /p "T_SEL=Select theme (1-%t_count%): "
if not defined theme_%T_SEL% goto menu_theme
set "SEL_THEME_FILE=!theme_%T_SEL%!"
set "ACTIVE_THEME=%THEME_DIR%\active.omp.json"
copy /Y "%SYSTEM_THEMES%\%SEL_THEME_FILE%" "%ACTIVE_THEME%" >nul

:: STEP 3: Dynamic Font Family Selection
:menu_font
cls
echo [STEP 3/4] Choose a Font Family to Install:
echo.
set "f_count=0"
echo [0] Skip Font Installation
for /d %%d in ("%SYSTEM_FONTS%\*") do (
    set /a "f_count+=1"
    set "font_!f_count!=%%~nxd"
    echo [!f_count!] %%~nxd
)
echo.
set /p "F_SEL=Select font family (0-%f_count%): "
if "%F_SEL%"=="0" goto step_final
if not defined font_%F_SEL% goto menu_font

set "SEL_FONT_DIR=!font_%F_SEL%!"
echo Installing %SEL_FONT_DIR% variations...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$fDir = Join-Path '%SYSTEM_FONTS%' '%SEL_FONT_DIR%'; $fonts = Get-ChildItem -Path $fDir -Filter *.ttf -Recurse; $fontFolder = [System.Environment]::GetFolderPath('Fonts'); foreach($font in $fonts) { $target = Join-Path $fontFolder $font.Name; if (-not (Test-Path $target)) { Copy-Item $font.FullName $target; $keyPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'; $valueName = $font.BaseName + ' (TrueType)'; Set-ItemProperty -Path $keyPath -Name $valueName -Value $font.Name -Force } }"

:: STEP 4: Finalize
:step_final
cls
echo [STEP 4/4] Finalizing Configurations...

:: PowerShell
if "%DO_PS%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$themePath = '%ACTIVE_THEME%'; $initLine = 'oh-my-posh init pwsh --config \"' + $themePath + '\" | Invoke-Expression'; $profiles = @($PROFILE, \"$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\"); foreach ($p in $profiles) { if ($p -and (Test-Path (Split-Path $p -Parent))) { if (-not (Test-Path $p)) { New-Item -Path $p -ItemType File -Force }; $content = Get-Content $p -Raw; $cleaned = $content -replace '(?m)^.*oh-my-posh init.*$\r?\n?', '' -replace '(?m)^.*Clear-Host.*$\r?\n?', ''; Set-Content -Path $p -Value $cleaned.Trim() -Encoding UTF8; Add-Content -Path $p -Value \"`r`n$initLine`r`nClear-Host\" -Encoding UTF8; } }"
)

:: CMD (Improved Path Handling for Spaces)
if "%DO_CMD%"=="1" (
    set "CMD_INIT=%THEME_DIR%\init_cmd.bat"
    echo @echo off > "!CMD_INIT!"
    echo cls >> "!CMD_INIT!"
    echo if exist "%%ProgramFiles(x86)%%\clink\clink.bat" ( >> "!CMD_INIT!"
    echo     call "%%ProgramFiles(x86)%%\clink\clink.bat" inject --quiet --autorun >> "!CMD_INIT!"
    echo ) else if exist "%%ProgramFiles%%\clink\clink.bat" ( >> "!CMD_INIT!"
    echo     call "%%ProgramFiles%%\clink\clink.bat" inject --quiet --autorun >> "!CMD_INIT!"
    echo ) >> "!CMD_INIT!"

    :: Robust AutoRun Registry Entry
    reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "if exist \"!CMD_INIT!\" call \"!CMD_INIT!\"" /f >nul 2>&1

    set "CLINK_EXE="
    if exist "%ProgramFiles(x86)%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles(x86)%\clink\clink.bat"
    if exist "%ProgramFiles%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles%\clink\clink.bat"
    if defined CLINK_EXE (
        call "%CLINK_EXE%" set clink.logo none >nul 2>&1
        call "%CLINK_EXE%" set clink.autoupdate off >nul 2>&1
    )

    set "CLINK_LUA=%LOCALAPPDATA%\clink"
    if not exist "!CLINK_LUA!" mkdir "!CLINK_LUA!"
    echo oh-my-posh init cmd --config "%ACTIVE_THEME%" > "!CLINK_LUA!\oh-my-posh.lua" 2>nul
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
pause
