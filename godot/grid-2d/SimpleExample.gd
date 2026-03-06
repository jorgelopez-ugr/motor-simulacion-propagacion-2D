extends Node2D
## Script de ejemplo simple para probar la integración
## Úsalo como Main Scene para testing rápido

@onready var bridge = FireSimulationBridge.new()
@onready var label = Label.new()

var grid_data = []
var cell_rects: Array[ColorRect] = []
var cell_size = 10
var grid_width = 30
var grid_height = 20


func _ready() -> void:
	print("=== EJEMPLO SIMPLE DE INTEGRACIÓN ===")
	
	# Configurar el bridge
	bridge.engine_path = "../build/fire_engine"
	add_child(bridge)
	
	# Crear label para información
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)
	
	# Crear grid visual simple
	_create_visual_grid()
	
	# Inicializar simulación
	print("Inicializando simulación...")
	var initial_state = bridge.initialize_simulation(grid_width, grid_height)
	
	if initial_state.is_empty():
		print("ERROR: No se pudo inicializar")
		label.text = "ERROR: No se pudo inicializar la simulación"
		return
	
	print("Estado inicial recibido: paso ", initial_state["step"])
	_update_visual_grid(initial_state["grid"])
	label.text = "Presiona ESPACIO para avanzar un paso"


func _create_visual_grid() -> void:
	for y in range(grid_height):
		for x in range(grid_width):
			var rect = ColorRect.new()
			rect.size = Vector2(cell_size, cell_size)
			rect.position = Vector2(x * cell_size + 10, y * cell_size + 50)
			rect.color = Color.GREEN
			add_child(rect)
			cell_rects.append(rect)


func _update_visual_grid(grid: Array) -> void:
	var index = 0
	for y in range(grid_height):
		for x in range(grid_width):
			var state = grid[y][x]
			var color = Color.GREEN
			
			match state:
				0: color = Color.GREEN       # Bosque
				1: color = Color.RED         # Fuego
				2: color = Color.YELLOW      # Brasas
				3: color = Color.GRAY        # Ceniza
			
			if index < cell_rects.size():
				cell_rects[index].color = color
			index += 1


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		print("\nProcesando siguiente paso...")
		var new_state = bridge.process_step()
		
		if new_state.is_empty():
			print("ERROR: No se pudo procesar el paso")
			label.text = "ERROR en el paso"
			return
		
		print("Paso ", new_state["step"], " completado")
		_update_visual_grid(new_state["grid"])
		label.text = "Paso: " + str(new_state["step"]) + " - Presiona ESPACIO para continuar"
		
		# Contar estados
		var stats = {"bosque": 0, "fuego": 0, "brasas": 0, "ceniza": 0}
		for row in new_state["grid"]:
			for cell in row:
				match cell:
					0: stats["bosque"] += 1
					1: stats["fuego"] += 1
					2: stats["brasas"] += 1
					3: stats["ceniza"] += 1
		
		print("  Bosque: ", stats["bosque"], " | Fuego: ", stats["fuego"], 
			  " | Brasas: ", stats["brasas"], " | Ceniza: ", stats["ceniza"])
