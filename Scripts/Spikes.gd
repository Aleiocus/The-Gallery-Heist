extends Area2D



#Create a hazard such as spikes or such that are an insta kill
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.game_over()
