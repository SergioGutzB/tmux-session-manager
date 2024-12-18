#!/bin/bash

# Enable debug mode to see all executed commands
set -e

TMUX_DIR="$HOME/.tmux"
SESSION_DIR="$TMUX_DIR/sessions"
DEBUG=false

log() {
  if [ "$DEBUG" = true ]; then
    echo "[DEBUG] $1" >&2
  fi
}

error() {
  echo "[ERROR] $1" >&2
  exit 1
}

cleanup_old_sessions() {
  log "Cleaning up old sessions in: $SESSION_DIR"
  find "$SESSION_DIR" -type f -mtime +7 -delete
  log "Old sessions cleanup completed"
}

save_tmux_sessions() {
  log "Starting session save..."

  # Verify tmux is running
  if ! tmux list-sessions &>/dev/null; then
    error "No active tmux sessions detected"
  fi

  # Create necessary directories
  mkdir -p "$SESSION_DIR"
  log "Session directory: $SESSION_DIR"

  # Get timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local session_file="$SESSION_DIR/sessions_$timestamp.txt"
  log "Session file: $session_file"

  # Save session list
  tmux list-sessions -F "#{session_name}" >"$session_file"
  log "Sessions found: $(cat "$session_file" | wc -l)"

  # Create symlink to latest session
  ln -sf "$session_file" "$SESSION_DIR/latest"

  # Save each session
  while read -r session; do
    log "Processing session: $session"

    # Save window information
    local windows_file="$SESSION_DIR/${session}_windows_$timestamp.txt"
    tmux list-windows -t "$session" -F "#{window_index} #{window_name} #{window_layout}" >"$windows_file"
    log "Windows saved to: $windows_file"

    # Save pane information
    local panes_file="$SESSION_DIR/${session}_panes_$timestamp.txt"
    tmux list-panes -t "$session" -F "#{window_index} #{pane_index} #{pane_current_path}" >"$panes_file"
    log "Panes saved to: $panes_file"
  done <"$session_file"

  # Validate that sessions were saved
  log "Validating saved sessions..."
  ls -la "$SESSION_DIR"

  log "Sessions saved successfully"
}

restore_tmux_sessions() {
  local latest_session="$SESSION_DIR/latest"

  if [ ! -f "$latest_session" ]; then
    log "No saved sessions to restore"
    return 0
  fi

  local timestamp=$(basename "$(readlink "$latest_session")" .txt | cut -d'_' -f2-)
  log "Restoring sessions from timestamp: $timestamp"

  while read -r session; do
    log "Restoring session: $session"

    # Create new session
    tmux new-session -d -s "$session" 2>/dev/null || continue

    # Restore windows
    if [ -f "$SESSION_DIR/${session}_windows_$timestamp.txt" ]; then
      while read -r window_info; do
        read -r window_index window_name layout <<<"$window_info"

        if [ "$window_index" -ne 0 ]; then
          tmux new-window -t "${session}:${window_index}" -n "$window_name"
        fi

        tmux select-layout -t "${session}:${window_index}" "$layout" 2>/dev/null || true
      done <"$SESSION_DIR/${session}_windows_$timestamp.txt"
    fi

    # Restore working directories
    if [ -f "$SESSION_DIR/${session}_panes_$timestamp.txt" ]; then
      while read -r pane_info; do
        read -r window_index pane_index pane_path <<<"$pane_info"
        if [ -d "$pane_path" ]; then
          tmux send-keys -t "${session}:${window_index}.${pane_index}" "cd \"$pane_path\"" C-m
        fi
      done <"$SESSION_DIR/${session}_panes_$timestamp.txt"
    fi
  done <"$latest_session"

  log "Sessions restored successfully"
}

save_named_session() {
  local session_name="$1"
  local save_name="$2"

  # Check if session exists
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    error "Session '$session_name' does not exist"
  fi

  mkdir -p "$SESSION_DIR/named"
  local save_dir="$SESSION_DIR/named/$save_name"
  mkdir -p "$save_dir"

  log "Saving session '$session_name' as '$save_name'"

  # Save metadata
  echo "$session_name" >"$save_dir/session_name.txt"
  date +%Y%m%d_%H%M%S >"$save_dir/timestamp.txt"

  # Save window and pane information
  tmux list-windows -t "$session_name" -F "#{window_index} #{window_name} #{window_layout}" \
    >"$save_dir/windows.txt"
  tmux list-panes -t "$session_name" -F "#{window_index} #{pane_index} #{pane_current_path}" \
    >"$save_dir/panes.txt"

  echo "Session successfully saved as '$save_name'"
}

