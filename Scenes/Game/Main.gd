extends Node2D

@onready var camera_2d = $Camera2D

func _input(event):
	if Input.is_action_just_pressed("Toggle Camera (temporary)")\
	and not camera_2d.is_current():
		camera_2d.make_current()