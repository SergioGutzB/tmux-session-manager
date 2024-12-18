#!/bin/bash

set -e

# Colores para mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para imprimir mensajes
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

# Verificar que tmux esté instalado
if ! command -v tmux >/dev/null 2>&1; then
  error "tmux no está instalado. Por favor, instálalo primero."
fi

# Crear estructura de directorios
log "Creando estructura de directorios..."
mkdir -p ~/.tmux/{scripts,sessions,backups}

# Backup de archivos existentes
if [ -f ~/.tmux.conf ]; then
  warn "Detectada configuración existente de tmux"
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp ~/.tmux.conf ~/.tmux/backups/tmux.conf.$timestamp
  log "Backup creado en ~/.tmux/backups/tmux.conf.$timestamp"
fi

# Copiar scripts
log "Instalando scripts..."
cp scripts/tmux-persist.sh ~/.tmux/scripts/
chmod +x ~/.tmux/scripts/tmux-persist.sh

# Fusionar configuración
log "Configurando tmux..."
{
  if [ -f ~/.tmux.conf ]; then
    cat ~/.tmux.conf
    echo -e "\n# === tmux-session-manager configuration ==="
  fi
  cat config/.tmux.conf
} >~/.tmux.conf.new
mv ~/.tmux.conf.new ~/.tmux.conf

# Configurar shell rc
configure_shell() {
  local rc_file=$1
  if [ -f "$rc_file" ]; then
    if ! grep -q "tmux-session-manager" "$rc_file"; then
      log "Configurando $rc_file..."
      echo '
# tmux-session-manager
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then
    ~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
fi' >>"$rc_file"
    else
      warn "Configuración ya existe en $rc_file"
    fi
  fi
}

configure_shell ~/.bashrc
configure_shell ~/.zshrc

# Recargar tmux si está en uso
if [ -n "$TMUX" ]; then
  log "Recargando configuración de tmux..."
  tmux source-file ~/.tmux.conf
fi

log "Instalación completada exitosamente!"
echo -e "
${GREEN}Uso:${NC}
- Las sesiones se guardan automáticamente al cerrarlas
- Las sesiones se restauran al iniciar una nueva sesión de tmux
- Comandos manuales:
  ${YELLOW}~/.tmux/scripts/tmux-persist.sh save_tmux_sessions${NC}    # Guardar sesiones
  ${YELLOW}~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions${NC} # Restaurar sesiones"
