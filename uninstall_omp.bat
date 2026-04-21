@echo off
setlocal EnableDelayedExpansion

:: Set encoding to UTF-8
chcp 65001 >nul

echo ========================================
echo Oh My Posh - Uninstaller
echo ========================================
echo.

:menu
echo Select an uninstallation option:
echo [1] PowerShell + CMD (Full Uninstallation)
echo [2] Only PowerShell (Removes PS config, keeps apps for CMD)
echo [3] Only CMD (Removes CMD config and Clink, keeps apps for PS)
echo.
set /p "CHOICE=Enter choice (1-3): "

if "%CHOICE%"=="" set "CHOICE=1"
if "%CHOICE%"=="1" goto start_uninstall
if "%CHOICE%"=="2" goto start_uninstall
if "%CHOICE%"=="3" goto start_uninstall

echo Invalid choice.
goto menu

:start_uninstall
cls
echo ========================================
echo Uninstalling... Option %CHOICE%
echo ========================================

:: Define logic flags based on CHOICE
set "DO_PS=0"
set "DO_CMD=0"
set "DO_FULL=0"
if "%CHOICE%"=="1" ( set "DO_PS=1" & set "DO_CMD=1" & set "DO_FULL=1" )
if "%CHOICE%"=="2" ( set "DO_PS=1" )
if "%CHOICE%"=="3" ( set "DO_CMD=1" )

set "THEME_DIR=C:\Terminal Theme"

:: 0. [CRITICAL] Emergency Registry Cleanup for CMD
if "!DO_CMD!"=="1" (
    echo [1/4] Cleaning up CMD AutoRun ^(Emergency Fix^)...
    reg delete "HKCU\Software\Microsoft\Command Processor" /v AutoRun /f >nul 2>&1
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name 'AutoRun' -ErrorAction SilentlyContinue" >nul 2>&1
)

:: 1. Uninstall Apps and Theme Folder
if "!DO_FULL!"=="1" (
    echo [2/4] Uninstalling Oh My Posh and Clink apps...
    winget uninstall JanDeDobbeleer.OhMyPosh --accept-source-agreements >nul 2>&1
    
    :: Uninstall Clink if it's there
    winget uninstall chrisant996.clink --accept-source-agreements >nul 2>&1
    
    :: Remove the Terminal Theme folder entirely
    if exist "%THEME_DIR%" (
        echo Removing theme folder: %THEME_DIR%
        rmdir /s /q "%THEME_DIR%" >nul 2>&1
    )
) else if "!DO_CMD!"=="1" (
    echo [2/4] Uninstalling Clink app...
    winget uninstall chrisant996.clink --accept-source-agreements >nul 2>&1
)

:: 3. Clean CMD/Clink Configurations
if "!DO_CMD!"=="1" (
    echo [3/4] Cleaning CMD configurations...
    if exist "%LOCALAPPDATA%\clink" (
        rmdir /s /q "%LOCALAPPDATA%\clink" >nul 2>&1
        echo Removed Clink configuration directory.
    )
)

:: 4. Clean PowerShell Profiles
if "!DO_PS!"=="1" (
    echo [4/4] Cleaning PowerShell profiles...
    set "TEMP_PS=%TEMP%\omp_clean_%RANDOM%.ps1"
    echo $profiles = @($PROFILE, >> "%TEMP_PS%"
    echo   "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1", >> "%TEMP_PS%"
    echo   "$HOME\OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1") >> "%TEMP_PS%"
    echo foreach ($p in $profiles) { >> "%TEMP_PS%"
    echo     if ($p -and (Test-Path $p)) { >> "%TEMP_PS%"
    echo         $content = Get-Content $p -Raw >> "%TEMP_PS%"
    echo         # Cleanup Oh My Posh, Clear-Host Added by installer
    echo         $cleaned = $content -replace '(?m)^.*oh-my-posh.*$\r?\n?', '' >> "%TEMP_PS%"
    echo         $cleaned = $cleaned -replace '(?m)^.*Clear-Host.*$\r?\n?', '' >> "%TEMP_PS%"
    echo         Set-Content -Path $p -Value $cleaned.Trim() -Encoding UTF8 >> "%TEMP_PS%"
    echo         Write-Host "Cleaned Profile: $p" >> "%TEMP_PS%"
    echo     } >> "%TEMP_PS%"
    echo } >> "%TEMP_PS%"

    powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%"
    if exist "%TEMP_PS%" del "%TEMP_PS%" >nul 2>&1
)

echo.
echo ========================================
echo Cleanup Complete!
echo ========================================
pause
