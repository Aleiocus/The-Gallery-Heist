extends CharacterBody2D

signal give_score(amount : float)

@export var _wander_speed : float = 50.0
@export var _health: float = 2.0
@export var _damage : float = 1.0
@export var _knockback : float = 80.0

@onready var _label : Label = $Label
@onready var _sprite : Sprite2D = $Sprite
@onready var _gap_detect_left : RayCast2D = $Detectors/GapDetectLeft
@onready var _gap_detect_right : RayCast2D = $Detectors/GapDetectRight
@onready var _hurtbox : Area2D = $Hurtbox
@onready var _took_hit_timer : Timer = $TookHit

var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var _state_machine : StateMachine = StateMachine.new()
var _wander_time : float
var _x_direction : int = 1
var _taking_hit : bool = false
const _pop_up : float = 60.0
const _push_back_force : float = 100.0
const _min_wander_time : float = 1.0
const _max_wander_time : float = 7.0

func _ready():
	_gap_detect_left.add_exception(self)
	_gap_detect_right.add_exception(self)
	
	_state_machine.add_state("wander", _state_wander_switch_to, Callable(), Callable(), _state_wander_ph_process)
	_state_machine.add_state("found_player", Callable(), Callable(), Callable(), _state_found_player_ph_process)
	_state_machine.change_state("wander")
	
func _process(delta : float):
	_state_machine.state_process(delta)
	
	_label.text = str("State: ", _state_machine.get_current_state())
	
	if _x_direction == 1:
		_sprite.flip_h = false
		_hurtbox.scale.x = 1
	elif _x_direction == -1:
		_sprite.flip_h = true
		_hurtbox.scale.x = -1
	
	if global_position.y > Level.death_height_y:
		give_score.emit(10)
		queue_free()

# TODO: we need a component that handles damage and knockback instead of rewritting this for
#       every damage taking object, should also handle damage cooldown
func take_damage(amount : int, force : float, direction : int):
	_taking_hit = true
	if _health > 0:
		_health = _health - amount
		velocity.x = (velocity.x + force) * direction
		velocity.y = -_pop_up
		_took_hit_timer.start()
	else:
		give_score.emit(10)
		queue_free()

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func _state_wander_switch_to(from : StringName):
	_wander_time = randf_range(_min_wander_time, _max_wander_time)

func _state_wander_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	_wander_time = max(_wander_time - delta, 0.0)
	if _wander_time == 0.0:
		_wander_time = randf_range(_min_wander_time, _max_wander_time)
		if randi_range(0, 1) == 0:
			_x_direction = -_x_direction
	
	if _taking_hit == false:
		velocity.x = _x_direction * _wander_speed
	
	if is_on_floor():
		var velocity_sign : int = sign(velocity.x)
		# TODO: we flip direction when a fall is detected but not when a wall is detected
		if ((velocity_sign == 1 && _gap_detect_right.is_colliding() == false) ||
		(velocity_sign == -1 && _gap_detect_left.is_colliding() == false)):
			_x_direction = -_x_direction
	
	move_and_slide()

func _state_found_player_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta

func _on_hurtbox_body_entered(body : Node2D):
	if body.is_in_group("Player"):
		_taking_hit = true
		_took_hit_timer.start()
		body.take_damage(_damage, _knockback, _x_direction)
		velocity.x = _push_back_force * -_x_direction
		velocity.y = -_pop_up

func _on_took_hit_timeout():
	_taking_hit = false
