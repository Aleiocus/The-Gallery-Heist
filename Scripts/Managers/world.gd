extends Node

# global data

var level : Level
var artwork_recoverd : Dictionary
var unlocked_levels : Array
var current_score : float : 
	set(value):
		current_score = value
		if current_score > high_score:
			high_score = current_score

var high_score : float

func _ready():
	SceneManager.scene_changed.connect(_on_scene_changed)
	_on_scene_changed() # call for starting scene

func _on_scene_changed():
	if get_tree().current_scene is Level:
		level = get_tree().current_scene
	else:
		level = null
