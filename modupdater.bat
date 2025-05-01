@echo off
setlocal enabledelayedexpansion

:: === CONFIG ===
set "ZIP_URL=https://gitunblock.netlify.app/instances"
set "INSTANCES_DIR=%APPDATA%\McBypass\Prism Launcher\instances"
set "TEMP_DIR=%TEMP%\MCBYPS_TEMP"
set "ZIP_FILE=%TEMP_DIR%\instances.zip"

:: === STEP 1: Prepare folders ===
echo [INFO] Preparing folders...
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if not exist "%INSTANCES_DIR%" mkdir "%INSTANCES_DIR%"

:: === STEP 2: Download new instances ZIP ===
echo [INFO] Downloading instances zip...
curl -L -s -o "%ZIP_FILE%" "%ZIP_URL%"
if not exist "%ZIP_FILE%" (
    echo [ERROR] Download failed.
    timeout /t 3 >nul
    exit /b
)

:: === STEP 3: Extract new instances ===
echo [INFO] Extracting downloaded instances...
set "EXTRACT_DIR=%TEMP_DIR%\extracted"
rd /s /q "%EXTRACT_DIR%" >nul 2>&1
mkdir "%EXTRACT_DIR%"

powershell -Command "Expand-Archive -LiteralPath '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force"

:: === STEP 4: Sync instances without duplication ===
echo [INFO] Syncing new instances...
for /d %%F in ("%EXTRACT_DIR%\*") do (
    set "NEW_INSTANCE=%%~nxF"
    set "DEST_FOLDER=%INSTANCES_DIR%\!NEW_INSTANCE!"

    if exist "!DEST_FOLDER!" (
        echo [SKIP] Instance already exists: !NEW_INSTANCE!
    ) else (
        set "BASE_NAME=!NEW_INSTANCE!"
        for /f "tokens=1 delims= " %%A in ("!BASE_NAME!") do set "BASE_COMPARE=%%A"
        for /d %%O in ("%INSTANCES_DIR%\*") do (
            set "OLD_INSTANCE=%%~nxO"
            echo !NEW_INSTANCE! | findstr /i "!OLD_INSTANCE! V" >nul && (
                echo [INFO] Detected new version for !OLD_INSTANCE! >nul
                if exist "%%O\minecraft\saves" (
                    xcopy /E /I /Y "%%O\minecraft\saves" "!DEST_FOLDER!\minecraft\saves" >nul
                    echo [INFO] Transferred saves from !OLD_INSTANCE! to !NEW_INSTANCE!
                )
            )
        )
        xcopy /E /I /Y "%%F" "!DEST_FOLDER!" >nul
        echo [OK] Installed: !NEW_INSTANCE!
    )
)

:: === STEP 5: Cleanup ===
echo [INFO] Cleaning up temporary files...
del /q "%ZIP_FILE%" >nul
rd /s /q "%EXTRACT_DIR%" >nul

:: === DONE ===
echo [SUCCESS] All instances updated successfully.
timeout /t 3 >nul
exit /b
