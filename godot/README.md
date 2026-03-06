# Integración del Motor de Simulación de Fuego con Godot

Este directorio contiene los scripts GDScript necesarios para integrar el motor de simulación de propagación de fuego (C++/Python) con Godot 4.x.

## 📋 Estructura de Archivos

- **`FireSimulationBridge.gd`**: Puente de comunicación entre Godot y el motor C++
- **`FireGridRenderer.gd`**: Renderizador 2D de la grid de simulación
- **`FireSimulationController.gd`**: Controlador principal que orquesta la simulación
- **`FireSimulationUI.gd`**: Interfaz de usuario para controles y estadísticas

## 🎮 Configuración en Godot

### Paso 1: Crear la Escena Principal

1. Crea una nueva escena en Godot con esta estructura:

```
FireSimulation (Node)
├── FireSimulationBridge (Node) [FireSimulationBridge.gd]
├── FireGridRenderer (Node2D) [FireGridRenderer.gd]
│   └── FireSimulationBridge (Node) [Link al bridge del padre]
├── FireSimulationController (Node) [FireSimulationController.gd]
│   ├── FireSimulationBridge (Node) [Link al bridge raíz]
│   └── FireGridRenderer (Node2D) [Link al renderer]
└── CanvasLayer
    └── FireSimulationUI (Control) [FireSimulationUI.gd]
```

### Paso 2: Configurar el FireSimulationBridge

En el Inspector de Godot, configura estos parámetros:

- **Engine Path**: `../build/fire_engine` (ruta relativa al proyecto de Godot)
  - O usa la ruta absoluta completa si prefieres

### Paso 3: Configurar el FireGridRenderer

Parámetros recomendados:

- **Cell Size**: `Vector2(16, 16)` (tamaño de cada celda en píxeles)
- **Grid Width**: `50`
- **Grid Height**: `50`
- **Grid Offset**: `Vector2(10, 10)` (margen desde la esquina)

Colores (puedes personalizarlos):
- **Color Forest**: Verde `#009900`
- **Color Active Fire**: Rojo `#FF3300`
- **Color Embers**: Amarillo `#FFCC00`
- **Color Ash**: Gris `#4D4D4D`

### Paso 4: Configurar el FireSimulationController

- **Auto Start**: `false` (si quieres que inicie automáticamente al abrir)
- **Simulation Delay**: `0.2` segundos entre pasos
- **Max Steps**: `0` (0 = infinito)

### Paso 5: Crear la UI (Opcional pero Recomendado)

Si usas `FireSimulationUI.gd`, crea esta estructura de nodos:

```
FireSimulationUI (Control)
└── MarginContainer
    └── VBoxContainer
        ├── StatsPanel (PanelContainer)
        │   └── StatsGrid (GridContainer)
        │       ├── Label "Paso:"
        │       ├── LabelStep (Label)
        │       ├── Label "Bosque:"
        │       ├── LabelForest (Label)
        │       ├── Label "Fuego:"
        │       ├── LabelFire (Label)
        │       ├── Label "Brasas:"
        │       ├── LabelEmbers (Label)
        │       ├── Label "Ceniza:"
        │       └── LabelAsh (Label)
        ├── StatusPanel (PanelContainer)
        │   └── LabelStatus (Label)
        └── ControlPanel (PanelContainer)
            ├── HBoxContainer
            │   ├── BtnStart (Button) "Iniciar"
            │   ├── BtnPause (Button) "Pausar"
            │   ├── BtnStep (Button) "Paso"
            │   └── BtnReset (Button) "Reset"
            └── SpeedControl (HBoxContainer)
                ├── Label "Velocidad:"
                └── SliderSpeed (HSlider) [min=0, max=100, value=50]
```

## 🎯 Uso

### Controles de Teclado

- **Espacio**: Pausar/Reanudar simulación
- **R**: Resetear simulación
- **S**: Ejecutar un solo paso (cuando está pausado)
- **ESC**: Detener simulación
- **+**: Aumentar velocidad
- **-**: Disminuir velocidad

### Controles de Ratón

- **Click Izquierdo**: Seleccionar celda (implementación futura para ignición manual)

### Desde Código

```gdscript
# Iniciar simulación con dimensiones personalizadas
$FireSimulationController.start_simulation(100, 100)

# Pausar
$FireSimulationController.pause_simulation()

# Reanudar
$FireSimulationController.resume_simulation()

# Ejecutar paso único
$FireSimulationController.step_once()

# Cambiar velocidad
$FireSimulationController.set_simulation_speed(0.1)  # 0.1 segundos por paso

# Obtener información
var info = $FireSimulationController.get_simulation_info()
print("Paso actual: ", info["current_step"])
print("Estadísticas: ", info["statistics"])
```

## 🔧 Solución de Problemas

### Error: "Motor no encontrado"

- Verifica que el ejecutable `fire_engine` existe en `../build/`
- Compila el motor C++ si no existe:
  ```bash
  cd ..
  mkdir -p build && cd build
  cmake ..
  make
  ```

### Error: "No se pudo crear archivo temporal"

- Verifica permisos de escritura en el directorio de datos de usuario de Godot
- En Linux: `~/.local/share/godot/`

### La simulación no se actualiza

- Verifica que las señales estén correctamente conectadas
- Revisa la consola de Godot para mensajes de error
- Asegúrate de que los nodos tengan los nombres correctos según el `@onready`

## 📊 Formato de Estado JSON

El motor C++ intercambia datos con Godot en este formato:

```json
{
  "step": 0,
  "width": 50,
  "height": 50,
  "grid": [
    [0, 0, 1, 0, 0, ...],  // Fila 0
    [0, 0, 0, 0, 0, ...],  // Fila 1
    ...
  ],
  "fuel": [[1.0, 1.0, ...], ...],
  "temperature": [[0.0, 0.0, ...], ...],
  "u": [[0.0, 0.0, ...], ...],
  "v": [[0.0, 0.0, ...], ...],
  "density": [[0.0, 0.0, ...], ...]
}
```

**Estados de celda:**
- `0`: Bosque intacto (verde)
- `1`: Fuego activo (rojo)
- `2`: Brasas/humo (amarillo)
- `3`: Ceniza/quemado (gris)

## 🚀 Próximas Mejoras

- [ ] Ignición manual de celdas con click
- [ ] Visualización de campos de velocidad (flechas)
- [ ] Mapa de calor de temperatura
- [ ] Exportar/Importar estados de simulación
- [ ] Configuración de parámetros físicos desde UI
- [ ] Terreno con elevación (integración con DEM)
- [ ] Viento configurable

## 📝 Notas Técnicas

- Los scripts están diseñados para Godot 4.x (GDScript 2.0)
- La comunicación con el motor C++ usa `OS.execute()` de forma síncrona
- La grid se renderiza con nodos `ColorRect` para mejor rendimiento
- El estado se mantiene en memoria y se pasa al motor en cada paso
