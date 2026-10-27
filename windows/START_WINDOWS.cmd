@echo off
setlocal
cd /d "%~dp0.."
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build_Installer_Windows.ps1"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Build failed with exit code %RC% - do not flash an older ISO.
pause
exit /b %RC%
