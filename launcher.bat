@echo off
setlocal enabledelayedexpansion

:: CONFIG
set "LICENSE_FILE=%APPDATA%\McBypass\license.key"
set "LICENSE_URL=https://gitunblock.netlify.app/ethantphillips/mclcheck/main/.mcbypass_licenses.ini"
set "PRISM_LAUNCHER=%APPDATA%\McBypass\PrismLauncher\prismlauncher.exe"
set "BRF=%TEMP%\backend_ready_check.txt"
set "TLF=%TEMP%\licensecheck.ini"
set "SUSPENDED_FLAG=%APPDATA%\McBypass\suspended.txt"
set "INFO_TEMP=%TEMP%\_licenseinfo.tmp"

:: Step 1: Read license
if not exist "%LICENSE_FILE%" (
  echo [ERROR] No license.key; run setup first.
  pause
  exit /b
)
set /p LICENSE_KEY=<"%LICENSE_FILE%"
echo Using saved license key: !LICENSE_KEY!

:: Step 2: Backend ready check (10× retries, 10s wait)
set "RETRIES=10"
:CHECK_BACKEND
set /a RETRIES-=1
curl -s "%LICENSE_URL%" | findstr /B /C:"Ready" >nul
if !errorlevel! EQU 0 goto VERIFY_LICENSE

if !RETRIES! LEQ 0 (
  echo Backend not ready after retries -> offline mode
  if exist "!SUSPENDED_FLAG!" (
    echo [BLOCKED] Offline mode but user is suspended.
    pause
    exit /b
  )
  goto :LAUNCH
:: Time-based greeting
for /f "tokens=1 delims=:" %%t in ('time /t') do set HOUR=%%t
if %HOUR% LSS 12 (
  set GREETING=Good Morning
) else if %HOUR% LSS 18 (
  set GREETING=Good Afternoon
) else (
  set GREETING=Good Evening
)
echo !GREETING!, !NAME!, have fun!

)
echo Backend not ready. Retrying in 10s... (!RETRIES! left)
timeout /t 10 >nul
goto CHECK_BACKEND

:VERIFY_LICENSE
curl -s -o "!TLF!" "%LICENSE_URL%"
if not exist "!TLF!" (
  echo [ERROR] Could not verify license; assuming active.
  goto LAUNCH
)

del /f /q "!INFO_TEMP!" >nul 2>&1

set "VALID=0"
set "LINE_FOUND="

for /f "usebackq tokens=1,* delims==" %%A in ("!TLF!") do (
  set "CURRENT_KEY=%%A"
  set "REST_OF_LINE=%%B"
  call set "CURRENT_KEY=!CURRENT_KEY!"
  if /I not "!CURRENT_KEY!"=="Ready" (
    echo Checking license: !CURRENT_KEY!
    set "MATCHES=0"
    set /a "KEYLEN=0"
    for /l %%i in (0,1,31) do (
      call set "CHAR_KEY=!LICENSE_KEY:~%%i,1!"
      call set "CHAR_CUR=!CURRENT_KEY:~%%i,1!"
      if defined CHAR_KEY if defined CHAR_CUR set /a "KEYLEN+=1"
      if "!CHAR_KEY!"=="!CHAR_CUR!" set /a MATCHES+=1
    )
    if not "!KEYLEN!"=="0" set /a "SCORE=MATCHES*100/KEYLEN"
    if defined SCORE if !SCORE! GEQ 75 (
      echo Matched with !CURRENT_KEY! (!SCORE!%% match)
      set "LINE_FOUND=1"
      echo !REST_OF_LINE!>"!INFO_TEMP!"
    )
  )
)
  )
)

if not defined LINE_FOUND (
  echo [ERROR] License not found/inactive.
  del /f /q "!TLF!" >nul 2>&1
  pause
  exit /b
)

for /f "tokens=1,2,3,4,5 delims=," %%i in (!INFO_TEMP!) do (
  set "NAME=%%i"
  set "EXP=%%j"
  set "MAX=%%k"
  set "USED=%%l"
  set "STATUS=%%m"
)

del /f /q "!INFO_TEMP!" >nul 2>&1

if /I "!STATUS!"=="active" (
  set "VALID=1"
  if exist "!SUSPENDED_FLAG!" del /f /q "!SUSPENDED_FLAG!" >nul 2>&1
) else if /I "!STATUS!"=="suspended" (
  echo [SUSPENDED] License suspended; access blocked.
  echo Suspension detected > "!SUSPENDED_FLAG!"
  del /f /q "!TLF!" >nul 2>&1
  pause
  exit /b
)

:: Cleanup license check file
del /f /q "!TLF!" >nul 2>&1

:LAUNCH
echo Launching Prism Launcher...
start "" "%PRISM_LAUNCHER%"
exit /b
