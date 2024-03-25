class_name Enemy
extends "res://Scripts/Characters/character.gd"

# enemies are named based on their behavior rather than type
# a "patroling" enemy may have different skins for different areas but always
# the same behavior. in the future we can have a "skin" or "type"
# that changes the visuals of each enemy

func _damage_taken(damage : int, die : bool):
	if die:
		# score..
		queue_free()
	else:
		_damaged_sfx.play()
