cmake_minimum_required(VERSION 3.10)
project(FireSimulation2D)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Incluir nlohmann/json como header-only
include(FetchContent)
FetchContent_Declare(
    json
    URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz
)
FetchContent_MakeAvailable(json)

# Ejecutable del motor
add_executable(fire_engine 
    src/main.cpp
    src/fire_engine.cpp
)

target_link_libraries(fire_engine PRIVATE nlohmann_json::nlohmann_json)
