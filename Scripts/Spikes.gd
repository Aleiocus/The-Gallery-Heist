extends Area2D

# Create a hazard such as spikes or such that are an insta kill
func _on_body_entered(body : Node2D):
	if body is Player:
		body.game_over()
