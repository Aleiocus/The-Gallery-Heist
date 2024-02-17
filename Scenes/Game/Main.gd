extends Node2D

@onready var camera_2d = $Camera2D
@onready var label_6 = $Label6
var high_score

func _process(delta):
	high_score = PlayerManager.high_score
	label_6.text = str("High Score: ", high_score)
	
func _input(event):
	if Input.is_action_just_pressed("Toggle Camera (temporary)"):
		camera_2d.make_current()
