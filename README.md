# Motor de Simulación de Propagación de Fuego 2D

Motor de simulación en C++ para cálculos de propagación de fuego en 2D, con API Python y visualización en terminal. Como paso previo a la creación del motor volumétrico, este motor más simple permite definir y validar las condiciones del intercambio de datos en JSON con un renderizador 2D en Godot.

## 🔥 Características

- **Motor C++**: Procesa estados en JSON y aplica lógica de propagación de fuego
- **API Python**: Interfaz sencilla para comunicarse con el motor C++
- **Visualizador de Terminal**: Renderiza el estado de la simulación en la consola
- **Formato JSON**: Comunicación estandarizada entre componentes

## 📁 Estructura del Proyecto

```
motor-simulacion-propagacion-2D/
├── src/                      # Código fuente del motor C++
│   ├── fire_engine.hpp       # Clase principal del motor
│   ├── fire_engine.cpp       # Implementación del motor
│   └── main.cpp              # Punto de entrada del ejecutable
├── api/                      # API Python
│   └── fire_simulation_api.py
├── scripts/                  # Scripts de utilidades
│   ├── visualize.py          # Visualizador de terminal
│   └── demo.py               # Script de demostración
├── CMakeLists.txt            # Configuración de CMake
└── README.md                 # Este archivo
```

## 🛠️ Requisitos

### Para el Motor C++
- **CMake** >= 3.10
- **Compilador C++17** (g++, clang++, MSVC)
- **nlohmann/json** (se descarga automáticamente via CMake)

### Para la API y Scripts Python
- **Python** >= 3.8

## 🚀 Instalación y Compilación

### 1. Compilar el Motor C++

```bash
# Desde la raíz del proyecto
mkdir build
cd build
cmake ..
make
```

Esto generará el ejecutable `fire_engine` en el directorio `build/`.

### 2. Verificar la Instalación

```bash
# Desde el directorio build/
./fire_engine --generate 2 2 0
```

Deberías ver la salida JSON del estado inicial.

## Uso

### Motor C++ (Línea de Comandos)

#### Generar Estado Inicial
```bash
./build/fire_engine --generate <width> <height> [step]

# Ejemplos:
./build/fire_engine --generate 2 2 0    # Cuadrícula 2x2, todo verde
./build/fire_engine --generate 2 2 1    # Cuadrícula 2x2, una celda roja
```

#### Procesar Estado desde Archivo
```bash
./build/fire_engine <archivo_entrada.json>

# Ejemplo:
./build/fire_engine state.json
```

### API Python

```python
from api.fire_simulation_api import FireSimulationAPI

# Inicializar API
api = FireSimulationAPI()

# Generar estado inicial (todo verde)
state = api.generate_initial_state(width=2, height=2, step=0)

# Generar estado con una celda en fuego
state = api.generate_initial_state(width=2, height=2, step=1)

# Procesar siguiente estado
next_state = api.process_state(state)

# Ejecutar simulación completa
states = api.run_simulation(width=2, height=2, steps=5)

# Guardar/Cargar estados
api.save_state(state, "estado.json")
loaded_state = api.load_state("estado.json")
```

### Visualizador de Terminal

```bash
# Visualizar desde archivo
python scripts/visualize.py estado.json

# Visualizar desde stdin (pipe)
./build/fire_engine --generate 2 2 1 | python scripts/visualize.py -
```

**Leyenda:**
- `X` = Celda verde (sin fuego)
- `O` = Celda roja (en fuego)

### Script de Demostración

```bash
# Demostración básica (2x2)
python scripts/demo.py

# Cuadrícula personalizada
python scripts/demo.py --width 3 --height 3

# Ajustar velocidad de animación
python scripts/demo.py --delay 2.0

# Guardar estados en archivos JSON
python scripts/demo.py --save

# Ver ayuda
python scripts/demo.py --help
```

## 🔬 Formato JSON

### Estructura del Estado

```json
{
  "step": 0,
  "width": 2,
  "height": 2,
  "grid": [
    [0, 0],
    [0, 0]
  ],
  "cells_ignited": 0
}
```

**Campos:**
- `step`: Número del paso actual
- `width`: Ancho de la cuadrícula
- `height`: Alto de la cuadrícula
- `grid`: Matriz 2D (0 = sin fuego, 1 = en fuego)
- `cells_ignited`: Número de celdas incendiadas en este paso (opcional)

## 🎮 Integración con Godot

El motor está diseñado para integrarse con Godot. El flujo sería:

1. **Godot** envía el estado actual en JSON a la API Python
2. **API Python** comunica con el motor C++ para procesar el estado
3. **Motor C++** devuelve el nuevo estado en JSON
4. **API Python** devuelve el resultado a Godot
5. **Godot** renderiza la visualización 2D

Por ahora, el visualizador de terminal simula lo que Godot haría con la información.

## 🧪 Ejemplo Completo

```bash
# 1. Compilar el motor
mkdir build && cd build
cmake ..
make
cd ..

# 2. Ejecutar demostración
python scripts/demo.py --width 2 --height 2

# 3. Ejemplo manual paso a paso
# Generar estado inicial
./build/fire_engine --generate 2 2 1 > step1.json
python scripts/visualize.py step1.json

# Procesar siguiente estado
./build/fire_engine step1.json > step2.json
python scripts/visualize.py step2.json

# Continuar...
./build/fire_engine step2.json > step3.json
python scripts/visualize.py step3.json
```

## 🎯 Ejemplo de Salida

```
==================================================
  PASO 1
==================================================
  Dimensiones: 2x2

  ┌───────┐
  │ O │ X │
  │ X │ X │
  └───────┘

  ■ Verdes (sin fuego): 3
  ■ Rojas (en fuego): 1
==================================================
```

## 📝 Notas de Desarrollo

- El motor usa propagación simple a celdas adyacentes (arriba, abajo, izquierda, derecha)
- No se considera propagación diagonal
- La lógica de propagación es básica y puede extenderse para simular velocidades de propagación, intensidades, etc.
- El formato JSON facilita la extensión futura del sistema

## 🔮 Próximos Pasos

- [ ] Implementar factores de propagación (viento, humedad, etc.)
- [ ] Añadir diferentes intensidades de fuego
- [ ] Integración real con Godot
- [ ] Optimización para cuadrículas grandes
- [ ] Soporte para obstáculos y zonas resistentes al fuego

## 📄 Licencia

Este proyecto es parte de un TFG (Trabajo de Fin de Grado).

---

**Desarrollado con:** C++17, Python 3, CMake, nlohmann/json
