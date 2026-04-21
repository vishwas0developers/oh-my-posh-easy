@echo off
setlocal EnableDelayedExpansion

:: Set encoding to UTF-8
chcp 65001 >nul

:: ========================================
:: AUTO-ELEVATION (Request Admin Privileges)
:: ========================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrator privileges for cleanup...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

echo ========================================
echo Oh My Posh - Smart Uninstaller
echo ========================================
echo.

:: Global Paths
set "THEME_DIR=C:\Terminal Theme"

:menu
echo Select uninstallation scope:
echo [1] Full Cleanup (Apps + Configs + Themes)
echo [2] Only PowerShell Profiles
echo [3] Only CMD / Clink Configs
echo.
set /p "CHOICE=Enter choice (1-3): "

if "%CHOICE%"=="1" goto uninstall_full
if "%CHOICE%"=="2" goto uninstall_ps
if "%CHOICE%"=="3" goto uninstall_cmd
goto menu

:: ========================================
:uninstall_full
:: ========================================
echo [1/4] Uninstalling Apps...
winget uninstall JanDeDobbeleer.OhMyPosh --accept-source-agreements >nul 2>&1
winget uninstall chrisant996.clink --accept-source-agreements >nul 2>&1

echo [2/4] Removing System Theme directory...
if exist "%THEME_DIR%" rmdir /s /q "%THEME_DIR%" >nul 2>&1

goto uninstall_ps_core

:: ========================================
:uninstall_ps
:: ========================================
:uninstall_ps_core
echo [3/4] Cleaning PowerShell profiles (All Versions)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles = @($PROFILE, \"$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\", \"$HOME\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\"); foreach ($p in $profiles) { if ($p -and (Test-Path $p)) { $content = Get-Content $p -Raw; $cleaned = $content -replace '(?m)^.*oh-my-posh.*$\r?\n?', '' -replace '(?m)^.*Clear-Host.*$\r?\n?', ''; Set-Content -Path $p -Value $cleaned.Trim() -Encoding UTF8; Write-Host \"  Cleaned: $p\" } }"
if "%CHOICE%"=="2" goto finish

:: ========================================
:uninstall_cmd
:: ========================================
:uninstall_cmd_core
echo [4/4] Cleaning CMD and Clink configurations...

:: Clear AutoRun Registry
reg delete "HKCU\Software\Microsoft\Command Processor" /v AutoRun /f >nul 2>&1

:: Remove Clink Local AppData
if exist "%LOCALAPPDATA%\clink" rmdir /s /q "%LOCALAPPDATA%\clink" >nul 2>&1

:: Reset Clink settings if possible
set "CLINK_EXE="
if exist "%ProgramFiles(x86)%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles(x86)%\clink\clink.bat"
if exist "%ProgramFiles%\clink\clink.bat" set "CLINK_EXE=%ProgramFiles%\clink\clink.bat"
if defined CLINK_EXE (
    call "%CLINK_EXE%" set clink.logo "" >nul 2>&1
    call "%CLINK_EXE%" set clink.autoupdate on >nul 2>&1
)

goto finish

:: ========================================
:finish
:: ========================================
echo.
echo ========================================
echo Cleanup Successful!
echo ========================================
pause
exit /b
