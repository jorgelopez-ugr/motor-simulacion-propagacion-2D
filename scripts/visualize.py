#!/usr/bin/env python3
"""
Visualizador de terminal para la simulación de propagación de fuego.
Renderiza el estado de la cuadrícula en la terminal:
  X = celda verde (sin fuego)
  O = celda roja (en fuego)
"""

import json
import sys
from typing import Dict, Any


class TerminalVisualizer:
    """Visualizador de estados en la terminal."""
    
    # Colores ANSI
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

    fire_cells: int = 0  # Contador de celdas en fuego (para estadísticas)
    green_cells: int = 0  # Contador de celdas verdes (sin fuego)
    total_cells: int = 0  # Contador total de celdas (para estadísticas)
    
    def __init__(self, use_colors: bool = True):
        """
        Inicializa el visualizador.
        
        Args:
            use_colors: Si True, usa colores ANSI en la terminal
        """
        self.use_colors = use_colors
    
    def render_state(self, state: Dict[str, Any]) -> None:
        """
        Renderiza un estado en la terminal.
        
        Args:
            state: Estado de la simulación en formato JSON
        """
        # Limpiar pantalla antes de renderizar
        self._clear_screen()
        
        step = state.get('step', 0)
        width = state.get('width', 0)
        height = state.get('height', 0)
        grid = state.get('grid', [])
        cells_ignited = state.get('cells_ignited', 0)
        
        # Encabezado
        print(f"\n{self._color('=' * 50, self.BLUE)}")
        print(f"{self._color(f'  PASO {step}', self.BOLD + self.YELLOW)}")
        print(f"{self._color('=' * 50, self.BLUE)}")
        print(f"  Dimensiones: {width}x{height}")
        if 'cells_ignited' in state:
            print(f"  Celdas incendiadas este paso: {cells_ignited}")
        print()
        
        # Renderizar cuadrícula
        self._render_grid(grid)
        
        # Estadísticas
        state_0 = sum(row.count(0) for row in grid)  # Bosque intacto
        state_1 = sum(row.count(1) for row in grid)  # Fuego activo
        state_2 = sum(row.count(2) for row in grid)  # Brasas/humo
        state_3 = sum(row.count(3) for row in grid)  # Ceniza/quemado
        
        print(f"\n  {self._color('■', self.GREEN)} Bosque intacto: {state_0}")
        print(f"  {self._color('■', self.RED)} Fuego activo: {state_1}")
        print(f"  {self._color('■', self.YELLOW)} Brasas/humo: {state_2}")
        print(f"  {self._color('■', '\\033[90m')} Ceniza/quemado: {state_3}")
        print(f"{self._color('=' * 50, self.BLUE)}\n")
    
    def _clear_screen(self) -> None:
        """Limpia la pantalla de la terminal."""
        # Usar secuencia ANSI para limpiar y mover cursor al inicio
        print('\033[2J\033[H', end='')
    
    def _render_grid(self, grid: list) -> None:
        """
        Renderiza la cuadrícula en la terminal.
        
        Args:
            grid: Matriz que representa el estado de la cuadrícula
        """
        if not grid:
            print("  (cuadrícula vacía)")
            return
        
        height = len(grid)
        width = len(grid[0]) if height > 0 else 0
        
        # Borde superior
        print(f"  ┌{'─' * (width * 4 - 1)}┐")
        
        # Renderizar cada fila
        for row in grid:
            line = "  │ "
            for cell in row:
                if cell == 0:
                    # Bosque intacto (verde)
                    symbol = self._color('🟢', self.GREEN)
                elif cell == 1:
                    # Fuego activo (rojo brillante)
                    symbol = self._color('🔴', self.RED)
                elif cell == 2:
                    # Brasas/humo (amarillo)
                    symbol = self._color('🟡', self.YELLOW)
                else:  # cell == 3
                    # Ceniza/quemado (gris oscuro)
                    symbol = self._color('🟠', '\033[90m')  # Gris oscuro
                line += symbol + " │ "
            print(line)
        
        # Borde inferior
        print(f"  └{'─' * (width * 4 - 1)}┘")
    
    def _color(self, text: str, color: str) -> str:
        """
        Aplica color a un texto.
        
        Args:
            text: Texto a colorear
            color: Código de color ANSI
        
        Returns:
            Texto coloreado si use_colors=True, texto sin cambios en caso contrario
        """
        if self.use_colors:
            return f"{color}{text}{self.RESET}"
        return text
    
    def render_from_json_string(self, json_string: str) -> None:
        """
        Renderiza un estado desde una cadena JSON.
        
        Args:
            json_string: Estado en formato JSON string
        """
        try:
            state = json.loads(json_string)
            self.render_state(state)
        except json.JSONDecodeError as e:
            print(f"Error al parsear JSON: {e}", file=sys.stderr)
            sys.exit(1)
    
    def render_from_file(self, filepath: str) -> None:
        """
        Renderiza un estado desde un archivo JSON.
        
        Args:
            filepath: Ruta al archivo JSON
        """
        try:
            with open(filepath, 'r') as f:
                state = json.load(f)
            self.render_state(state)
        except FileNotFoundError:
            print(f"Error: No se encontró el archivo {filepath}", file=sys.stderr)
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error al parsear JSON: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    """Función principal del visualizador."""
    if len(sys.argv) < 2:
        print("Uso:", file=sys.stderr)
        print(f"  {sys.argv[0]} <archivo.json>", file=sys.stderr)
        print(f"  cat estado.json | {sys.argv[0]} -", file=sys.stderr)
        sys.exit(1)
    
    visualizer = TerminalVisualizer()
    
    if sys.argv[1] == '-':
        # Leer desde stdin
        json_string = sys.stdin.read()
        visualizer.render_from_json_string(json_string)
    else:
        # Leer desde archivo
        visualizer.render_from_file(sys.argv[1])


if __name__ == "__main__":
    main()
