"""
API Python para el motor de simulación de propagación de fuego 2D.
Gestiona la comunicación con el motor C++ a través de JSON.
"""

import json
import subprocess
import tempfile
import os
from pathlib import Path
from typing import Dict, Any, Optional


class FireSimulationAPI:
    """API para interactuar con el motor de simulación de fuego."""
    
    def __init__(self, engine_path: Optional[str] = None):
        """
        Inicializa la API.
        
        Args:
            engine_path: Ruta al ejecutable del motor C++. 
                        Si no se especifica, se busca en build/fire_engine
        """
        if engine_path is None:
            # Buscar el ejecutable en la ruta por defecto
            project_root = Path(__file__).parent.parent
            engine_path = project_root / "build" / "fire_engine"
        
        self.engine_path = Path(engine_path)
        
        if not self.engine_path.exists():
            raise FileNotFoundError(
                f"No se encontró el ejecutable del motor en {self.engine_path}. "
                f"Asegúrate de compilar el proyecto primero."
            )
    
    def generate_initial_state(self, width: int, height: int, step: int = 0) -> Dict[str, Any]:
        """
        Genera el estado inicial de la simulación.
        Al path del ejecutable se le pasan los parámetros de ancho, alto y paso para generar el estado inicial.
        Sobre el estado inicial que generemos aqui se aplicará la lógica de propagación en los pasos siguientes.
        a base de generación de estado sobre estado.

        Args:
            width: Ancho de la cuadrícula
            height: Alto de la cuadrícula
            step: Paso inicial (0 = todo verde, 1 = una celda roja aleatoria)
        
        Returns:
            Diccionario con el estado inicial en formato JSON
        """
        try:
            # Corre el ejecutable del motor con los parámetros para generar el estado inicial
            result = subprocess.run(
                [str(self.engine_path), "--generate", str(width), str(height), str(step)],
                capture_output=True,
                text=True,
                check=True
            )
            # Devuelve en JSON el estado generado por el motor.
            return json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Error al generar estado inicial: {e.stderr}")
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Error al parsear JSON del motor: {e}")
    
    def process_state(self, current_state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Procesa el estado actual y devuelve el siguiente estado.
        
        Args:
            current_state: Estado actual de la simulación en formato JSON
        
        Returns:
            Diccionario con el siguiente estado en formato JSON
        """
        # Crear archivo temporal para el estado de entrada
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as tmp_file:
            json.dump(current_state, tmp_file)
            tmp_path = tmp_file.name
        
        try:
            result = subprocess.run(
                [str(self.engine_path), tmp_path],
                capture_output=True,
                text=True,
                check=True
            )
            return json.loads(result.stdout)
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Error al procesar estado: {e.stderr}")
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Error al parsear JSON del motor: {e}")
        finally:
            # Limpiar archivo temporal
            os.unlink(tmp_path)
    
    def run_simulation(self, width: int, height: int, steps: int) -> list[Dict[str, Any]]:
        """
        Ejecuta una simulación completa durante un número determinado de pasos.
        
        Args:
            width: Ancho de la cuadrícula
            height: Alto de la cuadrícula
            steps: Número de pasos a simular
        
        Returns:
            Lista con todos los estados de la simulación
        """
        states = []
        
        # Generar estado inicial (paso 0 - todo verde)
        current_state = self.generate_initial_state(width, height, step=0)
        states.append(current_state)
        
        # Generar primer estado con celda aleatoria en fuego
        if steps > 0:
            current_state = self.generate_initial_state(width, height, step=1)
            states.append(current_state)
        
        # Procesar pasos restantes
        for _ in range(steps - 1):
            current_state = self.process_state(current_state)
            states.append(current_state)
        
        return states
    
    def save_state(self, state: Dict[str, Any], filepath: str) -> None:
        """
        Guarda un estado en un archivo JSON.
        
        Args:
            state: Estado a guardar
            filepath: Ruta del archivo donde guardar
        """
        with open(filepath, 'w') as f:
            json.dump(state, f, indent=2)
    
    def load_state(self, filepath: str) -> Dict[str, Any]:
        """
        Carga un estado desde un archivo JSON.
        
        Args:
            filepath: Ruta del archivo a cargar
        
        Returns:
            Estado cargado
        """
        with open(filepath, 'r') as f:
            return json.load(f)


if __name__ == "__main__":
    # Ejemplo de uso
    print("Inicializando API de simulación de fuego...")
    
    try:
        api = FireSimulationAPI()
        print("API inicializada correctamente")
        
        # Generar estado inicial
        print("\nGenerando estado inicial (2x2)...")
        state = api.generate_initial_state(2, 2, step=1)
        print(json.dumps(state, indent=2))
        
        # Procesar siguiente estado
        print("\nProcesando siguiente estado...")
        next_state = api.process_state(state)
        print(json.dumps(next_state, indent=2))
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("\nPara usar la API, primero compila el motor:")
        print("  mkdir build && cd build")
        print("  cmake ..")
        print("  make")
