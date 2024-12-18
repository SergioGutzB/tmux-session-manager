#!/bin/bash

set -e

TMUX_DIR="$HOME/.tmux"
SESSION_DIR="$TMUX_DIR/sessions"
DEBUG=true

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
  log "Iniciando guardado de sesiones..."

  # Verificar que tmux está corriendo
  if ! tmux list-sessions &>/dev/null; then
    error "No se detectaron sesiones de tmux activas"
  fi

  # Crear directorios necesarios
  mkdir -p "$SESSION_DIR"
  log "Directorio de sesiones: $SESSION_DIR"

  # Obtener timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local session_file="$SESSION_DIR/sessions_$timestamp.txt"
  log "Archivo de sesiones: $session_file"

  # Guardar lista de sesiones
  tmux list-sessions -F "#{session_name}" >"$session_file"
  log "Sesiones encontradas: $(cat "$session_file" | wc -l)"

  # Crear enlace a la última sesión
  ln -sf "$session_file" "$SESSION_DIR/latest"

  # Guardar cada sesión
  while read -r session; do
    log "Procesando sesión: $session"

    # Guardar información de ventanas
    local windows_file="$SESSION_DIR/${session}_windows_$timestamp.txt"
    tmux list-windows -t "$session" -F "#{window_index} #{window_name} #{window_layout}" >"$windows_file"
    log "Ventanas guardadas en: $windows_file"

    # Guardar información de paneles
    local panes_file="$SESSION_DIR/${session}_panes_$timestamp.txt"
    tmux list-panes -t "$session" -F "#{window_index} #{pane_index} #{pane_current_path}" >"$panes_file"
    log "Paneles guardados en: $panes_file"
  done <"$session_file"

  # Verificar que los archivos se crearon
  log "Verificando archivos guardados:"
  ls -la "$SESSION_DIR"

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
    if [ -f "$SESSION_DIR/${session}_windows_$timestamp.txt" ]; then
      while read -r window_info; do
        read -r window_index window_name layout <<<"$window_info"

        if [ "$window_index" -ne 0 ]; then
          tmux new-window -t "${session}:${window_index}" -n "$window_name"
        fi

        tmux select-layout -t "${session}:${window_index}" "$layout" 2>/dev/null || true
      done <"$SESSION_DIR/${session}_windows_$timestamp.txt"
    fi

    # Restaurar directorios de trabajo
    if [ -f "$SESSION_DIR/${session}_panes_$timestamp.txt" ]; then
      while read -r pane_info; do
        read -r window_index pane_index pane_path <<<"$pane_info"
        if [ -d "$pane_path" ]; then
          tmux send-keys -t "${session}:${window_index}.${pane_index}" "cd \"$pane_path\"" C-m
        fi
      done <"$SESSION_DIR/${session}_panes_$timestamp.txt"
    fi
  done <"$latest_session"

  log "Sesiones restauradas exitosamente"
}

save_named_session() {
  local session_name="$1"
  local save_name="$2"

  # Verificar si la sesión existe
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    error "La sesión '$session_name' no existe"
  fi

  mkdir -p "$SESSION_DIR/named"
  local save_dir="$SESSION_DIR/named/$save_name"
  mkdir -p "$save_dir"

  log "Guardando sesión '$session_name' como '$save_name'"

  # Guardar metadata
  echo "$session_name" >"$save_dir/session_name.txt"
  date +%Y%m%d_%H%M%S >"$save_dir/timestamp.txt"

  # Guardar información de ventanas y paneles
  tmux list-windows -t "$session_name" -F "#{window_index} #{window_name} #{window_layout}" \
    >"$save_dir/windows.txt"
  tmux list-panes -t "$session_name" -F "#{window_index} #{pane_index} #{pane_current_path}" \
    >"$save_dir/panes.txt"

  echo "Sesión guardada exitosamente como '$save_name'"
}

