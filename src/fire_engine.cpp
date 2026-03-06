#include "fire_engine.hpp"
#include <random>
#include <ctime>
#include <algorithm>
#include <cmath>

// ============================================================================
// IMPLEMENTACIÓN DE FluidGrid
// ============================================================================

FluidGrid::FluidGrid(int w, int h) : width(w), height(h) {
    // Inicializar arrays 2D: field[y][x]
    fuel.assign(height, std::vector<double>(width, 1.0));         // Todo es combustible
    temperature.assign(height, std::vector<double>(width, 0.0));  // Temperatura ambiente
    u.assign(height, std::vector<double>(width, 0.0));            // Sin viento
    v.assign(height, std::vector<double>(width, 0.0));
    density.assign(height, std::vector<double>(width, 0.0));      // Sin fuego/humo
}

double FluidGrid::interpolate(const std::vector<std::vector<double>>& field, double x, double y) const {
    // Interpolación bilineal para advección suave
    // Clamp a los límites
    x = std::max(0.0, std::min(x, (double)(width - 1)));
    y = std::max(0.0, std::min(y, (double)(height - 1)));
    
    int x0 = (int)std::floor(x);
    int y0 = (int)std::floor(y);
    int x1 = std::min(x0 + 1, width - 1);
    int y1 = std::min(y0 + 1, height - 1);
    
    double fx = x - x0;
    double fy = y - y0;
    
    // Bilinear interpolation usando field[y][x]
    double c00 = field[y0][x0];
    double c10 = field[y0][x1];
    double c01 = field[y1][x0];
    double c11 = field[y1][x1];
    
    return (1 - fx) * (1 - fy) * c00 +
           fx * (1 - fy) * c10 +
           (1 - fx) * fy * c01 +
           fx * fy * c11;
}

// ============================================================================
// IMPLEMENTACIÓN DE FireEngine
// ============================================================================

FireEngine::FireEngine(int width, int height) 
    : width_(width), height_(height),
      grid_(width, height),
      next_grid_(width, height)
{
    // Parámetros físicos del modelo (tunear estos para diferentes comportamientos)
    dt_ = 0.15;                 // Paso de tiempo
    burn_rate_ = 0.12;          // k: Consumo de combustible (más alto = fuego más rápido)
    heat_production_ = 5.0;     // Calor liberado por combustión (aumentado)
    cooling_rate_ = 0.015;      // Disipación térmica al ambiente (reducida)
    buoyancy_ = 0.8;            // Fuerza ascendente por temperatura
    diffusion_ = 0.04;          // Suavizado térmico (aumentado para mejor propagación)
    
    // Seed para aleatoriedad
    std::srand(std::time(nullptr));
}

json FireEngine::generateInitialState(int step) {
    json state;
    state["step"] = step;
    state["width"] = width_;
    state["height"] = height_;
    
    // Inicializar campos de fluidos
    if (step == 0) {
        // Estado inicial: todo es bosque sin fuego
        state["grid"] = getDiscreteGrid();
    } else if (step == 1) {
        // Encender una celda aleatoria
        int randomX = std::rand() % width_;
        int randomY = std::rand() % height_;
        igniteCell(randomX, randomY);
        state["grid"] = getDiscreteGrid();
    }
    
    // Serializar campos de fluidos para persistencia entre llamadas
    state["fuel"] = grid_.fuel;
    state["temperature"] = grid_.temperature;
    state["u"] = grid_.u;
    state["v"] = grid_.v;
    state["density"] = grid_.density;
    
    return state;
}

void FireEngine::igniteCell(int x, int y) {
    // Iniciar combustión: temperatura alta y densidad visible
    grid_.temperature[y][x] = 5.0;  // Temperatura de ignición muy alta
    grid_.density[y][x] = 3.0;      // Fuego visible intenso
    grid_.fuel[y][x] = 0.95;        // Consumir un poco de combustible inicial
    
    // Precalentar vecinos inmediatos para asegurar propagación
    if (x > 0) grid_.temperature[y][x - 1] += 1.0;
    if (x < width_ - 1) grid_.temperature[y][x + 1] += 1.0;
    if (y > 0) grid_.temperature[y - 1][x] += 1.0;
    if (y < height_ - 1) grid_.temperature[y + 1][x] += 1.0;
}

