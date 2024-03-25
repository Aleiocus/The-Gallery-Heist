extends Area2D

@export var _target_player_only : bool = false
@export var damage : int = 1
@export var knockback : float = 130.0

# TODO: due to the way Area2D works, character will only take damage on_enter, need to periodically
#       check for bodies in area and apply damage with a customizable cooldown
func _on_body_entered(body : Node2D):
	if body != get_parent() && body is Character:
		if _target_player_only == false || (_target_player_only && body is Player):
			body.take_damage(damage, knockback, global_position)
