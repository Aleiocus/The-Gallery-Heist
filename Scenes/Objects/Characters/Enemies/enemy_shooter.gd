@tool
extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

## the direction that this enemy can shoot in, can be a combination of multiple directions
@export_flags("vertical:1", "horizontal:2", "diagonal:4") var _shoot_direction : int = 3
## how far to detect the player
@export var _detection_radius : float = 80.0 :
	set(value):
		_detection_radius = max(value, 0.0)
		if is_node_ready() == false:
			await ready
		
		_detection_collider.shape.radius = _detection_radius
## how much time between each shot
@export var _shooting_cooldown : float :
	set(value):
		_shooting_cooldown = max(value, 0.1)
## projectile force
@export var _projectile_force : float = 64.0 :
	set(value):
		_projectile_force = max(value, 0.0)

@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection_collider : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var _shooting_cooldown_timer : Timer = $ShootCooldown

const _projectile_scene : PackedScene = preload("res://Scenes/Objects/Projectiles/projectile_shooter_enemy_shot.tscn")

const _align_threshold : float = 0.1
const _align_threshold_diagonal : float = 0.21


func _ready():
	set_process(false)
	if Engine.is_editor_hint(): return
	
	_max_health = 2
	_damage_cooldown_time = 2.0
	_health = _max_health
	_knockback = 20.0
	
	if _shoot_direction == 0:
		push_error("No shoot direction specified, enemy will not shoot")
	
	_sprite.flip_h
	_shooting_cooldown_timer.wait_time = _shooting_cooldown

func _process(delta : float):
	if Engine.is_editor_hint(): return
	
	if _shooting_cooldown_timer.is_stopped():
		var shoot_v : bool = _shoot_direction & 1
		var shoot_h : bool = _shoot_direction & 2
		var shoot_d : bool = _shoot_direction & 4
		var player_direction : Vector2 = (World.level.player.global_position - global_position).normalized()
		
		# pick proper shooting direction based on allowed directions
		# each direction is evaluated based on dot product of player direction and a minimum threshold
		var found_shoot_dir : bool = false
		var shoot_direction : Vector2
		# horizontal
		if shoot_h && found_shoot_dir == false:
			var local_right : Vector2 = transform.basis_xform(Vector2.RIGHT)
			var dot : float = player_direction.dot(local_right)
			if 1.0 - abs(dot) <= _align_threshold:
				found_shoot_dir = true
				shoot_direction = local_right * sign(dot)
		
		# vertical
		if shoot_v && found_shoot_dir == false:
			var local_down : Vector2 = transform.basis_xform(Vector2.DOWN)
			var dot : float = player_direction.dot(local_down)
			if 1.0 - abs(dot) <= _align_threshold:
				found_shoot_dir = true
				shoot_direction = local_down * sign(dot)
		
		# diagonal
		if shoot_d && found_shoot_dir == false:
			var local_down_right : Vector2 = transform.basis_xform(Vector2(0.707107, 0.707107))
			var dot_down_right : float = player_direction.dot(local_down_right)
			
			var local_up_right : Vector2 = transform.basis_xform(Vector2(0.707107, -0.707107))
			var dot_up_right : float = player_direction.dot(local_up_right)
			
			if 1.0 - abs(dot_down_right) <= _align_threshold_diagonal:
				found_shoot_dir = true
				shoot_direction = local_down_right * sign(dot_down_right)
			
			elif 1.0 - abs(dot_up_right) <= _align_threshold_diagonal:
				found_shoot_dir = true
				shoot_direction = local_up_right * sign(dot_up_right)
		
		if found_shoot_dir:
			# shoot
			var instance := _projectile_scene.instantiate()
			instance.global_position = global_position
			get_tree().current_scene.add_child(instance)
			instance.setup(shoot_direction, _projectile_force, [self] as Array[Object])
			_shooting_cooldown_timer.start()
			
			# sprite direction
			var local_right : Vector2 = transform.basis_xform(Vector2.RIGHT)
			_sprite.flip_h = sign(local_right.dot(player_direction)) < 0.0

func _on_detection_area_body_entered(body : Node2D):
	if body is Player:
		set_process(true)

func _on_detection_area_body_exited(body : Node2D):
	if body is Player:
		set_process(false)
