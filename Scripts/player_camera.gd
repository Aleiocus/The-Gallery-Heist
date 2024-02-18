extends Camera2D

const _look_ahead_factor : float = 0.1
var _facing = 0
@onready var _prev_camera_pos = get_target_position()


func _process(delta : float):
	_check_facing()
	
	_prev_camera_pos = get_target_position()

func _check_facing():
	var in_air : bool = !World.player.is_on_floor()
	drag_vertical_enabled = in_air
	
	var new_facing : float = sign(get_target_position().x - _prev_camera_pos.x)
	if new_facing != 0 && _facing != new_facing:
		_facing = new_facing
		var target_offset = get_viewport_rect().size.x * _look_ahead_factor * _facing
		if in_air == false:
			var tween = create_tween()
			tween.tween_property(self, "position:x", target_offset, 1)
		elif in_air == true:
			var tween = create_tween()
			tween.tween_property(self, "position:x", target_offset, .75)
