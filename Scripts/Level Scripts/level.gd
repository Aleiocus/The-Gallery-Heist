class_name Level
extends Node2D

# TODO: level should handles:
#       UI and score
#       dialogue player object
#       music
#       pausing
const death_height_y : float = 0.0


func _ready():
	World.level = self
	World.player.died.connect(_on_player_died)

func _on_player_died():
	SceneManager.restart_scene()
