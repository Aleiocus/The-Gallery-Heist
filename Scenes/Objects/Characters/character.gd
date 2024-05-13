class_name Character
extends CharacterBody2D

signal died

@onready var _damaged_sfx : AudioStreamPlayer2D = $Sounds/Damaged
@onready var _damage_cooldown_timer : Timer = $Timers/DamageCooldownTimer
@warning_ignore("unused_private_class_variable")
@onready var _collider : CollisionShape2D = $CollisionShape2D

@warning_ignore("unused_private_class_variable")
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
@warning_ignore("unused_private_class_variable")
var _direction : Vector2 = Vector2.RIGHT
@warning_ignore("unused_private_class_variable")
var _max_health : int
var _health : int
var _damage_cooldown_time : float
var _is_invincible : bool
var _knockback : float = 0.0


func _process(delta : float):
	if _damage_cooldown_timer.is_stopped() == false:
		# TODO: should only modulate character sprite rather than every node
		#       this can be fixed by having a sprite in this class for all characters
		modulate.a = (sin(_damage_cooldown_timer.time_left * 10.0) + 1.0) / 2.0

# override
func take_damage(damage : int, knockback_direction : Vector2, is_deadly : bool = false) -> bool:
	if _is_invincible: return false
	
	var cooldown : bool = _damage_cooldown_timer.is_stopped() == false
	
	if is_deadly:
		_health = 0
	elif cooldown == false:
		_health -= damage
	else:
		# no damage applied due to cooldown, nothing more to do
		return false
	
	if _health > 0:
		velocity += knockback_direction * _knockback
		_damage_cooldown_timer.wait_time = _damage_cooldown_time
		_damage_cooldown_timer.start()
		_damage_taken(damage, false)
		
	else:
		_damage_taken(damage, true)
	
	return true

# override
func _damage_taken(damage : int, die : bool):
	if die:
		queue_free()
		died.emit()
	else:
		_damaged_sfx.play()

func _on_damage_cooldown_timer_timeout():
	modulate.a = 1.0

