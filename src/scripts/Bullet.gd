extends Area2D
class_name Bullet

@export var speed: float = 900.0
@export var lifetime: float = 1.2

@export var damage: int = 25

var is_active: bool = false
var _dir: Vector2 = Vector2.RIGHT
var _life_left: float = 0.0
var _shooter_id: int = -1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_deactivate()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	global_position += _dir * speed * delta
	_life_left -= delta
	if _life_left <= 0.0:
		_deactivate()

func activate(spawn_position: Vector2, direction: Vector2, shooter_id: int) -> void:
	global_position = spawn_position
	_dir = direction.normalized()
	rotation = _dir.angle()
	_life_left = lifetime
	_shooter_id = shooter_id
	is_active = true
	visible = true
	set_physics_process(true)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	global_position = Vector2(-9999.0, -9999.0)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body is Player:
		if body.player_id == _shooter_id:
			return # Don't hit ourselves
		body.take_damage(damage, _shooter_id)
		_request_deactivate()
	else:
		_request_deactivate() # Hit an obstacle or wall
	
func _request_deactivate():
	call_deferred("_deactivate")
