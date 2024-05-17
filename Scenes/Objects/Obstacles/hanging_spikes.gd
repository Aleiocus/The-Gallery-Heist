extends AnimatableBody2D

const _max_rot_speed : float = 500.0
const _rot_accel : float = 370.0
var _rotation_speed : float = _max_rot_speed
var _rotation_direction : int = 1


func _physics_process(delta : float):
	_rotation_speed = min(
		_rotation_speed + _rot_accel * delta, _max_rot_speed
	)
	rotation_degrees += _rotation_direction * _rotation_speed * delta

func _on_hurt_box_applied_damage():
	_rotation_direction *= -1
	_rotation_speed = 0.0
