#!/bin/bash
# Script de ejemplos de uso del motor de simulación

echo "=========================================="
echo "  EJEMPLOS DE USO - Motor de Fuego 2D"
echo "=========================================="
echo ""

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$PROJECT_ROOT"

# Verificar que el motor esté compilado
if [ ! -f "build/fire_engine" ]; then
    echo "Error: El motor no está compilado."
    echo "Por favor ejecuta primero:"
    echo "  mkdir build && cd build && cmake .. && make"
    exit 1
fi

echo "Motor encontrado"
echo ""

# Ejemplo 1: Generar y visualizar estado inicial
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ejemplo 1: Estado inicial (todo verde)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./build/fire_engine --generate 2 2 0 | python3 scripts/visualize.py -
echo ""
read -p "Presiona Enter para continuar..."
echo ""

# Ejemplo 2: Estado con una celda en fuego
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ejemplo 2: Primera celda incendiada"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./build/fire_engine --generate 2 2 1 | python3 scripts/visualize.py -
echo ""
read -p "Presiona Enter para continuar..."
echo ""

# Ejemplo 3: Procesamiento paso a paso
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ejemplo 3: Procesamiento paso a paso"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Crear estado inicial
./build/fire_engine --generate 2 2 1 > /tmp/step1.json
echo "Paso 1:"
python3 scripts/visualize.py /tmp/step1.json

# Procesar siguiente paso
./build/fire_engine /tmp/step1.json > /tmp/step2.json
echo "Paso 2:"
python3 scripts/visualize.py /tmp/step2.json

# Procesar siguiente paso
./build/fire_engine /tmp/step2.json > /tmp/step3.json
echo "Paso 3:"
python3 scripts/visualize.py /tmp/step3.json

# Limpiar archivos temporales
rm /tmp/step*.json

echo ""
read -p "Presiona Enter para continuar..."
echo ""

# Ejemplo 4: Demostración animada 2x2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ejemplo 4: Simulación animada 2x2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python3 scripts/demo.py --width 2 --height 2 --delay 0.8
echo ""
read -p "Presiona Enter para continuar..."
echo ""

# Ejemplo 5: Demostración con cuadrícula más grande
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ejemplo 5: Simulación animada 4x4"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python3 scripts/demo.py --width 4 --height 4 --delay 0.5
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Todos los ejemplos completados"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Para más opciones, consulta el README.md"
