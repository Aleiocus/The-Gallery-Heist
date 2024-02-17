extends CharacterBody2D


@export var _wander_speed : float = 50.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
var _state_machine : StateMachine = StateMachine.new()
@onready var _label = $Label
var _move_direction 
var _wander_time : float
@onready var _sprite = $Sprite
@onready var _gap_detect_left = $Detectors/GapDetectLeft
@onready var _gap_detect_right = $Detectors/GapDetectRight
@onready var hurtbox = $Hurtbox
var _facing_right : bool = true
@export var _health: float = 3

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
		_facing_right = true
		hurtbox.position = Vector2(8,-6)
	else:
		_sprite.flip_h = true
		_facing_right = false
		hurtbox.position = Vector2(-8,-6)

func _take_damage():
	if _health > 0:
		_health -= 1
	

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	if not is_on_floor():
		velocity.y += _gravity * delta
	if _health <= 0:
		queue_free()
	
func _state_wander_ph_process(delta: float):
	
	if _wander_time > 0:
		_wander_time -= delta
	
	else:
		_randomize_wander()
	
	velocity.x = _move_direction * _wander_speed
	if (_gap_detect_left.is_colliding() == false\
	or _gap_detect_right.is_colliding() == false)\
	and is_on_floor():
		_flip()
	
	move_and_slide()
	
func _state_found_player_ph_process(delta: float):
	pass
	
func _state_just_lost_player_ph_process(delta: float):
	pass

func _flip ():
	if _facing_right == true:
		_move_direction = -1
	if _facing_right == false:
		_move_direction = 1

func _randomize_wander():
	_move_direction = randf_range(-2,2)
	_wander_time = randf_range(1,7)


func _on_area_2d_body_entered(body):
	pass # Replace with function body.


func _on_hurtbox_body_entered(body):
	if body.is_in_group("Player"):
		body._game_over()
