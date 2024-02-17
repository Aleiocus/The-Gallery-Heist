extends Node

#For calling the player and storing global player variables

var player
var artwork_recoverd : Dictionary
var current_score: float = 0
var high_score :float = 0

func _process(delta):
	if current_score > high_score:
		high_score = current_score
