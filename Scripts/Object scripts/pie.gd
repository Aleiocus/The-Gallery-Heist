extends Area2D

# Set range/speed of coinbob
const _bob_height : float = 5.0
const _bob_speed : float = 5.0
# Establish Start location and variables for sinwave
@onready var start_y : float = global_position.y
var t : float = 0.0
@export var _score_value: float = 1.0
@onready var sprite_2d = $Sprite2D


func _ready():
	sprite_2d.frame = randi_range(1,7)

func _process(delta):
	# Calculation for sinwave bob
	t += delta
	var d = (sin(t * _bob_speed) + 1.0) / 2.0
	global_position.y = start_y + (d * _bob_height)

# Call function for body being entered and increase score when collected by player
func _on_body_entered(body):
	if body is Player:
		body.get_score(_score_value)
		queue_free()
