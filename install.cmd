@echo off
REM flight installer bootstrap for Windows
REM
REM Fetches and runs install.ps1 over HTTPS via PowerShell.
REM Double-click this file, or run `install.cmd` from a terminal.
REM It runs the same one-liner shown in the README "Quick start (Windows)".
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/tenzoki/flight/main/install.ps1 | iex"
set "rc=%errorlevel%"
echo.
pause
exit /b %rc%
