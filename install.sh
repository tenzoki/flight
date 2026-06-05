#!/usr/bin/env bash
#
# flight installer — macOS / Linux
#
# Installs flight as a Claude Code plugin WITHOUT git, without SSH, and without
# Claude Code's plugin marketplace cache. It downloads the plugin over plain
# HTTPS, drops it in ~/.flight, and installs a `flight` launcher that loads the
# plugin straight from that directory on every run.
#
#   Install / update:  curl -fsSL https://raw.githubusercontent.com/tenzoki/flight/main/install.sh | bash
#   Run:               flight
#   Update later:      flight --update
#   Remove:            flight --uninstall
#
# Why this exists: the marketplace path clones over git (breaks when a user's
# git is configured for SSH or has no key) and its cache is not reliably
# replaced on update/uninstall. This path avoids all of that — it is just a
# download into a folder plus a one-line launcher.
#
# Overrides (optional env vars):
#   FLIGHT_REF   git ref to fetch (default: heads/main; pin a release with
#                FLIGHT_REF=tags/v0.6.0)
#   FLIGHT_HOME  install dir (default: ~/.flight)
#   FLIGHT_BIN   launcher dir (default: ~/.local/bin)

set -euo pipefail

REPO="tenzoki/flight"
REF="${FLIGHT_REF:-heads/main}"
INSTALL_DIR="${FLIGHT_HOME:-$HOME/.flight}"
BIN_DIR="${FLIGHT_BIN:-$HOME/.local/bin}"
LAUNCHER="$BIN_DIR/flight"
TARBALL_URL="https://github.com/$REPO/archive/refs/$REF.tar.gz"

say()  { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. Preconditions ---------------------------------------------------------
command -v curl >/dev/null 2>&1 || die "curl is required but not found."
command -v tar  >/dev/null 2>&1 || die "tar is required but not found."
if ! command -v claude >/dev/null 2>&1; then
  die "The Claude Code CLI ('claude') was not found on your PATH.
Install Claude Code first, then re-run this installer:
  https://docs.claude.com/en/docs/claude-code"
fi

# --- 2. Download + extract over HTTPS (no git, no SSH) ------------------------
say "Downloading flight ($REF) over HTTPS..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$TARBALL_URL" -o "$TMP/flight.tar.gz" \
  || die "Download failed: $TARBALL_URL
Check your internet connection and that the ref exists."
tar -xzf "$TMP/flight.tar.gz" -C "$TMP" || die "Could not extract the archive."

SRC="$(find "$TMP" -maxdepth 1 -type d -name 'flight-*' | head -1)"
[ -n "$SRC" ] && [ -f "$SRC/.claude-plugin/plugin.json" ] \
  || die "Downloaded archive does not look like the flight plugin (no .claude-plugin/plugin.json)."

VERSION="$(sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' "$SRC/.claude-plugin/plugin.json" | head -1)"

# --- 3. Install into ~/.flight (atomic replace) ------------------------------
say "Installing to $INSTALL_DIR ..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
# Copy only the plugin assets — never any dev cruft.
for item in .claude-plugin agents skills templates stilwerk README.md LICENSE; do
  [ -e "$SRC/$item" ] && cp -R "$SRC/$item" "$INSTALL_DIR/"
done
[ -f "$INSTALL_DIR/.claude-plugin/plugin.json" ] || die "Install copy failed."

# --- 4. Launcher --------------------------------------------------------------
mkdir -p "$BIN_DIR"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# flight launcher — loads the plugin directly from a folder (no cache, no git).
set -euo pipefail
FLIGHT_DIR="$INSTALL_DIR"
case "\${1:-}" in
  --update)
    curl -fsSL "https://raw.githubusercontent.com/$REPO/main/install.sh" -o /tmp/flight-install.sh \
      && bash /tmp/flight-install.sh
    exit \$?
    ;;
  --uninstall)
    rm -rf "\$FLIGHT_DIR" "$LAUNCHER"
    echo "flight removed."
    exit 0
    ;;
  --where)
    echo "\$FLIGHT_DIR"
    exit 0
    ;;
esac
exec claude --plugin-dir "\$FLIGHT_DIR" --agent flight:pilot "\$@"
EOF
chmod +x "$LAUNCHER"

# --- 5. PATH check ------------------------------------------------------------
say "flight ${VERSION:-} installed."
case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "Start it any time with:  flight"
    ;;
  *)
    warn "$BIN_DIR is not on your PATH yet."
    echo "Add it once (zsh):"
    echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    echo "Then start flight with:  flight"
    echo "(Or run it now with the full path: $LAUNCHER)"
    ;;
esac
