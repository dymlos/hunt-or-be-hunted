extends CharacterBody2D
class_name Player

signal request_bullet(spawn_position: Vector2, direction: Vector2, shooter_id: int)
signal player_died(victim_id: int, killer_id: int)

enum PlayerClass {
	MANTIS,
	FLY
}

@export var player_class: PlayerClass = PlayerClass.MANTIS
@export var player_id: int = 1
@export var move_speed: float = 260.0
@export var turn_speed: float = 16.0
@export var shoot_cooldown: float = 0.18

# Melee config
@export var melee_range: float = 80.0
@export var melee_damage: int = 35
@export var melee_cooldown: float = 0.8

# Dash config
@export var dash_duration: float = 0.15
@export var dash_speed_mult: float = 3.5
@export var dash_cooldown: float = 2.0

@export var max_health: int = 100

@onready var _bullet_spawn: Node2D = $BulletSpawn

var current_health: int
var _aim_dir: Vector2 = Vector2.RIGHT
var _cooldown_left: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT

var spawn_position: Vector2
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	spawn_position = global_position
	# Ensure we have a spawn point child
	if _bullet_spawn.get_parent() != self:
		add_child(_bullet_spawn)
	# buscar al otro jugador
	var players = get_parent().get_children()

	for p in players:
		if p != self and p is Player:
			_aim_dir = (p.global_position - global_position).normalized()
			rotation = _aim_dir.angle()
			break

func _physics_process(delta: float) -> void:
	_dash_timer = maxf(0.0, _dash_timer - delta)
	
	if _dash_timer > 0.0:
		velocity = _dash_dir * (move_speed * dash_speed_mult)
		move_and_slide()
	else:
		_update_move(delta)
		
	_update_aim(delta)
	_update_actions(delta)

func _update_move(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength(_action("move_right")) - Input.get_action_strength(_action("move_left")),
		Input.get_action_strength(_action("move_down")) - Input.get_action_strength(_action("move_up"))
	)
	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * move_speed
	move_and_slide()

func _update_aim(delta: float) -> void:
	var aim_input := Vector2(
		Input.get_action_strength(_action("aim_right")) - Input.get_action_strength(_action("aim_left")),
		Input.get_action_strength(_action("aim_down")) - Input.get_action_strength(_action("aim_up"))
	)

	if aim_input.length_squared() > 0.0:
		aim_input = aim_input.normalized()
		# Smooth aim direction
		_aim_dir = _aim_dir.lerp(aim_input, clamp(turn_speed * delta, 0.0, 1.0)).normalized()
		rotation = _aim_dir.angle()

func _update_actions(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)

	if player_class == PlayerClass.FLY:
		# Shoot
		if _cooldown_left <= 0.0 and Input.is_action_pressed(_action("shoot")):
			_cooldown_left = shoot_cooldown
			emit_signal("request_bullet", _bullet_spawn.global_position, _aim_dir, player_id)
		
		# Dash
		if _dash_cooldown_left <= 0.0 and Input.is_action_just_pressed(_action("ability")):
			_dash_cooldown_left = dash_cooldown
			_dash_timer = dash_duration
			
			var input_dir := Vector2(
				Input.get_action_strength(_action("move_right")) - Input.get_action_strength(_action("move_left")),
				Input.get_action_strength(_action("move_down")) - Input.get_action_strength(_action("move_up"))
			)
			if input_dir.length_squared() > 0.0:
				_dash_dir = input_dir.normalized()
			else:
				_dash_dir = _aim_dir
				
	elif player_class == PlayerClass.MANTIS:
		# Melee
		if _cooldown_left <= 0.0 and Input.is_action_pressed(_action("shoot")):
			_cooldown_left = melee_cooldown
			_perform_melee()

func _perform_melee() -> void:
	if not get_parent(): return
	var players = get_parent().get_children()
	for p in players:
		if p != self and p is Player and not p.is_dead:
			var dist = global_position.distance_to(p.global_position)
			if dist <= melee_range:
				var dir_to_target = (p.global_position - global_position).normalized()
				if _aim_dir.dot(dir_to_target) > 0.5: # frontal arc
					p.take_damage(melee_damage, player_id)

func take_damage(amount: int, killer_id: int) -> void:
	if current_health <= 0:
		return
		
	current_health -= amount
	print("Player %d took %d damage! Health: %d" % [player_id, amount, current_health])
	if current_health <= 0:
		_die(killer_id)

func _die(killer_id: int) -> void:
	is_dead = true
	print("Player %d died!" % player_id)
	emit_signal("player_died", player_id, killer_id)
	set_physics_process(false)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	
	await get_tree().create_timer(3.0).timeout
	
	if is_dead:
		_respawn()

func force_reset() -> void:
	if get_parent() and get_parent().get_parent() and "game_over" in get_parent().get_parent():
		if get_parent().get_parent().game_over:
			return
	is_dead = false
	global_position = spawn_position
	current_health = max_health
	visible = true
	set_physics_process(true)
	process_mode = Node.PROCESS_MODE_INHERIT

func _respawn() -> void:
	# Avoid respawning if the match has ended completely between the death and now
	if get_parent() and get_parent().get_parent() and "game_over" in get_parent().get_parent():
		if get_parent().get_parent().game_over:
			return

	is_dead = false
	global_position = spawn_position
	current_health = max_health
	visible = true
	set_physics_process(true)
	process_mode = Node.PROCESS_MODE_INHERIT
	print("Player %d respawned!" % player_id)

func _action(suffix: String) -> String:
	return "p%d_%s" % [player_id, suffix]
