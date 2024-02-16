extends CharacterBody2D


@export var _wander_speed : float = 50.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var _state_machine : StateMachine = StateMachine.new()
@onready var _label = $Label
var _move_direction 
var _wander_time : float
@onready var _sprite = $Sprite

func _ready():
	_state_machine.add_state("wander", Callable(), Callable(), Callable(),_state_wander_ph_process)
	_state_machine.add_state("found_player", Callable(), Callable(), Callable(),_state_found_player_ph_process)
	_state_machine.add_state("just_lost_player", Callable(), Callable(), Callable(), _state_just_lost_player_ph_process)
	_state_machine.change_state("wander")
	
func _process(delta : float):
	_state_machine.state_process(delta)
	_label.text = str("State: ", _state_machine.get_current_state())
	if velocity.x > 0 :
		_sprite.flip_h = false
	else:
		_sprite.flip_h = true
		
func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	if not is_on_floor():
		velocity.y += _gravity * delta
	
func _state_wander_ph_process(delta: float):
	
	if _wander_time > 0:
		_wander_time -= delta
	
	else:
		_randomize_wander()
	
	velocity.x = _move_direction * _wander_speed
	
	move_and_slide()
	
func _state_found_player_ph_process(delta: float):
	pass
	
func _state_just_lost_player_ph_process(delta: float):
	pass


func _randomize_wander():
	_move_direction = randf_range(-1,1)
	_wander_time = randf_range(1,7)
