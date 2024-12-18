# tmux-session-manager

Gestor de sesiones persistentes para tmux con soporte para configuraciones existentes y restauración automática.

## Características

- ✨ Persistencia automática de sesiones
- 🔄 Restauración automática al iniciar
- 📁 Preservación de directorios de trabajo
- 🧩 Compatibilidad con configuraciones existentes
- 🔒 Backup automático de configuraciones
- 🧹 Limpieza automática de sesiones antiguas
- 📝 Logging detallado (modo debug opcional)

## Requisitos

- tmux ≥ 2.1
- bash ≥ 4.0

## Instalación

```bash
git clone https://github.com/TU_USUARIO/tmux-session-manager.git
cd tmux-session-manager
./install.sh
```

## Características Detalladas

### Manejo de Configuraciones Existentes

- Realiza backup automático de configuraciones existentes
- Preserva configuraciones personalizadas
- Integración no destructiva con .tmux.conf existente

### Gestión de Sesiones

- Guarda automáticamente al cerrar sesiones
- Guarda automáticamente al desconectar cliente
- Mantiene historial de sesiones por 7 días
- Restaura layout de ventanas y paneles
- Restaura directorios de trabajo

### Seguridad y Confiabilidad

- Verifica existencia de directorios antes de restaurar
- Manejo de errores robusto
- Logging detallado en modo debug

## Uso

### Automático
Las sesiones se guardan y restauran automáticamente.

### Manual
```bash
# Guardar sesiones
~/.tmux/scripts/tmux-persist.sh save_tmux_sessions

# Restaurar sesiones
~/.tmux/scripts/tmux-persist.sh restore_tmux_sessions
```

### Debug
Para activar el modo debug, edita scripts/tmux-persist.sh y cambia:
```bash
DEBUG=false
```
a
```bash
DEBUG=true
```

## Estructura de Archivos

```
~/.tmux/
├── scripts/
│   └── tmux-persist.sh
├── sessions/
│   ├── latest -> sessions_20241218_120000.txt
│   ├── sessions_20241218_120000.txt
│   ├── session_name_windows_20241218_120000.txt
│   └── session_name_panes_20241218_120000.txt
└── backups/
    └── tmux.conf.20241218_120000
```

## Solución de Problemas

### Las sesiones no se restauran
- Verifica que tmux esté instalado y funcionando
- Comprueba los permisos de ~/.tmux/scripts/tmux-persist.sh
- Activa el modo debug para más información

### Conflictos con configuración existente
- Revisa los backups en ~/.tmux/backups/
- Edita manualmente ~/.tmux.conf si es necesario

## Contribuir

1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para más información.
