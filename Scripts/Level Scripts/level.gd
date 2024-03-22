class_name Level
extends Node2D

# TODO: level should handles:
#       score
#       dialogue player object
#       music
#       pausing
const _death_height_y : float = 0.0


func _ready():
	World.level = self
	World.player.died.connect(_on_player_died)

func _process(delta : float):
	# Fell off the world
	if World.player.global_position.y > _death_height_y:
		World.player.take_damage(0, 0.0, 0, true)

func _on_player_died():
	SceneManager.restart_scene()
