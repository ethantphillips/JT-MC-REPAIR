@echo off
setlocal enabledelayedexpansion

:: === SETTINGS ===
set "downloadUrl=https://my.microsoftpersonalcontent.com/personal/5584bdf1c898d789/_layouts/15/download.aspx?UniqueId=59264f0f-c286-41dd-832c-4e31c8c516ab&Translate=false&tempauth=v1e.eyJzaXRlaWQiOiI3ZmU1NjBjZi1jMTRkLTQ3OTgtOGQ0OC03YzYzNGJlNzkzYzQiLCJhcHBpZCI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDA0ODE3MTBhNCIsImF1ZCI6IjAwMDAwMDAzLTAwMDAtMGZmMS1jZTAwLTAwMDAwMDAwMDAwMC9teS5taWNyb3NvZnRwZXJzb25hbGNvbnRlbnQuY29tQDkxODgwNDBkLTZjNjctNGM1Yi1iMTEyLTM2YTMwNGI2NmRhZCIsImV4cCI6IjE3NDQzNzY3MTcifQ.ukEVjfYBTVvVyJ-GAZ1RcwiZSUgjnhwhE-Bdz3u2QmKNexmAW8c8rwgPd2sHJn90klr9u5dZy6GuYDeuKGHT4H_Aag3FVTRtbOplgGOldbIWc2be7NTIa6hrclr-Cnb-ehdXnMn9eF7sHvbx73xKrTkTsGFdu1iKEDqhPxLTB9zEzlKs4azcnfS-gV_jaxCIqIsz_S5uf6jXrxLmrhGa9Em8P1QEPbNkuXh8XLb9PRHlfUMEqabz_7tnNHCm1zM0fTQ2KJ_WLHMF4weMzkL9fkjJa0oGiFGwnBdEnXX7KE2GtQhZz4RtUDUQSYSihfOGSgiJWRErE5QAGAQ2Jee14v_zTWd3gm3_IDfrp_yTLazDxLZsbVenaMhkIEasmElcBiVP1IPqxBitpKCR2j_x6FccDncFbFfZgi0J2C9zOKw.V2tFhsdFCIIpKb1HYRIUWv3wQN6BmRqzsLS44EUxbYM&ApiVersion=2.0&AVOverride=1"
rem Use the newest matching file
call :getLatestZip
if not defined latestZip (
    echo No zip file found.
    exit /b
)
set "zip_name=%latestZip%"
goto :continue

:getLatestZip
set "latestZip="
set "highest=-1"
for %%f in (instances*.zip) do (
    set "name=%%~nf"
    set "number=!name:instances=!"
    set "number=!number:(=!"
    set "number=!number:)=!"
    if "!number!"=="" set "number=0"
    set /a curr=10!number! %% 1000000
    if !curr! GTR !highest! (
        set "highest=!curr!"
        set "latestZip=%%f"
    )
)
exit /b

:continue

set "crdownload=%TEMP%\instances*.zip.crdownload"
set "tempExtract=%TEMP%\instances_extract"
set "destination=D:\JT Minecraft Files, Mods, and Depencdencies\Prism Launcher\instances"

:: === DOWNLOAD ZIP ===
echo Downloading modpack zip from OneDrive...
curl -L "%downloadUrl%" -o "%zipFile%"

:: === WAIT FOR DOWNLOAD COMPLETION ===
:waitForDownload
if exist "%crdownload%" (
    echo Waiting for download to finish...
    timeout /t 5 /nobreak >nul
    goto waitForDownload
)

if not exist "%zipFile%" (
    echo Download failed or was interrupted.
    exit /b 1
)

:: === CLEAN OLD INSTANCES ===
echo Removing old modpack folders...
rd /s /q "%destination%"
mkdir "%destination%"

:: === EXTRACT NEW INSTANCES ===
echo Extracting new instances...
mkdir "%tempExtract%"
tar -xf "%zipFile%" -C "%tempExtract%"

:: === MOVE FOLDERS TO DESTINATION ===
echo Moving extracted folders to Prism Launcher instances folder...
xcopy "%tempExtract%\*" "%destination%\" /E /Y /I

:: === CLEANUP ===
echo Cleaning up temporary files...
rd /s /q "%tempExtract%"
del /q "%zipFile%"

echo ✅ All modpacks updated successfully!
pause
