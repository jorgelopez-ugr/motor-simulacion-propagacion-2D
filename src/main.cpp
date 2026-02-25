#include "fire_engine.hpp"
#include <iostream>
#include <fstream>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

int main(int argc, char* argv[]) {
    try {
        if (argc < 2) {
            std::cerr << "Uso: " << argv[0] << " <archivo_json_entrada>" << std::endl;
            std::cerr << "O: " << argv[0] << " --generate <width> <height>" << std::endl;
            return 1;
        }
        
        std::string command = argv[1];
        
        if (command == "--generate") {
            // Generar estado inicial
            if (argc < 4) {
                std::cerr << "Uso para generar: " << argv[0] << " --generate <width> <height> [step]" << std::endl;
                return 1;
            }
            
            int width = std::stoi(argv[2]);
            int height = std::stoi(argv[3]);
            int step = (argc >= 5) ? std::stoi(argv[4]) : 0;
            
            FireEngine engine(width, height);
            json state = engine.generateInitialState(step);
            
            std::cout << state.dump(2) << std::endl;
        } else {
            // Procesar estado desde archivo
            std::ifstream inputFile(command);
            if (!inputFile.is_open()) {
                std::cerr << "Error: No se pudo abrir el archivo " << command << std::endl;
                return 1;
            }
            
            json inputState;
            inputFile >> inputState;
            inputFile.close();
            
            int width = inputState["width"];
            int height = inputState["height"];
            
            FireEngine engine(width, height);
            json outputState = engine.processState(inputState);
            
            std::cout << outputState.dump(2) << std::endl;
        }
        
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