// ============================================================================
// MÉTODOS DE SIMULACIÓN DE FLUIDOS
// ============================================================================

void FireEngine::advect(const std::vector<std::vector<double>>& src, 
                        std::vector<std::vector<double>>& dest,
                        const std::vector<std::vector<double>>& u, 
                        const std::vector<std::vector<double>>& v) {
    // Advección semi-Lagrangiana: seguir partículas hacia atrás en el tiempo
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            // Retroceder en el tiempo según la velocidad
            double prev_x = x - u[y][x] * dt_;
            double prev_y = y - v[y][x] * dt_;
            
            // Interpolar el valor desde la posición anterior
            dest[y][x] = grid_.interpolate(src, prev_x, prev_y);
        }
    }
}

void FireEngine::processCombustion() {
    // Implementa la ecuación de reacción: dY/dt = -k
    // El combustible se consume, generando calor y humo
    
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            double& Y = grid_.fuel[y][x];        // Combustible
            double& T = grid_.temperature[y][x]; // Temperatura
            double& D = grid_.density[y][x];     // Densidad visual (fuego/humo)
            
            // Condición de ignición: si hay temperatura > umbral Y combustible
            if (Y > 0.05 && T > 0.2) { // Umbral muy bajo para facilitar ignición
                // Cantidad de combustible quemado este paso
                double burned = burn_rate_ * Y * dt_;
                
                // Consumir combustible (ecuación diferencial)
                Y -= burned;
                if (Y < 0) Y = 0;
                
                // Generar calor por combustión
                T += burned * heat_production_;
                
                // Generar densidad visual (fuego brillante)
                D += burned * 8.0;
                
                // Propagar temperatura a vecinos (ignición por conducción)
                double heat_transfer = burned * 0.8; // Alta transferencia de calor
                
                if (x > 0) grid_.temperature[y][x - 1] += heat_transfer;
                if (x < width_ - 1) grid_.temperature[y][x + 1] += heat_transfer;
                if (y > 0) grid_.temperature[y - 1][x] += heat_transfer;
                if (y < height_ - 1) grid_.temperature[y + 1][x] += heat_transfer;
            }
            
            // Enfriamiento natural (disipación al ambiente)
            T -= cooling_rate_ * T * dt_;
            D -= cooling_rate_ * D * dt_;
            
            // Clamp a valores físicos
            if (T < 0) T = 0;
            if (D < 0) D = 0;
            if (T > 10.0) T = 10.0; // Limitar temperatura máxima para estabilidad numérica
        }
    }
}

void FireEngine::applyBuoyancy() {
    // La temperatura genera velocidad vertical (flotabilidad)
    // Ley de Arquímedes: el aire caliente sube
    
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            // La velocidad vertical aumenta proporcionalmente a la temperatura
            // Nota: En matrices, Y+ suele ser "abajo", así que usamos -buoyancy para subir
            grid_.v[y][x] -= grid_.temperature[y][x] * buoyancy_ * dt_;
            
            // Agregar un poco de movimiento horizontal aleatorio (turbulencia)
            double turbulence = ((double)std::rand() / RAND_MAX - 0.5) * 0.1;
            grid_.u[y][x] += turbulence * grid_.temperature[y][x] * dt_;
        }
    }
}

void FireEngine::diffuseHeat() {
    // Difusión térmica: suaviza gradientes de temperatura
    // Implementación simplificada (Jacobi iteration, 1 paso)
    
    auto temp_copy = grid_.temperature; // Copia del array 2D
    
    for (int y = 1; y < height_ - 1; ++y) {
        for (int x = 1; x < width_ - 1; ++x) {
            // Promedio de vecinos (operador Laplaciano discreto)
            double avg = (temp_copy[y][x - 1] + temp_copy[y][x + 1] +
                         temp_copy[y - 1][x] + temp_copy[y + 1][x]) / 4.0;
            
            // Mezclar con el valor actual según coeficiente de difusión
            grid_.temperature[y][x] += (avg - grid_.temperature[y][x]) * diffusion_;
        }
    }
}

