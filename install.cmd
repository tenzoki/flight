@echo off
setlocal
REM flight installer bootstrap for Windows
REM
REM Fetches and runs install.ps1 over HTTPS via PowerShell.
REM Double-click this file, or run `install.cmd` from a terminal.
REM It runs the same one-liner shown in the README "Quick start (Windows)".

echo ================================================================
echo  flight installer - prerequisites
echo ================================================================
echo.
echo  Before installing flight, TWO tools must already be installed
echo  on this machine:
echo.
echo    1. Claude Code CLI   (provides the 'claude' command)
echo    2. Git for Windows   (provides the 'git' command)
echo.
echo ----------------------------------------------------------------
echo  How to install on Windows:
echo ----------------------------------------------------------------
echo.
echo  Claude Code CLI:
echo    Follow the Windows install steps in the docs:
echo    https://docs.claude.com/en/docs/claude-code
echo.
echo  Git for Windows:
echo    winget install --id Git.Git -e --source winget
echo    or download from:
echo    https://git-scm.com/download/win
echo.
echo ================================================================
echo.

choice /c YN /n /m "Are BOTH Claude Code and Git already installed?  [Y = continue / N = cancel] "
if errorlevel 2 goto :cancel

echo.
echo Continuing with flight installation...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/tenzoki/flight/main/install.ps1 | iex"
set "rc=%errorlevel%"
echo.
pause
exit /b %rc%

:cancel
echo.
echo Installation cancelled.
echo Please install the prerequisites above, then run install.cmd again.
echo.
pause
exit /b 1
