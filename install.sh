#!/bin/bash

set -e

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print messages
log() {
  echo -e "${GREEN}[✓]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[!]${NC} $1"
}

error() {
  echo -e "${RED}[✗]${NC} $1"
  exit 1
}

# Verify that tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
  error "tmux is not installed. Please install it first."
fi

# Create directory structure
log "Creating directory structure..."
mkdir -p ~/.tmux/{scripts,sessions,backups}

# Backup of existing files
if [ -f ~/.tmux.conf ]; then
  warn "Existing tmux configuration detected"
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp ~/.tmux.conf ~/.tmux/backups/tmux.conf.$timestamp
  log "Backup created at ~/.tmux/backups/tmux.conf.$timestamp"
fi

# Copy scripts
log "Installing scripts..."
cp scripts/tmux-persist.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/tmux-persist.sh

# Merge configuration
log "Configuring tmux..."
{
  if [ -f ~/.tmux.conf ]; then
    cat ~/.tmux.conf
    echo -e "\n# === tmux-session-manager configuration ==="
  fi
  cat config/.tmux.conf
} >~/.tmux.conf.new
mv ~/.tmux.conf.new ~/.tmux.conf

# Configuring shell rc
configure_shell() {
  local rc_file=$1
  if [ -f "$rc_file" ]; then
    if ! grep -q "tmux-session-manager" "$rc_file"; then
      log "Configuring $rc_file..."
      echo '
# tmux-session-manager
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
    ~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
fi' >>"$rc_file"
    else
      warn "Configuration already exists in $rc_file"
    fi
  fi
}

configure_shell ~/.bashrc
configure_shell ~/.zshrc

# Reload tmux if it is in use
if [ -n "$TMUX" ]; then
  log "Reloading tmux configuration..."
  tmux source-file ~/.tmux.conf
fi

log "Installation completed successfully!"
echo -e "
${GREEN}Uso:${NC}
- The sessions are saved automatically when closing them
- The sessions are restored when starting a new tmux session
- Manual commands:
  ${YELLOW}~/.tmux/scripts/tmux-persist.sh save_tmux_sessions${NC}    # Save current sessions
  ${YELLOW}~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions${NC} # Restore saved sessions"
