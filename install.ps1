# flight installer — Windows / PowerShell
#
# Installs flight as a Claude Code plugin WITHOUT git, without SSH, and without
# Claude Code's plugin marketplace cache. It downloads the plugin over plain
# HTTPS, drops it in %USERPROFILE%\.flight, and installs a `flight` launcher that
# loads the plugin straight from that directory on every run.
#
#   Install / update:  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/tenzoki/flight/main/install.ps1 | iex"
#   Run:               flight
#   Update later:      flight --update
#   Remove:            flight --uninstall
#
# Why this exists: the marketplace path clones over git (breaks when a user's
# git is configured for SSH or has no key) and its cache is not reliably
# replaced on update/uninstall. This path avoids all of that — it is just a
# download into a folder plus a one-line launcher. The `irm | iex` form runs in
# memory, so it is not blocked by the default PowerShell ExecutionPolicy that
# gates .ps1 files on disk.
#
# Overrides (optional env vars):
#   FLIGHT_REF   git ref to fetch (default: heads/main; pin a release with
#                FLIGHT_REF=tags/v0.8.0)
#   FLIGHT_HOME  install dir (default: %USERPROFILE%\.flight)
#   FLIGHT_BIN   launcher dir (default: %USERPROFILE%\.local\bin)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # makes Invoke-WebRequest fast

# --- 0. Settings / overrides --------------------------------------------------
$Repo = "tenzoki/flight"
$Ref  = $env:FLIGHT_REF;  if (-not $Ref)  { $Ref  = "heads/main" }
$InstallDir = $env:FLIGHT_HOME; if (-not $InstallDir) { $InstallDir = Join-Path $HOME ".flight" }
$BinDir     = $env:FLIGHT_BIN;  if (-not $BinDir)     { $BinDir     = Join-Path $HOME ".local\bin" }
$Launcher   = Join-Path $BinDir "flight.cmd"
$ZipUrl     = "https://github.com/$Repo/archive/refs/$Ref.zip"

function Say  { param([string]$m) Write-Host $m -ForegroundColor White }
function Warn { param([string]$m) Write-Host $m -ForegroundColor Yellow }
function Die  { param([string]$m) Write-Host $m -ForegroundColor Red; exit 1 }

# --- 1. Preconditions ---------------------------------------------------------
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Die @"
The Claude Code CLI ('claude') was not found on your PATH.
Install Claude Code first, then re-run this installer:
  https://docs.claude.com/en/docs/claude-code
"@
}

# --- 2. Download + extract over HTTPS (no git, no SSH) ------------------------
Say "Downloading flight ($Ref) over HTTPS..."
$Tmp = Join-Path $env:TEMP ("flight-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
try {
  $Zip = Join-Path $Tmp "flight.zip"
  try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $Zip -UseBasicParsing
  } catch {
    Die @"
Download failed: $ZipUrl
Check your internet connection and that the ref exists.
"@
  }

  try {
    Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
  } catch {
    Die "Could not extract the archive."
  }

  $Src = Get-ChildItem $Tmp -Directory | Where-Object Name -like 'flight-*' | Select-Object -First 1
  if (-not $Src) {
    Die "Downloaded archive does not look like the flight plugin (no flight-* directory)."
  }
  $Src = $Src.FullName

  $PluginJson = Join-Path $Src ".claude-plugin\plugin.json"
  if (-not (Test-Path $PluginJson)) {
    Die "Downloaded archive does not look like the flight plugin (no .claude-plugin/plugin.json)."
  }

  $Version = (Get-Content $PluginJson -Raw | ConvertFrom-Json).version

  # --- 3. Install into %USERPROFILE%\.flight (atomic-ish replace) -------------
  Say "Installing to $InstallDir ..."
  if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

  # Copy only the plugin assets — never any dev cruft.
  foreach ($item in @('.claude-plugin', 'agents', 'skills', 'templates', 'stilwerk', 'README.md', 'LICENSE')) {
    $srcItem = Join-Path $Src $item
    if (Test-Path $srcItem) {
      Copy-Item -Recurse -Force -Path $srcItem -Destination $InstallDir
    }
  }

  if (-not (Test-Path (Join-Path $InstallDir ".claude-plugin\plugin.json"))) {
    Die "Install copy failed."
  }

  # --- 4. Launcher -----------------------------------------------------------
  if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

  $launcherBody = @"
@echo off
setlocal
set "FLIGHT_DIR=$InstallDir"
if /i "%~1"=="--update"    ( powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/$Repo/main/install.ps1 | iex" & exit /b )
if /i "%~1"=="--uninstall" ( rmdir /s /q "%FLIGHT_DIR%" & del /q "%~f0" & echo flight removed. & exit /b 0 )
if /i "%~1"=="--where"     ( echo %FLIGHT_DIR% & exit /b 0 )
claude --plugin-dir "%FLIGHT_DIR%" --agent flight:pilot %*
"@
  # Write as UTF-8 without BOM — a BOM breaks `@echo off` parsing in cmd.exe.
  [System.IO.File]::WriteAllText($Launcher, $launcherBody, (New-Object System.Text.UTF8Encoding $false))

  # --- 5. PATH check + add (user scope, no admin) ----------------------------
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $onPath = $false
  if ($userPath) {
    foreach ($seg in $userPath.Split(';')) {
      if ($seg.TrimEnd('\') -ieq $BinDir.TrimEnd('\')) { $onPath = $true; break }
    }
  }

  $verLabel = if ($Version) { "flight $Version installed." } else { "flight installed." }
  Write-Host ""
  Write-Host $verLabel -ForegroundColor White

  if ($onPath) {
    Write-Host "Start it any time with:  flight"
  } else {
    if ($userPath) { $newPath = "$userPath;$BinDir" } else { $newPath = $BinDir }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:PATH = "$env:PATH;$BinDir"   # update current session immediately
    Warn "$BinDir was added to your user PATH."
    Write-Host "This terminal is already updated — but open a NEW terminal for it to stick everywhere."
    Write-Host "Then start flight with:  flight"
  }
}
finally {
  if (Test-Path $Tmp) { Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue }
}
