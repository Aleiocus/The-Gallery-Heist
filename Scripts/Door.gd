extends Area2D

# Establish the next scene in an exported box in the inspector (don't edit here)
@export_file("*.tscn") var next_scene

# When the player colides with the body then move to the established scene
func _on_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file(next_scene)
