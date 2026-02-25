#include "fire_engine.hpp"
#include <random>
#include <ctime>
#include <algorithm>

FireEngine::FireEngine(int width, int height) : width_(width), height_(height) {}

json FireEngine::generateInitialState(int step) {
    
    // Este objeto JSON una vez inicializado lucerá asi:
    /*
        {
        "step": 0,
        "width": 5,
        "height": 5,
        "grid": [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
        }

        ceros van cambiandose por 1 cuando se incendian
        simula la propagación con lógica super simple
    */  
    json state;
    state["step"] = step;
    state["width"] = width_;
    state["height"] = height_;
    
    // Crear grid vacío (todo en 0 = verde)

    // Esta grid es una matriz de enteros donde:
    // 0 = verde (sin fuego)
    // 1 = rojo (en fuego)

    std::vector<std::vector<int>> grid(height_, std::vector<int>(width_, 0));
    
    // Si es el paso 1, elegir una celda aleatoria para incendiar
    if (step == 1) {
        std::srand(std::time(nullptr));
        int randomX = std::rand() % width_;
        int randomY = std::rand() % height_;
        grid[randomY][randomX] = 1; // 1 = rojo (en fuego)
    }
    
    state["grid"] = grid;
    return state;
}

std::vector<std::pair<int, int>> FireEngine::getAdjacentCells(int x, int y) {
    
    // Se devuelve un vector de casilla adyacentes a la casilla que se le pase como argumento.
    // Se comprueba que no se salga de los limites del grid.
    std::vector<std::pair<int, int>> adjacent;
    
    // Arriba
    if (y > 0) adjacent.push_back({x, y - 1});
    // Abajo
    if (y < height_ - 1) adjacent.push_back({x, y + 1});
    // Izquierda
    if (x > 0) adjacent.push_back({x - 1, y});
    // Derecha
    if (x < width_ - 1) adjacent.push_back({x + 1, y});
    
    return adjacent;
}

std::vector<std::pair<int, int>> FireEngine::findCellsToPropagate(const std::vector<std::vector<int>>& grid) {
    std::vector<std::pair<int, int>> cellsToIgnite;
    
    // Buscar todas las celdas en fuego
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            if (grid[y][x] == 1) { // Si está en fuego
                // Propagar a adyacentes que no estén en fuego
                auto adjacent = getAdjacentCells(x, y);
                for (const auto& [adjX, adjY] : adjacent) {
                    if (grid[adjY][adjX] == 0) { // Si no está en fuego
                        cellsToIgnite.push_back({adjX, adjY});
                    }
                }
            }
        }
    }
    
    return cellsToIgnite;
}

json FireEngine::processState(const json& inputState) {
    json outputState;
    
    // Copiar metadata
    int step = inputState["step"];
    outputState["step"] = step + 1;
    outputState["width"] = inputState["width"];
    outputState["height"] = inputState["height"];
    
    // Obtener el grid actual
    std::vector<std::vector<int>> grid = inputState["grid"];
    
    // Encontrar celdas a propagar
    auto cellsToIgnite = findCellsToPropagate(grid);
    
    // Aplicar propagación
    for (const auto& [x, y] : cellsToIgnite) {
        grid[y][x] = 1;
    }
    
    outputState["grid"] = grid;
    outputState["cells_ignited"] = cellsToIgnite.size();
    
    return outputState;
}
