extends Node2D

class_name FireGridRenderer
## Renderiza una grid 2D de simulación de fuego
## Cada celda cambia de color según su estado (bosque, fuego, brasas, ceniza)

## Configuración de la grid
@export var cell_size: Vector2 = Vector2(16, 16)
@export var grid_width: int = 50
@export var grid_height: int = 50
@export var grid_offset: Vector2 = Vector2(10, 10)

## Colores para cada estado de celda
@export_group("Colores")
@export var color_forest: Color = Color(0.0, 0.6, 0.0, 1.0)      # Verde bosque
@export var color_active_fire: Color = Color(1.0, 0.2, 0.0, 1.0) # Rojo fuego
@export var color_embers: Color = Color(1.0, 0.8, 0.0, 1.0)      # Amarillo brasas
@export var color_ash: Color = Color(0.3, 0.3, 0.3, 1.0)         # Gris ceniza
@export var color_border: Color = Color(0.2, 0.2, 0.2, 0.5)     # Borde de celdas

## Referencia al puente de simulación (asignable desde el Inspector)
@export var simulation_bridge: FireSimulationBridge

## Grid de celdas (ColorRect para rendimiento)
var cells: Array[ColorRect] = []

## Estado actual de la grid
var current_grid_state: Array = []

## Estadísticas
var stats: Dictionary = {
	"forest": 0,
	"fire": 0,
	"embers": 0,
	"ash": 0
}


func _ready() -> void:
	print("[FireGridRenderer] Inicializando renderer de grid")
	_setup_cells()
	
	# Conectar señales del puente si existe
	if simulation_bridge:
		simulation_bridge.simulation_initialized.connect(_on_simulation_initialized)
		simulation_bridge.state_updated.connect(_on_state_updated)
		simulation_bridge.simulation_error.connect(_on_simulation_error)


## Configura todas las celdas de la grid
func _setup_cells() -> void:
	# Limpiar celdas existentes
	for cell in cells:
		cell.queue_free()
	cells.clear()
	
	# Crear nueva grid de celdas
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = ColorRect.new()
			cell.size = cell_size
			cell.position = grid_offset + Vector2(x * cell_size.x, y * cell_size.y)
			cell.color = color_forest
			
			# Opcional: añadir borde
			# var border = StyleBoxFlat.new()
			# border.border_color = color_border
			# border.set_border_width_all(1)
			
			add_child(cell)
			cells.append(cell)
	
	print("[FireGridRenderer] Grid de %dx%d celdas creada" % [grid_width, grid_height])


## Actualiza la visualización con un nuevo estado
func update_grid(grid_data: Array) -> void:
	if grid_data.size() != grid_height:
		push_error("[FireGridRenderer] Datos de grid inválidos: altura incorrecta")
		return
	
	current_grid_state = grid_data
	_update_statistics()
	
	var cell_index = 0
	for y in range(grid_height):
		if grid_data[y].size() != grid_width:
			push_error("[FireGridRenderer] Datos de grid inválidos: ancho incorrecto en fila " + str(y))
			return
		
		for x in range(grid_width):
			var state = grid_data[y][x]
			var color = _get_color_for_state(state)
			
			if cell_index < cells.size():
				cells[cell_index].color = color
			
			cell_index += 1


## Obtiene el color correspondiente a un estado de celda
func _get_color_for_state(state: int) -> Color:
	match state:
		0: return color_forest       # Bosque intacto
		1: return color_active_fire  # Fuego activo
		2: return color_embers       # Brasas/humo
		3: return color_ash          # Ceniza/quemado
		_: return Color.MAGENTA      # Estado desconocido (debug)


## Actualiza las estadísticas de la grid
func _update_statistics() -> void:
	stats = {"forest": 0, "fire": 0, "embers": 0, "ash": 0}
	
	for row in current_grid_state:
		for cell_state in row:
			match cell_state:
				0: stats["forest"] += 1
				1: stats["fire"] += 1
				2: stats["embers"] += 1
				3: stats["ash"] += 1


## Obtiene las estadísticas actuales
func get_statistics() -> Dictionary:
	return stats


## Handler para cuando se inicializa la simulación
func _on_simulation_initialized(initial_state: Dictionary) -> void:
	print("[FireGridRenderer] Simulación inicializada, actualizando grid")
	if initial_state.has("grid"):
		update_grid(initial_state["grid"])


## Handler para cuando se actualiza el estado
func _on_state_updated(new_state: Dictionary) -> void:
	if new_state.has("grid"):
		update_grid(new_state["grid"])


## Handler para errores de simulación
func _on_simulation_error(error_message: String) -> void:
	push_error("[FireGridRenderer] Error de simulación: " + error_message)


## Convierte coordenadas de mundo a coordenadas de grid
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - grid_offset
	var grid_x = int(local_pos.x / cell_size.x)
	var grid_y = int(local_pos.y / cell_size.y)
	
	# Clamp a los límites de la grid
	grid_x = clampi(grid_x, 0, grid_width - 1)
	grid_y = clampi(grid_y, 0, grid_height - 1)
	
	return Vector2i(grid_x, grid_y)


## Convierte coordenadas de grid a coordenadas de mundo (centro de la celda)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return grid_offset + Vector2(
		grid_pos.x * cell_size.x + cell_size.x / 2.0,
		grid_pos.y * cell_size.y + cell_size.y / 2.0
	)


## Maneja clicks en la grid (para ignición manual)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var grid_pos = world_to_grid(event.position)
			print("[FireGridRenderer] Click en grid: (%d, %d)" % [grid_pos.x, grid_pos.y])
			# Aquí podrías llamar a simulation_bridge.ignite_cell(grid_pos.x, grid_pos.y)
