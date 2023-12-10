extends Area2D

# Export variables to exit behavior for individual enemies.
@export var move_speed : float = 30.0
@export var move_dir : Vector2
var start_pos : Vector2
var target_pos: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	# Establish start position and determine target position.
	start_pos = global_position
	target_pos = start_pos + move_dir

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Move towards target position
	global_position = global_position.move_toward(target_pos, move_speed * delta)
	# When target position is reached, reset target position to original position
	if global_position == target_pos:
		if global_position == start_pos:
			target_pos = start_pos + move_dir
		else: 
			target_pos = start_pos

# Call on body entered to kill the player when collided with.
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.game_over()