list_saved_sessions() {
  log "Buscando sesiones guardadas..."

  # Verificar directorio de sesiones
  if [ ! -d "$SESSION_DIR" ]; then
    log "Directorio de sesiones no existe: $SESSION_DIR"
    echo "No hay sesiones guardadas"
    return
  fi

  # Buscar sesiones automáticas
  if [ -f "$SESSION_DIR/latest" ]; then
    echo "Sesiones automáticas:"
    echo "--------------------"
    local timestamp=$(basename "$(readlink "$SESSION_DIR/latest")" .txt | sed 's/sessions_//')
    echo "Último backup: $timestamp"
    echo "Sesiones:"
    sed 's/^/  - /' "$SESSION_DIR/latest"
    echo "--------------------"
  fi

  # Buscar sesiones con nombre
  if [ -d "$SESSION_DIR/named" ]; then
    echo "Sesiones con nombre:"
    echo "--------------------"
    for dir in "$SESSION_DIR/named"/*/; do
      if [ -d "$dir" ]; then
        local save_name=$(basename "$dir")
        if [ -f "$dir/session_name.txt" ] && [ -f "$dir/timestamp.txt" ]; then
          local session_name=$(cat "$dir/session_name.txt")
          local timestamp=$(cat "$dir/timestamp.txt")
          echo "Nombre guardado: $save_name"
          echo "  Sesión original: $session_name"
          echo "  Timestamp: $timestamp"
          echo "--------------------"
        fi
      fi
    done
  fi

  # Si no se encontró nada
  if [ ! -f "$SESSION_DIR/latest" ] && [ ! -d "$SESSION_DIR/named" ]; then
    echo "No hay sesiones guardadas"
  fi
}

restore_named_session() {
  local save_name="$1"
  local save_dir="$SESSION_DIR/named/$save_name"

  if [ ! -d "$save_dir" ]; then
    error "No se encontró la sesión guardada: $save_name"
  fi

  local session_name=$(cat "$save_dir/session_name.txt")

  # Crear nueva sesión
  tmux new-session -d -s "$session_name" 2>/dev/null || {
    error "No se pudo crear la sesión: $session_name (¿ya existe?)"
    exit 1
  }

  # Restaurar ventanas
  if [ -f "$save_dir/windows.txt" ]; then
    while read -r window_info; do
      read -r window_index window_name layout <<<"$window_info"

      if [ "$window_index" -ne 0 ]; then
        tmux new-window -t "${session_name}:${window_index}" -n "$window_name"
      fi

      tmux select-layout -t "${session_name}:${window_index}" "$layout" 2>/dev/null || true
    done <"$save_dir/windows.txt"
  fi

  # Restaurar directorios de trabajo
  if [ -f "$save_dir/panes.txt" ]; then
    while read -r pane_info; do
      read -r window_index pane_index pane_path <<<"$pane_info"
      if [ -d "$pane_path" ]; then
        tmux send-keys -t "${session_name}:${window_index}.${pane_index}" "cd \"$pane_path\"" C-m
      fi
    done <"$save_dir/panes.txt"
  fi

  echo "Sesión '$session_name' restaurada exitosamente"
  echo "Puedes conectarte usando: tmux attach -t $session_name"
}

# Menú de ayuda
show_help() {
  echo "Uso: $0 <comando> [argumentos]"
  echo ""
  echo "Comandos disponibles:"
  echo "  save_tmux_sessions              - Guarda todas las sesiones actuales"
  echo "  restore_tmux_sessions           - Restaura todas las sesiones del último backup"
  echo "  save-named <sesión> <nombre>    - Guarda una sesión específica con un nombre"
  echo "  list-saved                      - Muestra las sesiones guardadas con nombre"
  echo "  restore-named <nombre>          - Restaura una sesión guardada por nombre"
  echo "  help                            - Muestra esta ayuda"
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
    echo "Uso: $0 save-named <nombre_sesion_actual> <nombre_guardado>"
    exit 1
  fi
  save_named_session "$2" "$3"
  ;;
list-saved)
  list_saved_sessions
  ;;
restore-named)
  if [ -z "$2" ]; then
    echo "Uso: $0 restore-named <nombre_guardado>"
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
