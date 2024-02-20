extends Area2D

const _damage_amount: float = 1.0
const _knockback_force: float = 130.0
var _knockback_direction: float = 1.0
const _extend_vector : Vector2 = Vector2(15.0, 20.0)
@onready var hit_confirm_sfx = $"../SFX/HitConfirm"


func _physics_process(delta : float):
	var player_direction : Vector2 = World.player.get_direction()
	if player_direction != Vector2(0,0):
		position.x = sign(player_direction.x) * _extend_vector.x
		position.y = sign(player_direction.y) * _extend_vector.y
	
	_knockback_direction = player_direction.x

	

func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		hit_confirm_sfx.play()
		body.take_damage(_damage_amount, _knockback_force, _knockback_direction)
