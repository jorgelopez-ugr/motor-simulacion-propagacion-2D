extends Node
class_name FireSimulationController

## Controlador principal de la simulación de propagación de fuego
## Orquesta el flujo entre el motor C++ y la visualización en Godot

## Configuración de la simulación
@export var auto_start: bool = true
@export var simulation_delay: float = 0.2  # Segundos entre pasos
@export var max_steps: int = 0  # 0 = infinito

## Referencias a componentes (asignables desde el Inspector)
@export var bridge: FireSimulationBridge
@export var renderer: FireGridRenderer

## Estado de la simulación
var is_running: bool = false
var current_step: int = 0
var timer: Timer

## Señales
signal simulation_started()
signal simulation_stopped()
signal simulation_paused()
signal simulation_resumed()
signal step_completed(step_number: int)


func _ready() -> void:
	print("[FireSimulationController] Controlador inicializado")
	
	# Configurar timer para pasos automáticos
	timer = Timer.new()
	timer.wait_time = simulation_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Auto-iniciar si está configurado
	if auto_start:
		call_deferred("start_simulation")


## Inicia una nueva simulación
func start_simulation(width: int = 50, height: int = 50) -> void:
	print("[FireSimulationController] Iniciando simulación %dx%d" % [width, height])
	
	# Asegurarse que el renderer tenga las dimensiones correctas
	if renderer:
		renderer.grid_width = width
		renderer.grid_height = height
		renderer._setup_cells()
	
	# Inicializar el motor
	if bridge:
		var initial_state = bridge.initialize_simulation(width, height)
		
		if initial_state.is_empty():
			push_error("[FireSimulationController] No se pudo inicializar la simulación")
			return
		
		# Actualizar renderer con estado inicial
		if renderer and initial_state.has("grid"):
			renderer.update_grid(initial_state["grid"])
		
		current_step = 0
		is_running = true
		timer.start()
		simulation_started.emit()
		
		print("[FireSimulationController] Simulación iniciada correctamente")


## Detiene completamente la simulación
func stop_simulation() -> void:
	print("[FireSimulationController] Deteniendo simulación")
	is_running = false
	timer.stop()
	current_step = 0
	simulation_stopped.emit()


## Pausa la simulación sin resetear
func pause_simulation() -> void:
	if is_running:
		print("[FireSimulationController] Pausando simulación")
		is_running = false
		timer.stop()
		simulation_paused.emit()


## Reanuda la simulación pausada
func resume_simulation() -> void:
	if not is_running and bridge.is_simulation_active():
		print("[FireSimulationController] Reanudando simulación")
		is_running = true
		timer.start()
		simulation_resumed.emit()


## Ejecuta un solo paso manualmente
func step_once() -> void:
	if bridge.is_simulation_active():
		_process_simulation_step()


## Resetea la simulación al estado inicial
func reset_simulation() -> void:
	print("[FireSimulationController] Reseteando simulación")
	pause_simulation()
	
	if bridge:
		bridge.reset_simulation()
		current_step = 0


## Procesa el siguiente paso de simulación
func _process_simulation_step() -> void:
	if not bridge or not bridge.is_simulation_active():
		return
	
	# Procesar paso en el motor
	var new_state = bridge.process_step()
	
	if new_state.is_empty():
		push_error("[FireSimulationController] Error al procesar paso")
		stop_simulation()
		return
	
	# Actualizar visualización
	if renderer and new_state.has("grid"):
		renderer.update_grid(new_state["grid"])
	
	current_step += 1
	step_completed.emit(current_step)
	
	# Verificar si se alcanzó el límite de pasos
	if max_steps > 0 and current_step >= max_steps:
		print("[FireSimulationController] Límite de pasos alcanzado (%d)" % max_steps)
		stop_simulation()
	
	# Verificar condición de terminación (todas las celdas quemadas)
	if _check_simulation_complete(new_state):
		print("[FireSimulationController] ¡Todas las celdas están en fuego! Simulación completa.")
		stop_simulation()


## Verifica si la simulación ha terminado (todas las celdas quemadas)
func _check_simulation_complete(state: Dictionary) -> bool:
	if not state.has("grid"):
		return false
	
	var grid = state["grid"]
	var forest_count = 0
	
	for row in grid:
		for cell in row:
			if cell == 0:  # Bosque intacto
				forest_count += 1
	
	return forest_count == 0


## Callback del timer para procesamiento automático
func _on_timer_timeout() -> void:
	if is_running:
		_process_simulation_step()


## Cambia la velocidad de la simulación
func set_simulation_speed(delay_seconds: float) -> void:
	simulation_delay = clampf(delay_seconds, 0.01, 10.0)
	timer.wait_time = simulation_delay
	print("[FireSimulationController] Velocidad ajustada: %.2f seg/paso" % simulation_delay)


## Obtiene información del estado actual
func get_simulation_info() -> Dictionary:
	var info = {
		"is_running": is_running,
		"current_step": current_step,
		"simulation_delay": simulation_delay,
		"is_initialized": bridge.is_simulation_active() if bridge else false
	}
	
	if renderer:
		info["statistics"] = renderer.get_statistics()
	
	return info


## Maneja inputs del teclado para control de la simulación
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:  # Pausar/Reanudar
				if is_running:
					pause_simulation()
				else:
					resume_simulation()
			
			KEY_R:  # Resetear
				reset_simulation()
			
			KEY_S:  # Paso único
				if not is_running:
					step_once()
			
			KEY_ESCAPE:  # Detener
				stop_simulation()
			
			KEY_EQUAL, KEY_PLUS:  # Aumentar velocidad
				set_simulation_speed(simulation_delay * 0.8)
			
			KEY_MINUS:  # Disminuir velocidad
				set_simulation_speed(simulation_delay * 1.2)
