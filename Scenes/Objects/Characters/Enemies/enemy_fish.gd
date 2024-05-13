@tool
extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

## how far can this enemy detect the player from
@export var _detection_radius : float = 120.0 :
	set(value):
		_detection_radius = max(value, 0.0)
		if is_node_ready() == false:
			await ready
		
		_detection_collider.shape.radius = _detection_radius

@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var _detection_collider : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var _out_of_water_damage_timer : Timer = $Timers/OutOfWaterDamageTimer

var _state_machine : StateMachine = StateMachine.new()

@onready var _starting_position = global_position
const _acceleration : float = 280.0
const _deceleration : float = 80.0
const _max_speed : float = 160.0
const _idle_min_spawn_distance : float = 16.0
const _water_enter_max_speed : float = 90.0

const _hop_force : float = 200.0

var _is_player_detected : bool = false


func _ready():
	if Engine.is_editor_hint(): return
	
	_max_health = 2
	_damage_cooldown_time = 2.0
	_health = _max_health
	_knockback = 130.0
	
	_state_machine.add_state("normal", _state_normal_switch_to, Callable(), _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("outside_water", _state_outside_water_switch_to, _state_outside_water_switch_from, Callable(), _state_outside_water_ph_process)
	_state_machine.change_state("normal")

func _process(delta : float):
	if Engine.is_editor_hint(): return
	
	_state_machine.state_process(delta)
	
	if velocity.x > 0.0:
		_sprite.flip_h = false
	elif velocity.x < 0.0:
		_sprite.flip_h = true

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	_state_machine.state_physics_process(delta)

func _on_detection_area_body_entered(body : Node2D):
	if body is Player:
		_is_player_detected = true

func _on_detection_area_body_exited(body : Node2D):
	if body is Player:
		_is_player_detected = false

func _on_out_of_water_damage_timer_timeout():
	take_damage(1, Vector2.UP)

func _state_normal_switch_to(from : String):
	# damp effect when entering water
	velocity = velocity.clamp(Vector2.ONE * -_water_enter_max_speed, Vector2.ONE * _water_enter_max_speed)

func _state_normal_process(delta : float):
	if _is_player_detected:
		_sprite.play("attack")
	else:
		_sprite.play("idle")

func _state_normal_ph_process(delta : float):
	if _is_player_detected:
		# attack player
		_direction = (World.level.player.global_position - global_position).normalized()
	else:
		# go back to spawn point
		if global_position.distance_to(_starting_position) > _idle_min_spawn_distance:
			_direction = (_starting_position - global_position).normalized()
		else:
			_direction = Vector2.ZERO
	
	# accelerate
	velocity.x = Utilities.soft_clamp(velocity.x, _direction.x * _acceleration * delta, _max_speed)
	velocity.y = Utilities.soft_clamp(velocity.y, _direction.y * _acceleration * delta, _max_speed)
	
	# decelerate
	velocity.x = Utilities.soft_clamp(velocity.x, -sign(velocity.x) * _deceleration * delta, 0.0)
	velocity.y = Utilities.soft_clamp(velocity.y, -sign(velocity.y) * _deceleration * delta, 0.0)
	
	move_and_slide()
	
	if World.level.is_water_tile(global_position) == false:
		_state_machine.change_state("outside_water")
		return

func _state_outside_water_switch_from(to : String):
	_out_of_water_damage_timer.stop()

func _state_outside_water_switch_to(from : String):
	_out_of_water_damage_timer.start()
	_sprite.play("dying")

func _state_outside_water_ph_process(delta : float):
	if is_on_floor():
		# hop hop hop! hop for you life! hop hop hop! for your kids and your wife!
		velocity.y = Utilities.soft_clamp(velocity.y, -_hop_force, _hop_force)
		var x_dir : int = 1 if randi_range(0, 1) == 0 else -1
		velocity.x = Utilities.soft_clamp(velocity.x, x_dir * _hop_force, _hop_force)
	else:
		# gravity
		velocity.y = Utilities.soft_clamp(velocity.y, _gravity * delta, _gravity)
	
	velocity.x = Utilities.soft_clamp(velocity.x, -sign(velocity.x) * _deceleration * delta, 0.0)
	move_and_slide()
	
	if World.level.is_water_tile(global_position):
		_state_machine.change_state("normal")
		return
