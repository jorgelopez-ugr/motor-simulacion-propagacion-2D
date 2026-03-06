extends Node
class_name FireSimulationBridge
## Bridge entre Godot y el motor de simulación de fuego en Python
## Maneja la comunicación bidireccional a través de JSON

## Ruta al ejecutable de Python (configurable desde el editor)
@export var python_executable: String = "python3"

## Ruta al script de la API del motor (relativo al proyecto o absoluto)
@export var api_script_path: String = "../api/fire_simulation_api.py"

## Ruta al ejecutable del motor C++ (relativo o absoluto)
@export var engine_path: String = "../../build/fire_engine"

## Señales para notificar cambios de estado
signal state_updated(new_state: Dictionary)
signal simulation_error(error_message: String)
signal simulation_initialized(initial_state: Dictionary)

## Estado actual de la simulación
var current_state: Dictionary = {}
var is_initialized: bool = false

## Dimensiones de la grid
var grid_width: int = 10
var grid_height: int = 10


func _ready() -> void:
	print("[FireSimulationBridge] Puente de simulación listo")


## Inicializa una nueva simulación con dimensiones específicas
func initialize_simulation(width: int, height: int) -> Dictionary:
	print("[FireSimulationBridge] Inicializando simulación %dx%d" % [width, height])
	
	grid_width = width
	grid_height = height
	
	# Construir comando para generar estado inicial
	var args = [
		"--generate",
		str(width),
		str(height),
		"0"  # step inicial
	]
	
	var result = _execute_engine(args)
	
	if result["success"]:
		current_state = result["state"]
		is_initialized = true
		simulation_initialized.emit(current_state)
		print("[FireSimulationBridge] Simulación inicializada correctamente")
		return current_state
	else:
		simulation_error.emit(result["error"])
		push_error("[FireSimulationBridge] Error al inicializar: " + result["error"])
		return {}


## Procesa el siguiente paso de la simulación
func process_step() -> Dictionary:
	if not is_initialized:
		push_error("[FireSimulationBridge] Simulación no inicializada")
		return {}
	
	# Crear archivo temporal con el estado actual
	var temp_path = _create_temp_state_file(current_state)
	
	if temp_path.is_empty():
		simulation_error.emit("No se pudo crear archivo temporal")
		return {}
	
	# Ejecutar motor con el estado actual
	var result = _execute_engine([temp_path])
	
	# Limpiar archivo temporal
	DirAccess.remove_absolute(temp_path)
	
	if result["success"]:
		current_state = result["state"]
		state_updated.emit(current_state)
		return current_state
	else:
		simulation_error.emit(result["error"])
		push_error("[FireSimulationBridge] Error al procesar paso: " + result["error"])
		return {}


## Resetea la simulación al estado inicial
func reset_simulation() -> void:
	if grid_width > 0 and grid_height > 0:
		initialize_simulation(grid_width, grid_height)
	else:
		push_error("[FireSimulationBridge] No hay dimensiones definidas para resetear")


## Enciende una celda específica (coordenadas de grid)
func ignite_cell(x: int, y: int) -> void:
	if not is_initialized:
		push_error("[FireSimulationBridge] Simulación no inicializada")
		return
	
	# Nota: La lógica de ignición debe implementarse en el motor C++
	# Por ahora, solo actualizamos el estado local
	print("[FireSimulationBridge] Solicitando ignición en (%d, %d)" % [x, y])


## Ejecuta el motor C++ con argumentos dados
func _execute_engine(args: Array) -> Dictionary:
	var output = []
	
	# Obtener ruta absoluta del motor
	var engine_abs_path = ProjectSettings.globalize_path(engine_path)
	
	# Verificar que el ejecutable existe
	if not FileAccess.file_exists(engine_abs_path):
		return {
			"success": false,
			"error": "Motor no encontrado en: " + engine_abs_path,
			"state": {}
		}
	
	print("[FireSimulationBridge] Ejecutando: %s %s" % [engine_abs_path, " ".join(args)])
	
	# Ejecutar el proceso (Godot 4.x sintaxis: path, args, output, read_stderr, open_console)
	var exit_code = OS.execute(engine_abs_path, args, output, true, false) 

	
	if exit_code != 0:
		var error_msg = "Error code " + str(exit_code)
		if output.size() > 0:
			error_msg += ": " + str(output[0])
		return {
			"success": false,
			"error": error_msg,
			"state": {}
		}
	print("output:",output)
	
	# Parsear JSON de salida
	if output.size() == 0:
		return {
			"success": false,
			"error": "No hay salida del motor",
			"state": {}
		}
	
	var json_string = output[0]
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(json_string)
	
	if parse_result != OK:
		return {
			"success": false,
			"error": "Error parseando JSON: " + json_parser.get_error_message(),
			"state": {}
		}
	
	return {
		"success": true,
		"error": "",
		"state": json_parser.data
	}


## Crea un archivo temporal con el estado actual en formato JSON
func _create_temp_state_file(state: Dictionary) -> String:
	var temp_dir = OS.get_user_data_dir()
	var temp_file_path = temp_dir + "/fire_state_temp.json"
	
	var file = FileAccess.open(temp_file_path, FileAccess.WRITE)
	if file == null:
		push_error("[FireSimulationBridge] No se pudo crear archivo temporal")
		return ""
	
	var json_string = JSON.stringify(state)
	file.store_string(json_string)
	file.close()
	
	return temp_file_path


## Obtiene el estado actual de la simulación
func get_current_state() -> Dictionary:
	return current_state


## Verifica si la simulación está activa
func is_simulation_active() -> bool:
	return is_initialized