json FireEngine::processState(const json& inputState) {
    json outputState;
    
    // Metadata
    int step = inputState["step"];
    outputState["step"] = step + 1;
    outputState["width"] = width_;
    outputState["height"] = height_;
    
    // Deserializar campos de fluidos desde el estado anterior
    if (inputState.contains("fuel")) {
        grid_.fuel = inputState["fuel"].get<std::vector<std::vector<double>>>();
        grid_.temperature = inputState["temperature"].get<std::vector<std::vector<double>>>();
        grid_.u = inputState["u"].get<std::vector<std::vector<double>>>();
        grid_.v = inputState["v"].get<std::vector<std::vector<double>>>();
        grid_.density = inputState["density"].get<std::vector<std::vector<double>>>();
    }
    
    // === PIPELINE DE SIMULACIÓN DE FLUIDOS ===
    
    // 1. Advección de velocidad (el fluido se mueve a sí mismo)
    advect(grid_.u, next_grid_.u, grid_.u, grid_.v);
    advect(grid_.v, next_grid_.v, grid_.u, grid_.v);
    grid_.u = next_grid_.u;
    grid_.v = next_grid_.v;
    
    // 2. Advección de campos escalares (densidad y temperatura se mueven con el fluido)
    advect(grid_.density, next_grid_.density, grid_.u, grid_.v);
    advect(grid_.temperature, next_grid_.temperature, grid_.u, grid_.v);
    grid_.density = next_grid_.density;
    grid_.temperature = next_grid_.temperature;
    
    // Nota: El combustible NO se advecta (los árboles no se mueven con el viento)
    
    // 3. Procesos físicos
    processCombustion();  // Consume Y, genera T y D
    diffuseHeat();        // Suaviza temperatura
    applyBuoyancy();      // T genera velocidad vertical
    
    // 4. (FUTURO) Proyección de presión para incompresibilidad
    // projectVelocity();
    
    // Convertir estado continuo a discreto para visualización
    outputState["grid"] = getDiscreteGrid();
    
    // Serializar campos de fluidos para el próximo paso
    outputState["fuel"] = grid_.fuel;
    outputState["temperature"] = grid_.temperature;
    outputState["u"] = grid_.u;
    outputState["v"] = grid_.v;
    outputState["density"] = grid_.density;
    
    // Estadísticas
    int cells_burning = 0;
    int cells_burned = 0;
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            if (grid_.density[y][x] > 0.5) cells_burning++;
            if (grid_.fuel[y][x] < 0.1) cells_burned++;
        }
    }
    outputState["cells_burning"] = cells_burning;
    outputState["cells_burned"] = cells_burned;
    
    return outputState;
}

std::vector<std::vector<int>> FireEngine::getDiscreteGrid() const {
    // Convertir estado continuo (doubles) a discreto (ints) para visualización
    // Estados:
    // 0 = Bosque intacto (verde)
    // 1 = Fuego activo (rojo/naranja)
    // 2 = Brasas/humo (gris)
    // 3 = Ceniza/quemado (negro)
    
    std::vector<std::vector<int>> discrete(height_, std::vector<int>(width_));
    
    for (int y = 0; y < height_; ++y) {
        for (int x = 0; x < width_; ++x) {
            double fuel = grid_.fuel[y][x];
            double temp = grid_.temperature[y][x];
            double dens = grid_.density[y][x];
            
            // Lógica de clasificación
            if (dens > 1.0 && temp > 0.5) {
                discrete[y][x] = 1; // Fuego activo
            } else if (dens > 0.3 || temp > 0.3) {
                discrete[y][x] = 2; // Brasas/humo
            } else if (fuel < 0.2) {
                discrete[y][x] = 3; // Ceniza/quemado
            } else {
                discrete[y][x] = 0; // Bosque intacto
            }
        }
    }
    
    return discrete;
}
