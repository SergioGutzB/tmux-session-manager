#!/bin/bash

# Create bin directory if it doesn't exist
mkdir -p "$HOME/.local/bin"

# Create the CLI wrapper
cat >"$HOME/.local/bin/tmux-manager" <<'EOF'
#!/bin/bash

# Wrapper script for tmux-session-manager
TMUX_SCRIPT="$HOME/.tmux/scripts/tmux-persist.sh"

# Check if the main script exists
if [ ! -f "$TMUX_SCRIPT" ]; then
    echo "Error: tmux-session-manager is not properly installed"
    echo "Please reinstall the package"
    exit 1
fi

# Forward all arguments to the main script
exec "$TMUX_SCRIPT" "$@"
EOF

# Make the CLI wrapper executable
chmod +x "$HOME/.local/bin/tmux-manager"

# Add to PATH if needed
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.zshrc"
  echo "Please restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "CLI installed successfully! You can now use 'tmux-manager' command."
