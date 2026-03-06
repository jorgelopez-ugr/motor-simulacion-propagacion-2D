# Configuración de Proyecto de Godot
# Archivo de referencia - NO es un project.godot real

## Información General
- **Engine**: Godot 4.2+ (GDScript 2.0)
- **Tipo**: 2D
- **Renderer**: Forward+ o Mobile (ambos funcionan)

## Configuración Recomendada

### Display
```
display/window/size/viewport_width = 1280
display/window/size/viewport_height = 720
display/window/size/resizable = true
```

### Autoload (Singletons Globales) - Opcional
Si quieres acceso global al bridge:
```
FireSimulationBridge = "*res://godot/FireSimulationBridge.gd"
```

### Input Map
Añade estas acciones para controles adicionales:

```
"simulation_pause" = Space
"simulation_reset" = R
"simulation_step" = S
"simulation_stop" = Escape
"simulation_speed_up" = Plus, Equal
"simulation_speed_down" = Minus
```

## Estructura de Directorios Recomendada

```
tu_proyecto_godot/
├── project.godot
├── main.tscn                  # Escena principal
├── scenes/
│   ├── fire_simulation.tscn   # Escena de simulación completa
│   └── ui/
│       └── simulation_hud.tscn
├── scripts/
│   ├── FireSimulationBridge.gd
│   ├── FireGridRenderer.gd
│   ├── FireSimulationController.gd
│   └── FireSimulationUI.gd
└── assets/
    ├── fonts/
    ├── icons/
    └── themes/
```

## Importar Scripts

Para usar los scripts de este directorio:

1. Copia todos los archivos `.gd` a tu proyecto de Godot
2. O mantenlos en este directorio y referéncialos con ruta relativa

Ejemplo en Godot si tu proyecto está al mismo nivel:
```gdscript
# Desde: /tu_proyecto_godot/main.gd
# Motor en: /motor-simulacion-propagacion-2D/build/fire_engine
@export var engine_path: String = "../motor-simulacion-propagacion-2D/build/fire_engine"
```

## Testing Rápido

### Opción 1: Ejemplo Simple
1. Crea una nueva escena Node2D
2. Añade `SimpleExample.gd` como script
3. Ajusta la ruta del motor si es necesario
4. Ejecuta (F5) y presiona ESPACIO para avanzar

### Opción 2: Escena Completa
1. Sigue las instrucciones del README.md
2. Crea la estructura de nodos completa
3. Configura los parámetros en el Inspector
4. Ejecuta y usa los controles de teclado/UI

## Notas de Rendimiento

- Grid de 50x50 = 2500 nodos ColorRect (muy eficiente)
- Grid de 100x100 = 10000 nodos (puede ralentizar en hardware antiguo)
- Para grids grandes (>100x100), considera usar:
  - Shader personalizado
  - Texture2D con `set_pixel()`
  - TileMap con autotiling

## Debugging

Activa la consola de Godot para ver los mensajes de debug:
```
Project > Project Settings > Debug > Gdscript > Verbose Gdscript Loading
```

Todos los scripts imprimen mensajes útiles con el prefijo de su clase.
