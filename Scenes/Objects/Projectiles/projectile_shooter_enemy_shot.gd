extends "res://Scenes/Objects/Projectiles/projectile.gd"

# overrride
func _impact(hit_character : Character):
	queue_free()
