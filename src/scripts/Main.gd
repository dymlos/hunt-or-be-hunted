extends Node2D
class_name Main

@export var win_score: int = 15 # Aumentado para el MVP del tótem (estaba en 3)

@onready var totems_container: Node2D = $Totems
@onready var bullet_pool: BulletPool = $BulletPool
@onready var player1: Player = $Players/Player1
@onready var player2: Player = $Players/Player2

@onready var score_label: Label = $UI/UIRoot/ScoreLabel
@onready var winner_label: Label = $UI/UIRoot/WinnerLabel

var score_p1: int = 0
var score_p2: int = 0
var game_over: bool = false

func _ready() -> void:
	InputMapSetup.ensure_actions()

	player1.request_bullet.connect(_on_player_request_bullet)
	player2.request_bullet.connect(_on_player_request_bullet)
	player1.player_died.connect(_on_player_died)
	player2.player_died.connect(_on_player_died)
	
	if totems_container:
		for child in totems_container.get_children():
			if child is Totem:
				child.totem_point_awarded.connect(_on_totem_point_awarded)
	
	_update_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_R and event.pressed and not event.echo:
		_reset_match()

func _on_player_request_bullet(spawn_position: Vector2, direction: Vector2, shooter_id: int) -> void:
	if game_over: return
	bullet_pool.spawn_bullet(spawn_position, direction, shooter_id)

func _on_totem_point_awarded(player_id: int) -> void:
	if game_over: return
	
	if player_id == 1:
		score_p1 += 1
	elif player_id == 2:
		score_p2 += 1
		
	_update_ui()
	
	if score_p1 >= win_score:
		_end_match(1)
	elif score_p2 >= win_score:
		_end_match(2)

func _on_player_died(_victim_id: int, killer_id: int) -> void:
	if game_over: return
	
	if killer_id == 1:
		score_p1 += 1
	elif killer_id == 2:
		score_p2 += 1
		
	_update_ui()
	
	if score_p1 >= win_score:
		_end_match(1)
	elif score_p2 >= win_score:
		_end_match(2)

func _update_ui() -> void:
	if score_label:
		score_label.text = "P1: %d  P2: %d" % [score_p1, score_p2]

func _end_match(winner_id: int) -> void:
	game_over = true
	if winner_label:
		winner_label.text = "PLAYER %d WINS!" % winner_id
		winner_label.visible = true
	
	# Stop players
	player1.process_mode = Node.PROCESS_MODE_DISABLED
	player2.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Disable existing bullets
	for bullet in bullet_pool.pool:
		if bullet.is_active:
			bullet._deactivate()

func _reset_match() -> void:
	score_p1 = 0
	score_p2 = 0
	game_over = false
	
	if winner_label:
		winner_label.visible = false
	_update_ui()
	
	if totems_container:
		for child in totems_container.get_children():
			if child is Totem:
				child.reset_totem()
	
	# Clear bullets
	for bullet in bullet_pool.pool:
		if bullet.is_active:
			bullet._deactivate()
			
	# Reset players strictly
	player1.force_reset()
	player2.force_reset()