list_saved_sessions() {
  # Check for automatic backups first
  if [ -f "$SESSION_DIR/latest" ] && [ -L "$SESSION_DIR/latest" ]; then
    local timestamp=$(basename "$(readlink "$SESSION_DIR/latest")" .txt | sed 's/sessions_//')
    printf "\nAutomatic Backup (%s):\n" "$timestamp"
    if [ -f "$SESSION_DIR/latest" ]; then
      printf "  %-20s %s\n" "SESSION NAME" "WINDOWS"
      printf "  %-20s %s\n" "-----------" "-------"
      while read -r session; do
        local window_count=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
        printf "  %-20s %d\n" "$session" "${window_count:-0}"
      done <"$SESSION_DIR/latest"
    fi
  fi

  # Check for named sessions
  if [ -d "$SESSION_DIR/named" ] && [ "$(ls -A "$SESSION_DIR/named" 2>/dev/null)" ]; then
    printf "\nNamed Sessions:\n"
    printf "  %-20s %-20s %s\n" "SAVED NAME" "ORIGINAL NAME" "SAVED ON"
    printf "  %-20s %-20s %s\n" "----------" "-------------" "--------"
    for dir in "$SESSION_DIR/named"/*/; do
      if [ -d "$dir" ] && [ -f "$dir/session_name.txt" ] && [ -f "$dir/timestamp.txt" ]; then
        local save_name=$(basename "$dir")
        local session_name=$(cat "$dir/session_name.txt")
        local timestamp=$(cat "$dir/timestamp.txt")
        printf "  %-20s %-20s %s\n" "$save_name" "$session_name" "$timestamp"
      fi
    done
  fi

  # If no sessions found, show simple message
  if [ ! -f "$SESSION_DIR/latest" ] && [ ! -d "$SESSION_DIR/named" ]; then
    echo "No saved sessions found."
  fi

  echo # Empty line at end
}

restore_named_session() {
  local save_name="$1"
  local save_dir="$SESSION_DIR/named/$save_name"

  if [ ! -d "$save_dir" ]; then
    error "Saved session not found: $save_name"
  fi

  local session_name=$(cat "$save_dir/session_name.txt")

  # Create new session
  tmux new-session -d -s "$session_name" 2>/dev/null || {
    error "Could not create session: $session_name (Already exists?)"
    exit 1
  }

  # Restore windows
  if [ -f "$save_dir/windows.txt" ]; then
    while read -r window_info; do
      read -r window_index window_name layout <<<"$window_info"

      if [ "$window_index" -ne 0 ]; then
        tmux new-window -t "${session_name}:${window_index}" -n "$window_name"
      fi

      tmux select-layout -t "${session_name}:${window_index}" "$layout" 2>/dev/null || true
    done <"$save_dir/windows.txt"
  fi

  # Restore working directories
  if [ -f "$save_dir/panes.txt" ]; then
    while read -r pane_info; do
      read -r window_index pane_index pane_path <<<"$pane_info"
      if [ -d "$pane_path" ]; then
        tmux send-keys -t "${session_name}:${window_index}.${pane_index}" "cd \"$pane_path\"" C-m
      fi
    done <"$save_dir/panes.txt"
  fi

  echo "Session '$session_name' restored successfully"
  echo "You can attach to it using: tmux attach -t $session_name"
}

show_help() {
  echo "tmux-manager - Tmux Session Manager"
  echo
  echo "Usage: tmux-manager <command> [arguments]"
  echo
  echo "Commands:"
  printf "  %-30s %-20s %s\n" "save_tmux_sessions, -s" "" "Save all current sessions"
  printf "  %-30s %-20s %s\n" "restore_tmux_sessions, -r" "" "Restore all sessions from latest backup"
  printf "  %-30s %-20s %s\n" "save-named, -sn" "<session> <name>" "Save a specific session with a custom name"
  printf "  %-30s %-20s %s\n" "list-saved, -ls" "" "Show all saved sessions"
  printf "  %-30s %-20s %s\n" "restore-named, -rn" "<name>" "Restore a session by its saved name"
  printf "  %-30s %-20s %s\n" "help, -h" "" "Show this help message"
  echo
  echo "Examples:"
  echo "  tmux-manager -ls                          # List all saved sessions"
  echo "  tmux-manager -sn development project1     # Save 'development' session as 'project1'"
  echo "  tmux-manager -rn project1                 # Restore session named 'project1'"
  echo "  tmux-manager -s                          # Save all current sessions"
}

case "$1" in
save_tmux_sessions)
  save_tmux_sessions
  ;;
restore_tmux_sessions)
  restore_tmux_sessions
  ;;
save-named)
  if [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 save-named <session_name> <save_name>"
    exit 1
  fi
  save_named_session "$2" "$3"
  ;;
list-saved)
  list_saved_sessions
  ;;
restore-named)
  if [ -z "$2" ]; then
    echo "Usage: $0 restore-named <save_name>"
    exit 1
  fi
  restore_named_session "$2"
  ;;
help)
  show_help
  ;;
*)
  show_help
  exit 1
  ;;
esac
