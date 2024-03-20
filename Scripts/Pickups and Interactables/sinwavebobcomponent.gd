extends Node2D

# Set range/speed of bob
@export var _bob_height : float = 5.0
@export var _bob_speed : float = 5.0

# Establish Start location and variables for sinwave
@onready var parent = $".."
@onready var start_y : float = parent.global_position.y
var t : float = 0.0


func _process(delta):
	# Calculation for sinwave bob
	t += delta
	var d = (sin(t * _bob_speed) + 1.0) / 2.0
	parent.global_position.y = start_y + (d * _bob_height)
