extends Area2D

# Export variables to exit behavior for individual enemies.
@export var _move_speed : float = 30.0
@export var _move_dir : Vector2
var _start_pos : Vector2
var _target_pos: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Establish start position and determine target position.
	_start_pos = global_position
	_target_pos = _start_pos + _move_dir

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float):
	# Move towards target position
	global_position = global_position.move_toward(
		_target_pos, _move_speed * delta
	)
	# When target position is reached, reset target position to original position
	if global_position == _target_pos:
		if global_position == _start_pos:
			_target_pos = _start_pos + _move_dir
		else: 
			_target_pos = _start_pos

# Call on body entered to kill the player when collided with.
func _on_body_entered(body : Node2D):
	if body is Player:
		body.game_over()
