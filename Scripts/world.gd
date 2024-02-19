extends Node

# Global class for dependency management between level objects

var player : Player
var artwork_recoverd : Dictionary
var current_score : float : 
	set(value):
		current_score = value
		if current_score > high_score:
			high_score = current_score

var high_score : float

func clear():
	# NOTE: for now this gets called on scene changed, in the future
	#       we'd want to call this specificaly when changing to a "Level" scene
	player = null
	artwork_recoverd = {}
	current_score = 0.0
	high_score = 0.0