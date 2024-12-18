#!/bin/bash

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
  find "$SESSION_DIR" -type f -mtime +7 -delete
  log "Limpieza de sesiones antiguas completada"
}

save_tmux_sessions() {
  mkdir -p "$SESSION_DIR"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local session_file="$SESSION_DIR/sessions_$timestamp.txt"

  log "Guardando sesiones en $session_file"

  # Crear enlace simbólico a la última sesión
  ln -sf "$session_file" "$SESSION_DIR/latest"

  # Guardar lista de sesiones
  tmux list-sessions -F "#{session_name}" >"$session_file"

  while read -r session; do
    log "Procesando sesión: $session"

    # Guardar información de ventanas
    tmux list-windows -t "$session" -F "#{window_index} #{window_name} #{window_layout}" \
      >"$SESSION_DIR/${session}_windows_$timestamp.txt"

    # Guardar directorios de trabajo de los paneles
    tmux list-panes -t "$session" -F "#{window_index} #{pane_index} #{pane_current_path}" \
      >"$SESSION_DIR/${session}_panes_$timestamp.txt"
  done <"$session_file"

  cleanup_old_sessions
  log "Sesiones guardadas exitosamente"
}

restore_tmux_sessions() {
  local latest_session="$SESSION_DIR/latest"

  if [ ! -f "$latest_session" ]; then
    log "No hay sesiones guardadas para restaurar"
    return 0
  fi

  local timestamp=$(basename "$(readlink "$latest_session")" .txt | cut -d'_' -f2-)
  log "Restaurando sesiones de timestamp: $timestamp"

  while read -r session; do
    log "Restaurando sesión: $session"

    # Crear nueva sesión
    tmux new-session -d -s "$session" 2>/dev/null || continue

    # Restaurar ventanas
    while read -r window_info; do
      read -r window_index window_name layout <<<"$window_info"

      if [ "$window_index" -ne 0 ]; then
        tmux new-window -t "${session}:${window_index}" -n "$window_name"
      fi

      tmux select-layout -t "${session}:${window_index}" "$layout" 2>/dev/null || true
    done <"$SESSION_DIR/${session}_windows_$timestamp.txt"

    # Restaurar directorios de trabajo
    while read -r pane_info; do
      read -r window_index pane_index pane_path <<<"$pane_info"
      if [ -d "$pane_path" ]; then
        tmux send-keys -t "${session}:${window_index}.${pane_index}" "cd \"$pane_path\"" C-m
      fi
    done <"$SESSION_DIR/${session}_panes_$timestamp.txt"
  done <"$latest_session"

  log "Sesiones restauradas exitosamente"
}

case "$1" in
save_tmux_sessions)
  save_tmux_sessions
  ;;
restore_tmux_sessions)
  restore_tmux_sessions
  ;;
*)
  error "Uso: $0 {save_tmux_sessions|restore_tmux_sessions}"
  ;;
esac
