@echo off
setlocal enabledelayedexpansion

:: ===== CONFIG =====
set "LICENSE_FILE=%APPDATA%\McBypass\license.key"
set "LICENSE_URL=gitunblock.netlify.app/ethantphillips/mclcheck/main/.mcbypass_licenses.ini"
set "PRISM_LAUNCHER=%APPDATA%\McBypass\PrismLauncher\PrismLauncher.exe"

:: ===== Step 1: Read stored license =====
if not exist "!LICENSE_FILE!" (
    echo [ERROR] License key not found. Please run setup again.
    pause
    exit /b
)

set /p LICENSE_KEY=<"!LICENSE_FILE!"
echo Using saved license key: !LICENSE_KEY!

:: ===== Step 2: Check Internet =====
ping raw.githubusercontent.com -n 1 >nul 2>&1
if errorlevel 1 (
    echo Offline. Launching Prism...
    goto :LAUNCH
)

:: ===== Step 3: Download and Check License =====
set "TEMP_LICENSE=%TEMP%\licensecheck.ini"
curl -s -o "!TEMP_LICENSE!" "!LICENSE_URL!"
if errorlevel 1 (
    echo [ERROR] Could not verify license. Assuming active.
    goto :LAUNCH
)

set "VALID=0"
for /f "usebackq tokens=1,* delims==" %%A in ("!TEMP_LICENSE!") do (
    echo Checking license: %%A
    if "%%A"=="suspended !LICENSE_KEY!" (
        echo [SUSPENDED] Your license has been suspended. Access to Prism is blocked.
        pause
        exit /b
    )
    if "%%A"=="!LICENSE_KEY!" (
        set "VALID=1"
    )
)

if "!VALID!"=="0" (
    echo [ERROR] License key not found or invalid.
    pause
    exit /b
)

:: ===== Step 4: Launch Prism =====
:LAUNCH
echo Launching Prism Launcher...
start "" "!PRISM_LAUNCHER!"
exit /b
