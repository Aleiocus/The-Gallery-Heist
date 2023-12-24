extends Camera2D

const _look_ahead_factor = 0.2
var facing = 0
@onready var _prev_camera_pos = get_target_position()


func _process(delta):
	_check_facing()
	_prev_camera_pos = get_target_position()

func _check_facing():
	var new_facing = sign(get_target_position().x - _prev_camera_pos.x)
	if new_facing != 0 && facing != new_facing:
		facing = new_facing
		var target_offset = get_viewport_rect().size.x * _look_ahead_factor * facing
		position.x = target_offset
		
func _on_player_is_in_air():
	drag_vertical_enabled = true


func _on_player_is_on_ground():
	drag_vertical_enabled = false
