#!/usr/bin/env bash
set -euo pipefail

REPO="sundayceo/claude-profile"
INSTALL_DIR="${CLAUDE_PROFILE_INSTALL_DIR:-$HOME/.local/bin}"
INSTALL_PATH="$INSTALL_DIR/claude-profile"
DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/claude-profile"

info() {
  printf '\033[1;34m==>\033[0m %s\n' "$1"
}

success() {
  printf '\033[1;32m✓\033[0m %s\n' "$1"
}

error() {
  printf '\033[1;31m✗\033[0m %s\n' "$1" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || error "curl is required."

info "Installing claude-profile"

mkdir -p "$INSTALL_DIR"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$DOWNLOAD_URL" -o "$tmp" || \
  error "Failed to download claude-profile."

chmod +x "$tmp"
mv "$tmp" "$INSTALL_PATH"

success "Installed to $INSTALL_PATH"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    ;;
  *)
    SHELL_NAME="$(basename "${SHELL:-}")"

    case "$SHELL_NAME" in
      zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
      bash)
        RC_FILE="$HOME/.bashrc"
        ;;
      *)
        RC_FILE=""
        ;;
    esac

    if [[ -n "$RC_FILE" ]]; then
      PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

      if ! grep -Fqx "$PATH_LINE" "$RC_FILE" 2>/dev/null; then
        printf '\n%s\n' "$PATH_LINE" >> "$RC_FILE"
        success "Added $INSTALL_DIR to PATH in $RC_FILE"
      fi

      echo
      echo "Restart your shell or run:"
      echo
      echo "  source \"$RC_FILE\""
    else
      echo
      echo "Add this directory to your PATH:"
      echo
      echo "  $INSTALL_DIR"
    fi
    ;;
esac

echo
success "claude-profile installed"
echo
echo "Get started:"
echo
echo "  claude-profile --create work"
echo "  claude-profile --use work"
