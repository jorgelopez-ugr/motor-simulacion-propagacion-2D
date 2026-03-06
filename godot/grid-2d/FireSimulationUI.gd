extends Control
class_name FireSimulationUI
## Interfaz de usuario para controlar y visualizar la simulación

## Referencias (asignables desde el Inspector)
@export var controller: FireSimulationController
@export var renderer: FireGridRenderer

## Labels para estadísticas (opcionales - usar get_node_or_null)
var label_step: Label
var label_forest: Label
var label_fire: Label
var label_embers: Label
var label_ash: Label
var label_status: Label

## Botones de control (opcionales)
var btn_start: Button
var btn_pause: Button
var btn_step: Button
var btn_reset: Button

## Slider de velocidad (opcional)
var slider_speed: HSlider


func _ready() -> void:
	print("[FireSimulationUI] UI inicializada")
	
	# Obtener referencias a nodos de UI si existen
	label_step = get_node_or_null("MarginContainer/VBoxContainer/StatsPanel/StatsGrid/LabelStep")
	label_forest = get_node_or_null("MarginContainer/VBoxContainer/StatsPanel/StatsGrid/LabelForest")
	label_fire = get_node_or_null("MarginContainer/VBoxContainer/StatsPanel/StatsGrid/LabelFire")
	label_embers = get_node_or_null("MarginContainer/VBoxContainer/StatsPanel/StatsGrid/LabelEmbers")
	label_ash = get_node_or_null("MarginContainer/VBoxContainer/StatsPanel/StatsGrid/LabelAsh")
	label_status = get_node_or_null("MarginContainer/VBoxContainer/StatusPanel/LabelStatus")
	
	btn_start = get_node_or_null("MarginContainer/VBoxContainer/ControlPanel/HBoxContainer/BtnStart")
	btn_pause = get_node_or_null("MarginContainer/VBoxContainer/ControlPanel/HBoxContainer/BtnPause")
	btn_step = get_node_or_null("MarginContainer/VBoxContainer/ControlPanel/HBoxContainer/BtnStep")
	btn_reset = get_node_or_null("MarginContainer/VBoxContainer/ControlPanel/HBoxContainer/BtnReset")
	
	slider_speed = get_node_or_null("MarginContainer/VBoxContainer/ControlPanel/SpeedControl/SliderSpeed")
	
	# Conectar botones
	if btn_start:
		btn_start.pressed.connect(_on_start_pressed)
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_pressed)
	if btn_step:
		btn_step.pressed.connect(_on_step_pressed)
	if btn_reset:
		btn_reset.pressed.connect(_on_reset_pressed)
	
	# Conectar slider
	if slider_speed:
		slider_speed.value_changed.connect(_on_speed_changed)
	
	# Conectar señales del controlador
	if controller:
		controller.simulation_started.connect(_on_simulation_started)
		controller.simulation_stopped.connect(_on_simulation_stopped)
		controller.simulation_paused.connect(_on_simulation_paused)
		controller.simulation_resumed.connect(_on_simulation_resumed)
		controller.step_completed.connect(_on_step_completed)


func _process(_delta: float) -> void:
	_update_statistics()


## Actualiza las estadísticas en pantalla
func _update_statistics() -> void:
	if not controller or not renderer:
		return
	
	var info = controller.get_simulation_info()
	
	# Actualizar paso
	if label_step:
		label_step.text = "Paso: " + str(info["current_step"])
	
	# Actualizar estadísticas de celdas
	if info.has("statistics"):
		var stats = info["statistics"]
		
		if label_forest:
			label_forest.text = "Bosque: " + str(stats["forest"])
		if label_fire:
			label_fire.text = "Fuego: " + str(stats["fire"])
		if label_embers:
			label_embers.text = "Brasas: " + str(stats["embers"])
		if label_ash:
			label_ash.text = "Ceniza: " + str(stats["ash"])
	
	# Actualizar estado
	if label_status:
		if info["is_running"]:
			label_status.text = "Estado: EJECUTANDO"
			label_status.modulate = Color.GREEN
		elif info["is_initialized"]:
			label_status.text = "Estado: PAUSADO"
			label_status.modulate = Color.YELLOW
		else:
			label_status.text = "Estado: DETENIDO"
			label_status.modulate = Color.RED


## Callbacks de botones
func _on_start_pressed() -> void:
	if controller:
		controller.start_simulation()


func _on_pause_pressed() -> void:
	if controller:
		if controller.is_running:
			controller.pause_simulation()
		else:
			controller.resume_simulation()


func _on_step_pressed() -> void:
	if controller:
		controller.step_once()


func _on_reset_pressed() -> void:
	if controller:
		controller.reset_simulation()


func _on_speed_changed(value: float) -> void:
	if controller:
		# Convertir slider (0-100) a delay (0.01-2.0 segundos)
		var delay = 2.0 - (value / 50.0) * 1.99
		controller.set_simulation_speed(delay)


## Callbacks de señales del controlador
func _on_simulation_started() -> void:
	print("[FireSimulationUI] Simulación iniciada")
	if btn_start:
		btn_start.disabled = true
	if btn_pause:
		btn_pause.disabled = false
		btn_pause.text = "Pausar"


func _on_simulation_stopped() -> void:
	print("[FireSimulationUI] Simulación detenida")
	if btn_start:
		btn_start.disabled = false
	if btn_pause:
		btn_pause.disabled = true


func _on_simulation_paused() -> void:
	print("[FireSimulationUI] Simulación pausada")
	if btn_pause:
		btn_pause.text = "Reanudar"


func _on_simulation_resumed() -> void:
	print("[FireSimulationUI] Simulación reanudada")
	if btn_pause:
		btn_pause.text = "Pausar"


func _on_step_completed(step_number: int) -> void:
	print("completed step on number:",step_number)
	pass
