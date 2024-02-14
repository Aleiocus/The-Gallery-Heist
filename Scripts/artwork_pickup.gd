extends Area2D
class_name ArtPickup

@onready var sprite = $Sprite
@onready var shape = $Shape
@export var art_data : ArtData

const _bob_height : float = 5.0
const _bob_speed : float = 5.0
@onready var start_y : float = global_position.y
var t : float = 0.0


func _ready():
	sprite.texture = art_data.texture
	shape.shape.size = art_data.size
# BUG IF 2 ARTWORKS ARE LOADING, THE LAST ARTDATA IS USED IN THIS OPERATION

func _process(delta):
	# Calculation for sinwave bob
	t += delta
	var d = (sin(t * _bob_speed) + 1.0) / 2.0
	global_position.y = start_y + (d * _bob_height)



func _on_body_entered(body):
	if body.is_in_group("player"):
		pass
