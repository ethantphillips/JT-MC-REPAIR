@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Get the folder where this script is located
set "script_dir=%~dp0"
cd /d "%script_dir%"

:: Generate today's date in yyyyMMdd format
for /f %%a in ('powershell -Command Get-Date -Format "yyyyMMdd"') do set "today=%%a"

:: Obfuscate and limit to 6-digit code
set /a seed=31415
set /a code_raw=(!today! * !seed! + 271828)
set /a code=(code_raw %% 900000) + 100000

:: Prompt for the access code
set /p "input=Enter today's access code: "

:: Compare input with generated code
if "%input%" NEQ "!code!" (
    echo Incorrect code. Exiting...
    timeout /t 3 >nul
    exit /b
)

echo Code accepted. Beginning update...

:: Define the name of this .bat file so it won't delete itself
set "self=%~nx0"

:: Delete all files in the current directory EXCEPT this .bat file
for %%f in (*) do (
    if /I not "%%~nxf"=="%self%" del /f /q "%%~f"
)

:: Download the zip file
set "download_url=hhttps://my.microsoftpersonalcontent.com/personal/5584bdf1c898d789/_layouts/15/download.aspx?UniqueId=a88d5cfa-0269-466b-a749-f2674fddc9d1&Translate=false&tempauth=v1e.eyJzaXRlaWQiOiI3ZmU1NjBjZi1jMTRkLTQ3OTgtOGQ0OC03YzYzNGJlNzkzYzQiLCJhcHBpZCI6IjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDA0ODE3MTBhNCIsImF1ZCI6IjAwMDAwMDAzLTAwMDAtMGZmMS1jZTAwLTAwMDAwMDAwMDAwMC9teS5taWNyb3NvZnRwZXJzb25hbGNvbnRlbnQuY29tQDkxODgwNDBkLTZjNjctNGM1Yi1iMTEyLTM2YTMwNGI2NmRhZCIsImV4cCI6IjE3NDQzNzYxMTUifQ.MaPuRBVcJ3O5c8zIf-5YSEvUBesoyTpAWi0TLZMneYZ9M9ydHafADGVtjxROEy7tZRu-G_0Xu4GvEJ55QFRWtgAtW3IxkC1R9HH3ZGlUspg7ulZ0LbpC1k0kFv3BtFvXEerFqPkw_NiDHJEHfYU6CpfYUeD_PwyXk-v3VA3kBUxnx0stMgODKNVJTfRUf_2LULH7--p7rzNkKWDNq7KQC_nFA5JQjVMWq_wZlPyifruVmvuDay6LTYEZqGo66QyJfDJ314eTwi1_UEM5kBpmanCEUMseaeGhzS-D-Fnz8iQJYikwCXF17OPK96D3nAyzvJH2IMURu5zccwZ7L4uTJocPh0d0rLC1IgZpqSqBUkNRuxdCqGb7h_MXtidPk0F7NviORmQOzc43PQFwdY6NDXWozLtBGhZxJ0fwtV_2uEw.C3U9VxcMHDkI1W5bKlgCw9FP0zlwgOYyUZ0Xhe6TUdI&ApiVersion=2.0&AVOverride=1"
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
for %%f in (repair*.zip) do (
    set "name=%%~nf"
    set "number=!name:repair=!"
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


echo Downloading update package...
powershell -Command "Invoke-WebRequest -Uri '%download_url%' -OutFile '%zip_name%'"

:: Extract the zip file to the same directory
echo Extracting...
powershell -Command "Expand-Archive -Path '%zip_name%' -DestinationPath '.' -Force"

:: Clean up downloaded zip
del /f /q "%zip_name%"

echo Update complete. Cleaning up...

:: Self-delete
(
    echo @echo off
    echo timeout /t 1 >nul
    echo del "%%~f0"
) > temp_del.bat
start /min "" temp_del.bat
exit
