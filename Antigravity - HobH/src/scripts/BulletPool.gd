extends Node
class_name BulletPool

@export var pool_size: int = 50

var pool: Array[Bullet] = []
var bullet_scene: PackedScene = preload("res://src/scenes/Bullet.tscn")

func _ready() -> void:
	for i: int in range(pool_size):
		_create_new_bullet()

func get_bullet() -> Bullet:
	for bullet: Bullet in pool:
		if not bullet.is_active:
			return bullet
	return _create_new_bullet()

func spawn_bullet(spawn_position: Vector2, direction: Vector2, shooter_id: int) -> void:
	var bullet: Bullet = get_bullet()
	bullet.activate(spawn_position, direction, shooter_id)

func _create_new_bullet() -> Bullet:
	var bullet: Bullet = bullet_scene.instantiate() as Bullet
	add_child(bullet)
	pool.append(bullet)
	return bullet
