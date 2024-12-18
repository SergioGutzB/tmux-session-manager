# Tmux Session Manager

Un gestor de sesiones para tmux que permite guardar y restaurar sesiones de forma persistente. Mantiene el estado de tus ventanas, paneles y directorios de trabajo entre reinicios del sistema.

## Características

- ✨ Guarda y restaura sesiones de tmux
- 🔄 Restauración automática de layouts y directorios de trabajo
- 📝 Nombrado personalizado de sesiones guardadas
- 🔍 Listado de sesiones disponibles
- 🗑️ Limpieza automática de backups antiguos
- ⚡ Soporte para múltiples sesiones

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/tmux-session-manager.git

# Entrar al directorio
cd tmux-session-manager

# Ejecutar el instalador
./install.sh
```

## Uso

### Comandos Básicos

1. Ver todos los comandos disponibles:
```bash
~/.tmux/scripts/tmux-persist.sh help
```

2. Listar sesiones guardadas:
```bash
~/.tmux/scripts/tmux-persist.sh list-saved
```

### Guardar Sesiones

1. Guardar todas las sesiones activas:
```bash
~/.tmux/scripts/tmux-persist.sh save_tmux_sessions
```

2. Guardar una sesión específica con nombre personalizado:
```bash
~/.tmux/scripts/tmux-persist.sh save-named nombre_sesion_actual nombre_guardado
```

Ejemplo:
```bash
# Guardar la sesión "desarrollo" como "proyecto_web"
~/.tmux/scripts/tmux-persist.sh save-named desarrollo proyecto_web
```

### Restaurar Sesiones

1. Restaurar todas las sesiones del último backup:
```bash
~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
```

2. Restaurar una sesión específica por nombre:
```bash
~/.tmux/scripts/tmux-persist.sh restore-named nombre_guardado
```

Ejemplo:
```bash
# Restaurar la sesión guardada como "proyecto_web"
~/.tmux/scripts/tmux-persist.sh restore-named proyecto_web
```

### Ejemplos de Flujo de Trabajo

#### Ejemplo 1: Guardar sesión de desarrollo
```bash
# 1. Crear nueva sesión
tmux new-session -s desarrollo

# 2. Configurar tu entorno (crear ventanas, paneles, etc.)

# 3. Guardar la sesión
~/.tmux/scripts/tmux-persist.sh save-named desarrollo mi_proyecto

# 4. Verificar que se guardó
~/.tmux/scripts/tmux-persist.sh list-saved

# 5. Más tarde, restaurar la sesión
~/.tmux/scripts/tmux-persist.sh restore-named mi_proyecto
```

#### Ejemplo 2: Backup de todas las sesiones
```bash
# 1. Guardar todas las sesiones activas
~/.tmux/scripts/tmux-persist.sh save_tmux_sessions

# 2. Después de un reinicio, restaurar todas las sesiones
~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
```

## Resumen de Comandos

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `help` | Muestra la ayuda | `~/.tmux/scripts/tmux-persist.sh help` |
| `save_tmux_sessions` | Guarda todas las sesiones | `~/.tmux/scripts/tmux-persist.sh save_tmux_sessions` |
| `restore_tmux_sessions` | Restaura todas las sesiones | `~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions` |
| `save-named` | Guarda una sesión con nombre | `~/.tmux/scripts/tmux-persist.sh save-named actual guardado` |
| `list-saved` | Lista las sesiones guardadas | `~/.tmux/scripts/tmux-persist.sh list-saved` |
| `restore-named` | Restaura una sesión por nombre | `~/.tmux/scripts/tmux-persist.sh restore-named guardado` |

## Estructura de Archivos

```
~/.tmux/
├── scripts/
│   └── tmux-persist.sh
├── sessions/
│   ├── latest -> sessions_[timestamp].txt
│   ├── sessions_[timestamp].txt
│   └── named/
│       └── [nombre_guardado]/
│           ├── session_name.txt
│           ├── timestamp.txt
│           ├── windows.txt
│           └── panes.txt
└── backups/
    └── tmux.conf.[timestamp]
```

## Solución de Problemas

### Las sesiones no se guardan
- Verifica que tmux esté ejecutándose
- Comprueba los permisos del directorio ~/.tmux/sessions
- Asegúrate de que el script tiene permisos de ejecución

### Las sesiones no se restauran
- Verifica que los archivos existen en ~/.tmux/sessions
- Comprueba que no hay sesiones con el mismo nombre ya ejecutándose
- Revisa los logs con el modo debug activado

## Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/NuevaCaracteristica`)
3. Commit tus cambios (`git commit -m 'Añade nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Crea un Pull Request

## Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.
