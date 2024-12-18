#!/bin/bash

TMUX_DIR="$HOME/.tmux"
SESSION_DIR="$TMUX_DIR/sessions"
DEBUG=false

# [Previous functions remain the same until show_help]

show_help() {
  echo "Usage: tmux-manager <command> [arguments]"
  echo ""
  echo "Available commands:"
  echo "  save_tmux_sessions, -s         - Save all current sessions"
  echo "  restore_tmux_sessions, -r      - Restore all sessions from latest backup"
  echo "  save-named, -sn <session> <name> - Save a specific session with a custom name"
  echo "  list-saved, -ls                - Show all saved sessions"
  echo "  restore-named, -rn <name>      - Restore a session by its saved name"
  echo "  help, -h                       - Show this help message"
}

case "$1" in
save_tmux_sessions | -s)
  save_tmux_sessions
  ;;
restore_tmux_sessions | -r)
  restore_tmux_sessions
  ;;
save-named | -sn)
  if [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: tmux-manager save-named|-sn <session_name> <save_name>"
    exit 1
  fi
  save_named_session "$2" "$3"
  ;;
list-saved | -ls)
  list_saved_sessions
  ;;
restore-named | -rn)
  if [ -z "$2" ]; then
    echo "Usage: tmux-manager restore-named|-rn <save_name>"
    exit 1
  fi
  restore_named_session "$2"
  ;;
help | -h)
  show_help
  ;;
*)
  show_help
  exit 1
  ;;
esac
