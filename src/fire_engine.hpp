#ifndef FIRE_ENGINE_HPP
#define FIRE_ENGINE_HPP

#include <string>
#include <vector>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

class FireEngine {
private:
    int width_;
    int height_;
    
    // Encuentra las celdas que deben propagarse en el siguiente paso
    std::vector<std::pair<int, int>> findCellsToPropagate(const std::vector<std::vector<int>>& grid);
    
    // Obtiene las celdas adyacentes (arriba, abajo, izquierda, derecha)
    std::vector<std::pair<int, int>> getAdjacentCells(int x, int y);

    // Obtiene las celdas que se encenderán a partir de una celda en fuego
    // Implementa la logica de propagacion. getAdjacentCells es un caso de ejemplo
    std::vector<std::pair<int, int>> getIgnitionCellsProbabilities(int x, int y);

    std::vector<std::pair<int, int>> getIgnitionCellsProbabilities(int x, int y);

public:
    FireEngine(int width, int height);
    // Estos metodos auxiliares van a simular la logica de propagacion
    // Llegado el momento seran sustituidos por otros mas complejos
    // El objetivo es tener una estructura de motor de pruebas que se pueda ir mejorando iterativamente sin romper la interfaz

    // Procesa un estado y devuelve el siguiente
    json processState(const json& inputState);
    
    // Genera el estado inicial
    json generateInitialState(int step = 0);

};

#endif // FIRE_ENGINE_HPP
