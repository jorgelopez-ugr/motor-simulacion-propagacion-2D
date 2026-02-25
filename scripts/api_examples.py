#!/usr/bin/env python3
"""
Ejemplo de uso de la API Python para el motor de simulación de fuego.
Demuestra diferentes formas de interactuar con el motor.
"""

import sys
import json
from pathlib import Path

# Agregar el directorio api al path
sys.path.insert(0, str(Path(__file__).parent.parent / "api"))

from fire_simulation_api import FireSimulationAPI
from visualize import TerminalVisualizer


def example_basic_usage():
    """Ejemplo 1: Uso básico de la API."""
    print("\n" + "="*60)
    print("EJEMPLO 1: Uso Básico de la API")
    print("="*60)
    
    api = FireSimulationAPI()
    visualizer = TerminalVisualizer()
    
    # Generar estado inicial
    print("\n1. Generar estado inicial (2x2, todo verde):")
    state = api.generate_initial_state(2, 2, step=0)
    print(json.dumps(state, indent=2))
    
    # Generar primer estado con fuego
    print("\n2. Generar estado con una celda en fuego:")
    state = api.generate_initial_state(2, 2, step=1)
    print(json.dumps(state, indent=2))
    visualizer.render_state(state)
    
    # Procesar siguiente estado
    print("\n3. Procesar siguiente estado:")
    next_state = api.process_state(state)
    print(json.dumps(next_state, indent=2))
    visualizer.render_state(next_state)


def example_save_load():
    """Ejemplo 2: Guardar y cargar estados."""
    print("\n" + "="*60)
    print("EJEMPLO 2: Guardar y Cargar Estados")
    print("="*60)
    
    api = FireSimulationAPI()
    
    # Generar estado
    print("\n1. Generar estado:")
    state = api.generate_initial_state(3, 3, step=1)
    print(f"Estado generado: paso {state['step']}, {state['width']}x{state['height']}")
    
    # Guardar estado
    filename = "/tmp/fire_state_example.json"
    print(f"\n2. Guardando estado en {filename}...")
    api.save_state(state, filename)
    print("✓ Estado guardado")
    
    # Cargar estado
    print(f"\n3. Cargando estado desde {filename}...")
    loaded_state = api.load_state(filename)
    print("✓ Estado cargado:")
    print(json.dumps(loaded_state, indent=2))


def example_full_simulation():
    """Ejemplo 3: Simulación completa."""
    print("\n" + "="*60)
    print("EJEMPLO 3: Simulación Completa")
    print("="*60)
    
    api = FireSimulationAPI()
    visualizer = TerminalVisualizer()
    
    width, height, steps = 3, 3, 6
    print(f"\nEjecutando simulación de {width}x{height} durante {steps} pasos...")
    
    states = api.run_simulation(width, height, steps)
    
    print(f"\n✓ Simulación completada. Se generaron {len(states)} estados.")
    print("\nVisualizando estados:")
    
    for state in states:
        visualizer.render_state(state)
        input("Presiona Enter para ver el siguiente estado...")


def example_custom_simulation():
    """Ejemplo 4: Simulación personalizada."""
    print("\n" + "="*60)
    print("EJEMPLO 4: Simulación Personalizada")
    print("="*60)
    
    api = FireSimulationAPI()
    visualizer = TerminalVisualizer()
    
    # Crear un estado inicial personalizado
    print("\n1. Crear estado personalizado con múltiples focos de fuego:")
    custom_state = {
        "step": 0,
        "width": 5,
        "height": 5,
        "grid": [
            [0, 0, 0, 0, 0],
            [0, 1, 0, 1, 0],  # Dos focos de fuego
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    }
    
    visualizer.render_state(custom_state)
    input("Presiona Enter para procesar siguiente estado...")
    
    # Procesar varios pasos
    current_state = custom_state
    for i in range(3):
        current_state = api.process_state(current_state)
        visualizer.render_state(current_state)
        
        fire_cells = sum(row.count(1) for row in current_state['grid'])
        total_cells = current_state['width'] * current_state['height']
        
        if fire_cells >= total_cells:
            print("¡Todas las celdas están en fuego!")
            break
        
        if i < 2:  # No preguntar en la última iteración
            input("Presiona Enter para procesar siguiente estado...")


def example_statistics():
    """Ejemplo 5: Análisis estadístico de la simulación."""
    print("\n" + "="*60)
    print("EJEMPLO 5: Análisis Estadístico")
    print("="*60)
    
    api = FireSimulationAPI()
    
    width, height, steps = 4, 4, 10
    print(f"\nEjecutando simulación de {width}x{height} durante {steps} pasos...")
    
    states = api.run_simulation(width, height, steps)
    
    print(f"\n{'Paso':<8} {'Celdas en fuego':<18} {'Nuevas celdas':<15} {'% Completado':<15}")
    print("-" * 60)
    
    total_cells = width * height
    for state in states:
        step = state['step']
        fire_cells = sum(row.count(1) for row in state['grid'])
        new_cells = state.get('cells_ignited', 'N/A')
        percentage = (fire_cells / total_cells) * 100
        
        print(f"{step:<8} {fire_cells:<18} {new_cells:<15} {percentage:>6.1f}%")
    
    print("\n✓ Análisis completado")


def main():
    """Función principal que ejecuta todos los ejemplos."""
    try:
        print("\n" + "="*60)
        print("  EJEMPLOS DE USO DE LA API PYTHON")
        print("  Motor de Simulación de Propagación de Fuego 2D")
        print("="*60)
        
        examples = [
            ("Uso Básico", example_basic_usage),
            ("Guardar y Cargar Estados", example_save_load),
            ("Simulación Completa", example_full_simulation),
            ("Simulación Personalizada", example_custom_simulation),
            ("Análisis Estadístico", example_statistics)
        ]
        
        print("\nEjemplos disponibles:")
        for i, (name, _) in enumerate(examples, 1):
            print(f"  {i}. {name}")
        print(f"  {len(examples) + 1}. Ejecutar todos")
        print("  0. Salir")
        
        while True:
            try:
                choice = input("\nSelecciona un ejemplo (0-{}): ".format(len(examples) + 1))
                choice = int(choice)
                
                if choice == 0:
                    print("\n¡Hasta luego!")
                    break
                elif choice == len(examples) + 1:
                    # Ejecutar todos
                    for name, func in examples:
                        func()
                        print("\n" + "-"*60)
                    print("\n✓ Todos los ejemplos completados")
                    break
                elif 1 <= choice <= len(examples):
                    name, func = examples[choice - 1]
                    func()
                    print("\n" + "-"*60)
                else:
                    print("Opción inválida. Intenta de nuevo.")
            except ValueError:
                print("Por favor ingresa un número válido.")
            except KeyboardInterrupt:
                print("\n\nInterrumpido por el usuario.")
                break
    
    except FileNotFoundError as e:
        print(f"\nError: {e}", file=sys.stderr)
        print("\nSolución: Compila el motor C++ primero:", file=sys.stderr)
        print("     mkdir build && cd build", file=sys.stderr)
        print("     cmake ..", file=sys.stderr)
        print("     make", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\nError inesperado: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
