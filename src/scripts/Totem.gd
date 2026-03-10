extends Node2D
class_name Totem

@onready var visual: ColorRect = $Visual
@onready var state_label: Label = $StateLabel
@onready var capture_area: Area2D = $CaptureArea

signal totem_point_awarded(player_id: int)

# Progreso periódico de puntos
var point_timer: float = 0.0
const POINT_INTERVAL: float = 1.0

# Nuevo Label para mostrar el progreso
@onready var progress_label: Label = Label.new()

var players_in_zone: Array[Player] = []

# Progreso de captura: -100 (Player 1) a 100 (Player 2)
var capture_progress: float = 0.0
const MAX_PROGRESS: float = 100.0
const CAPTURE_SPEED: float = 50.0 # Puntos por segundo
const DECAY_SPEED: float = 20.0 # Puntos por segundo hacia 0

enum TotemState {
	NEUTRAL,
	CAPTURING_P1,
	CAPTURING_P2,
	CONTESTED,
	CONTROLLED_P1,
	CONTROLLED_P2
}
var current_state: TotemState = TotemState.NEUTRAL

func _ready() -> void:
	# Añadimos el label de progreso por código temporalmente para no tocar la escena si no es necesario
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	progress_label.add_theme_constant_override("outline_size", 4)
	progress_label.position = Vector2(-50, 70)
	add_child(progress_label)
	
	# Conectamos las señales del área para detectar jugadores
	capture_area.body_entered.connect(_on_capture_area_body_entered)
	capture_area.body_exited.connect(_on_capture_area_body_exited)
	
	_update_state()
	
func _process(delta: float) -> void:
	_process_capture(delta)
	_process_points(delta)

func _process_points(delta: float) -> void:
	if current_state == TotemState.CONTROLLED_P1:
		point_timer += delta
		if point_timer >= POINT_INTERVAL:
			point_timer -= POINT_INTERVAL
			totem_point_awarded.emit(1)
	elif current_state == TotemState.CONTROLLED_P2:
		point_timer += delta
		if point_timer >= POINT_INTERVAL:
			point_timer -= POINT_INTERVAL
			totem_point_awarded.emit(2)
	else:
		point_timer = 0.0

func _on_capture_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if not players_in_zone.has(body):
			players_in_zone.append(body)
			_update_state()

func _on_capture_area_body_exited(body: Node2D) -> void:
	if body is Player:
		if players_in_zone.has(body):
			players_in_zone.erase(body)
			_update_state()

func _process_capture(delta: float) -> void:
	var p1_in: bool = false
	var p2_in: bool = false
	
	for p in players_in_zone:
		if p.player_id == 1:
			p1_in = true
		elif p.player_id == 2:
			p2_in = true

	# Si ambos o ninguno están, decae hacia cero
	if (p1_in and p2_in) or (not p1_in and not p2_in):
		if current_state != TotemState.CONTROLLED_P1 and current_state != TotemState.CONTROLLED_P2:
			if capture_progress > 0:
				capture_progress = maxf(0.0, capture_progress - DECAY_SPEED * delta)
			elif capture_progress < 0:
				capture_progress = minf(0.0, capture_progress + DECAY_SPEED * delta)
	# Solo p1
	elif p1_in and current_state != TotemState.CONTROLLED_P1:
		capture_progress -= CAPTURE_SPEED * delta
		if capture_progress <= -MAX_PROGRESS:
			capture_progress = - MAX_PROGRESS
	# Solo p2
	elif p2_in and current_state != TotemState.CONTROLLED_P2:
		capture_progress += CAPTURE_SPEED * delta
		if capture_progress >= MAX_PROGRESS:
			capture_progress = MAX_PROGRESS
			
	_update_state()

func _update_state() -> void:
	var p1_in: bool = false
	var p2_in: bool = false
	
	for p in players_in_zone:
		if p.player_id == 1:
			p1_in = true
		elif p.player_id == 2:
			p2_in = true

	# Determinar el estado interno
	if capture_progress <= -MAX_PROGRESS:
		current_state = TotemState.CONTROLLED_P1
	elif capture_progress >= MAX_PROGRESS:
		current_state = TotemState.CONTROLLED_P2
	elif p1_in and p2_in:
		current_state = TotemState.CONTESTED
	elif p1_in:
		current_state = TotemState.CAPTURING_P1
	elif p2_in:
		current_state = TotemState.CAPTURING_P2
	else:
		current_state = TotemState.NEUTRAL

	# Actualizar visuals
	match current_state:
		TotemState.CONTROLLED_P1:
			state_label.text = "Controlled by P1"
			visual.color = Color(0.8, 0.2, 0.2) # Rojo pleno
		TotemState.CONTROLLED_P2:
			state_label.text = "Controlled by P2"
			visual.color = Color(0.2, 0.2, 0.8) # Azul pleno
		TotemState.CONTESTED:
			state_label.text = "Contested"
			visual.color = Color(0.8, 0.8, 0.2) # Amarillo
		TotemState.CAPTURING_P1:
			state_label.text = "Capturing P1"
			visual.color = Color(0.6, 0.4, 0.4) # Rojo apagado
		TotemState.CAPTURING_P2:
			state_label.text = "Capturing P2"
			visual.color = Color(0.4, 0.4, 0.6) # Azul apagado
		TotemState.NEUTRAL:
			state_label.text = "Neutral"
			visual.color = Color(0.8, 0.8, 0.8) # Gris

	# Actualizar label de progreso (mostramos el valor absoluto para que sea más legible)
	progress_label.text = "Progreso: %d%%" % int(absf(capture_progress))

func reset_totem() -> void:
	capture_progress = 0.0
	point_timer = 0.0
	players_in_zone.clear()
	_update_state()
