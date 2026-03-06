#ifndef FIRE_ENGINE_HPP
#define FIRE_ENGINE_HPP

#include <string>
#include <vector>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

// Estructura para representar campos escalares 2D (fluidos)
struct FluidGrid {
    int width, height;
    
    // Campos físicos según modelo NVIDIA de propagación de fuego
    // Ahora usamos arrays 2D tradicionales: field[y][x]
    std::vector<std::vector<double>> fuel;        // Y: Coordenada de reacción (1.0 = combustible completo, 0.0 = ceniza)
    std::vector<std::vector<double>> temperature; // T: Temperatura (genera ignición y flotabilidad)
    std::vector<std::vector<double>> u, v;        // Velocidad del fluido en X e Y
    std::vector<std::vector<double>> density;     // Densidad visual (fuego/humo para renderizado)
    
    FluidGrid(int w, int h);
    
    // Interpolación bilinear para advección (accede directamente a field[y][x])
    double interpolate(const std::vector<std::vector<double>>& field, double x, double y) const;
};

class FireEngine {
private:
    int width_;
    int height_;
    
    // Campos de fluidos (actual y buffer para ping-pong)
    FluidGrid grid_;
    FluidGrid next_grid_;
    
    // Parámetros físicos del modelo (basados en artículo NVIDIA)
    double dt_;              // Paso de tiempo
    double burn_rate_;       // k: Rapidez consumo de combustible
    double heat_production_; // Calor liberado al quemar
    double cooling_rate_;    // Disipación térmica
    double buoyancy_;        // Fuerza flotación por temperatura
    double diffusion_;       // Viscosidad/difusión térmica
    
    // === MÉTODOS DE SIMULACIÓN DE FLUIDOS ===
    
    // 1. Advección: mueve cantidades según el campo de velocidad
    void advect(const std::vector<std::vector<double>>& src, 
                std::vector<std::vector<double>>& dest,
                const std::vector<std::vector<double>>& u, 
                const std::vector<std::vector<double>>& v);
    
    // 2. Combustión: implementa dY/dt = -k (ecuación de reacción)
    void processCombustion();
    
    // 3. Flotabilidad: temperatura genera velocidad vertical
    void applyBuoyancy();
    
    // 4. Difusión térmica: suaviza gradientes de temperatura
    void diffuseHeat();
    
    // 5. Proyección de presión: hace el fluido incompresible (∇·u = 0)
    // void projectVelocity(); // TODO: Implementar en futuras iteraciones
    
    // === MÉTODOS AUXILIARES ===
    
    // Convierte el estado continuo (doubles) a discreto (ints) para visualización
    std::vector<std::vector<int>> getDiscreteGrid() const;
    
    // Enciende una celda (temperatura alta para iniciar reacción)
    void igniteCell(int x, int y);

public:
    FireEngine(int width, int height);
    
    // Procesa un paso de simulación completo
    json processState(const json& inputState);
    
    // Genera el estado inicial (ahora con campos de fluidos)
    json generateInitialState(int step = 0);
};

#endif // FIRE_ENGINE_HPP
