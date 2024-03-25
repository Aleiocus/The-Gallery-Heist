extends "res://Scripts/Characters/enemy.gd"

@export var _wander_speed : float = 50.0

@onready var _sprite : Sprite2D = $Sprite
@onready var _gap_detect_left : RayCast2D = $Detectors/GapDetectLeft
@onready var _gap_detect_right : RayCast2D = $Detectors/GapDetectRight
@onready var _hurtbox : Area2D = $HurtBox
@onready var _took_hit_timer : Timer = $TookHit
@onready var _debug_vars_visualizer : PanelContainer = $DebugVarsVisualizer

var _state_machine : StateMachine = StateMachine.new()
var _wander_time : float
var _taking_hit : bool = false
const _min_wander_time : float = 1.0
const _max_wander_time : float = 7.0

func _ready():
	_max_health = 2
	_health = _max_health
	
	_gap_detect_left.add_exception(self)
	_gap_detect_right.add_exception(self)
	
	_debug_vars_visualizer.add_var("State")
	
	_state_machine.add_state("wander", _state_wander_switch_to, Callable(), Callable(), _state_wander_ph_process)
	_state_machine.add_state("found_player", Callable(), Callable(), Callable(), _state_found_player_ph_process)
	_state_machine.change_state("wander")
	
func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	
	_debug_vars_visualizer.edit_var("State", _state_machine.get_current_state())
	
	if _direction.x == 1:
		_sprite.flip_h = false
		_hurtbox.scale.x = 1
	elif _direction.x == -1:
		_sprite.flip_h = true
		_hurtbox.scale.x = -1

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func take_damage(damage : int, knockback : float, from : Vector2, is_deadly : bool = false):
	super.take_damage(damage, knockback, from, is_deadly)
	_taking_hit = true
	_took_hit_timer.start()

func _state_wander_switch_to(from : StringName):
	_wander_time = randf_range(_min_wander_time, _max_wander_time)

func _state_wander_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	_wander_time = max(_wander_time - delta, 0.0)
	if _wander_time == 0.0:
		_wander_time = randf_range(_min_wander_time, _max_wander_time)
		if randi_range(0, 1) == 0:
			_direction.x = -_direction.x
	
	if _taking_hit == false:
		velocity.x = _direction.x * _wander_speed
	
	if is_on_floor():
		var velocity_sign : int = sign(velocity.x)
		# TODO: we flip direction when a fall is detected but not when a wall is detected
		if ((velocity_sign == 1 && _gap_detect_right.is_colliding() == false) ||
		(velocity_sign == -1 && _gap_detect_left.is_colliding() == false)):
			_direction.x = -_direction.x
	
	move_and_slide()

func _state_found_player_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta

func _on_took_hit_timeout():
	_taking_hit = false
