extends Area2D

var _damage_amount: float = 1
var _knockback_force: float = 130
var _knockback_direction: float = 1
@onready var sfx = $"../SFX"


func _face_up():
	position = Vector2(0,-18)

func _face_down():
	position = Vector2(0,18)
	
func _face_right():
	_knockback_direction = 1
	position = Vector2(15,0)

func _face_left():
	_knockback_direction = -1
	position = Vector2(-15,0)

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		sfx.get_child(8).play()
		body._take_damage(_damage_amount, _knockback_force, _knockback_direction)

