# Tmux Session Manager

A session manager for tmux that enables persistent saving and restoring of sessions. Maintains the state of your windows, panes, and working directories between system restarts.

## Features

- ✨ Save and restore tmux sessions
- 🔄 Automatic restoration of layouts and working directories
- 📝 Custom naming for saved sessions
- 🔍 List available sessions
- 🗑️ Automatic cleanup of old backups
- ⚡ Support for multiple sessions
- 🎯 CLI with short commands for quick access

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/tmux-session-manager.git

# Enter directory
cd tmux-session-manager

# Run installer
./install.sh

# Install CLI wrapper (optional but recommended)
./install-cli.sh

# Reload your shell or update PATH manually
export PATH="$HOME/.local/bin:$PATH"
```

## CLI Usage

The CLI provides both full and short commands for easier use:

### Quick Reference

| Short Command | Long Command | Description | Example |
|--------------|--------------|-------------|----------|
| `-h` | `help` | Show help message | `tmux-manager -h` |
| `-ls` | `list-saved` | List all saved sessions | `tmux-manager -ls` |
| `-s` | `save_tmux_sessions` | Save all current sessions | `tmux-manager -s` |
| `-r` | `restore_tmux_sessions` | Restore all sessions | `tmux-manager -r` |
| `-sn` | `save-named` | Save session with name | `tmux-manager -sn dev project1` |
| `-rn` | `restore-named` | Restore named session | `tmux-manager -rn project1` |

### Examples

1. Save current session with a name:
```bash
tmux-manager -sn development project_web
# or
tmux-manager save-named development project_web
```

2. List all saved sessions:
```bash
tmux-manager -ls
# or
tmux-manager list-saved
```

3. Restore a specific session:
```bash
tmux-manager -rn project_web
# or
tmux-manager restore-named project_web
```

4. Save all current sessions:
```bash
tmux-manager -s
# or
tmux-manager save_tmux_sessions
```

## Usage witout CLI

### Basic Commands

1. View all available commands:
```bash
~/.tmux/scripts/tmux-persist.sh help
```

2. List saved sessions:
```bash
~/.tmux/scripts/tmux-persist.sh list-saved
```

### Saving Sessions

1. Save all active sessions:
```bash
~/.tmux/scripts/tmux-persist.sh save_tmux_sessions
```

2. Save a specific session with a custom name:
```bash
~/.tmux/scripts/tmux-persist.sh save-named current_session_name save_name
```

Example:
```bash
# Save the "development" session as "web_project"
~/.tmux/scripts/tmux-persist.sh save-named development web_project
```

### Restoring Sessions

1. Restore all sessions from the latest backup:
```bash
~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
```

2. Restore a specific session by name:
```bash
~/.tmux/scripts/tmux-persist.sh restore-named save_name
```

Example:
```bash
# Restore the session saved as "web_project"
~/.tmux/scripts/tmux-persist.sh restore-named web_project
```

### Workflow Examples

#### Example 1: Save development session
```bash
# 1. Create new session
tmux new-session -s development

# 2. Set up your environment (create windows, panes, etc.)

# 3. Save the session
~/.tmux/scripts/tmux-persist.sh save-named development my_project

# 4. Verify it was saved
~/.tmux/scripts/tmux-persist.sh list-saved

# 5. Later, restore the session
~/.tmux/scripts/tmux-persist.sh restore-named my_project
```

#### Example 2: Backup all sessions
```bash
# 1. Save all active sessions
~/.tmux/scripts/tmux-persist.sh save_tmux_sessions

# 2. After a restart, restore all sessions
~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
```

## Command Summary

| Command | Description | Example |
|---------|-------------|---------|
| `help` | Show help message | `~/.tmux/scripts/tmux-persist.sh help` |
| `save_tmux_sessions` | Save all sessions | `~/.tmux/scripts/tmux-persist.sh save_tmux_sessions` |
| `restore_tmux_sessions` | Restore all sessions | `~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions` |
| `save-named` | Save a session with name | `~/.tmux/scripts/tmux-persist.sh save-named current saved` |
| `list-saved` | List saved sessions | `~/.tmux/scripts/tmux-persist.sh list-saved` |
| `restore-named` | Restore a session by name | `~/.tmux/scripts/tmux-persist.sh restore-named saved` |

## File Structure

```
~/.tmux/
├── scripts/
│   └── tmux-persist.sh
├── sessions/
│   ├── latest -> sessions_[timestamp].txt
│   ├── sessions_[timestamp].txt
│   └── named/
│       └── [save_name]/
│           ├── session_name.txt
│           ├── timestamp.txt
│           ├── windows.txt
│           └── panes.txt
└── backups/
    └── tmux.conf.[timestamp]
```

## Troubleshooting

### Sessions are not saving
- Verify tmux is running
- Check permissions of ~/.tmux/sessions directory
- Ensure the script has execution permissions

### Sessions are not restoring
- Verify files exist in ~/.tmux/sessions
- Check that no sessions with the same name are already running
- Review logs with debug mode enabled

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
