#!/usr/bin/env python3
"""
Script de demostración que ejecuta una simulación completa de propagación de fuego
y visualiza cada paso en la terminal.
"""

import sys
import time
import argparse
from pathlib import Path

# Agregar el directorio api al path para poder importar
sys.path.insert(0, str(Path(__file__).parent.parent / "api"))

from fire_simulation_api import FireSimulationAPI
from visualize import TerminalVisualizer


def run_demo(width: int = 2, height: int = 2, delay: float = 1.5, save_states: bool = False):
    """
    Ejecuta una demostración de la simulación.
    
    Args:
        width: Ancho de la cuadrícula
        height: Alto de la cuadrícula
        delay: Tiempo de espera entre pasos (en segundos)
        save_states: Si True, guarda los estados en archivos JSON
    """
    print("=" * 60)
    print("  SIMULACIÓN DE PROPAGACIÓN DE FUEGO 2D")
    print("=" * 60)
    print(f"\n  Configuración: cuadrícula de {width}x{height}")
    print(f"  Leyenda: X = verde (sin fuego), O = rojo (en fuego)")
    print("\n  Presiona Ctrl+C para detener la simulación")
    print("=" * 60)
    
    try:
        # Inicializar API
        api = FireSimulationAPI()
        visualizer = TerminalVisualizer()
        
        # Paso 0: Estado inicial (todo verde)
        print("\n🟢 Inicializando simulación...")
        time.sleep(delay / 2)
        
        state = api.generate_initial_state(width, height, step=0)
        visualizer.render_state(state)
        
        if save_states:
            api.save_state(state, f"state_step_{state['step']}.json")
        
        time.sleep(delay)
        
        # Paso 1: Primera celda se incendia
        print("\n¡Fuego detectado! Una celda se ha incendiado...")
        time.sleep(delay / 2)
        
        state = api.generate_initial_state(width, height, step=1)
        visualizer.render_state(state)
        
        if save_states:
            api.save_state(state, f"state_step_{state['step']}.json")
        
        time.sleep(delay)
        
        # Pasos siguientes: Propagación
        max_steps = width * height  # En el peor caso, se queman todas las celdas
        
        for i in range(max_steps):
            # Verificar si todas las celdas están en fuego
            total_cells = width * height
            fire_cells = sum(row.count(1) for row in state['grid'])
            
            if fire_cells >= total_cells:
                print("\n¡TODAS LAS CELDAS ESTÁN EN FUEGO!")
                print("  La simulación ha terminado.")
                break
            
            print(f"\nPropagando fuego (paso {i + 2})...")
            time.sleep(delay / 2)
            
            state = api.process_state(state)
            visualizer.render_state(state)
            
            if save_states:
                api.save_state(state, f"state_step_{state['step']}.json")
            
            # Si no se incendiaron nuevas celdas, la simulación ha terminado
            if state.get('cells_ignited', 0) == 0:
                print("\n✓ No hay más celdas para propagar.")
                print("  La simulación ha terminado.")
                break
            
            time.sleep(delay)
        
        print("\n" + "=" * 60)
        print("  FIN DE LA SIMULACIÓN")
        print("=" * 60)
        
        if save_states:
            print(f"\n  Estados guardados en archivos state_step_*.json")
        
    except FileNotFoundError as e:
        print(f"\nError: {e}", file=sys.stderr)
        print("\nSolución: Compila el motor C++ primero:", file=sys.stderr)
        print("     mkdir build && cd build", file=sys.stderr)
        print("     cmake ..", file=sys.stderr)
        print("     make", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nSimulación interrumpida por el usuario.")
        sys.exit(0)
    except Exception as e:
        print(f"\nError inesperado: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    """Función principal."""
    parser = argparse.ArgumentParser(
        description="Demostración de simulación de propagación de fuego 2D"
    )
    parser.add_argument(
        "--width", "-w",
        type=int,
        default=2,
        help="Ancho de la cuadrícula (por defecto: 2)"
    )
    parser.add_argument(
        "--height", "-H",
        type=int,
        default=2,
        help="Alto de la cuadrícula (por defecto: 2)"
    )
    parser.add_argument(
        "--delay", "-d",
        type=float,
        default=1.5,
        help="Tiempo de espera entre pasos en segundos (por defecto: 1.5)"
    )
    parser.add_argument(
        "--save",
        action="store_true",
        help="Guardar los estados en archivos JSON"
    )
    
    args = parser.parse_args()
    
    run_demo(
        width=args.width,
        height=args.height,
        delay=args.delay,
        save_states=args.save
    )


if __name__ == "__main__":
    main()
