@echo off
setlocal enabledelayedexpansion

:: ===== CONFIG =====
set "LICENSE_FILE=%APPDATA%\McBypass\license.key"
set "LICENSE_URL=https://gitunblock.netlify.app/ethantphillips/mclcheck/main/.mcbypass_licenses.ini"
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
ping google.com -n 1 >nul 2>&1
if errorlevel 1 (
    echo Offline. Launching Prism...
    goto :LAUNCH
)

:: ===== Step 3: Check Backend Ready with Retries =====
set "RETRIES=10"
:CHECK_BACKEND
set /a RETRIES-=1
set "BACKEND_READY_FILE=%TEMP%\backend_ready_check.txt"
curl -s -o "!BACKEND_READY_FILE!" "https://gitunblock.netlify.app/ethantphillips/mclcheck/main/.mcbypass_licenses.ini"
findstr /B /C:"Ready" "!BACKEND_READY_FILE!" >nul
if errorlevel 1 (
    if !RETRIES! LEQ 0 (
        echo [ERROR] Backend not ready after multiple attempts. Please try again later.
        pause
        exit /b
    )
    echo Backend not ready. Retrying in 10 seconds... (!RETRIES! retries left)
    timeout /t 10 >nul
    goto :CHECK_BACKEND
)

:: ===== Step 4: Download and Check License =====
set "TEMP_LICENSE=%TEMP%\licensecheck.ini"
curl -s -o "!TEMP_LICENSE!" "!LICENSE_URL!"
if errorlevel 1 (
    echo [ERROR] Could not verify license. Assuming active.
    goto :LAUNCH
)

set "VALID=0"
for /f "usebackq tokens=1,* delims==" %%A in ("!TEMP_LICENSE!") do (
    if /I "%%A"=="Ready" (
        rem skip header
    ) else (
        echo Checking license: %%A
        if "%%A"=="!LICENSE_KEY!" (
            for /f "tokens=1,2,3,4,5 delims=," %%i in ("%%B") do (
                set "NAME=%%i"
                set "EXP=%%j"
                set "MAX=%%k"
                set "USED=%%l"
                set "STATUS=%%m"
            )
            if /I "!STATUS!"=="active" (
                set "VALID=1"
            ) else if /I "!STATUS!"=="suspended" (
                echo [SUSPENDED] Your license has been suspended. Access to Prism is blocked.
                pause
                exit /b
            ) else (
                echo [ERROR] Unknown license status: !STATUS!
                pause
                exit /b
            )
        )
    )
)

if "!VALID!"=="0" (
    echo [ERROR] License key not found or inactive.
    pause
    exit /b
)

:: ===== Step 5: Launch Prism =====
:LAUNCH
echo Launching Prism Launcher...
start "" "!PRISM_LAUNCHER!"
exit /b
