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

# Simulación de gran escala (50x50)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Simulación de propagación de fuego (50x50)"
echo "Lógica probabilística activada."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ejecutar script de demostración con parámetros grandes
# Se reduce el delay para que la visualización sea más fluida
python3 scripts/demo.py --width 15 --height 15 --delay 0.1

echo ""
echo "Simulación finalizada."

