extends Camera2D

var _in_air : bool

const _look_ahead_factor = 0.2
var _facing = 0
@onready var _prev_camera_pos = get_target_position()


func _process(delta : float):
	_check_facing()
	_prev_camera_pos = get_target_position()

func _check_facing():
	var new_facing = sign(get_target_position().x - _prev_camera_pos.x)
	if new_facing != 0 && _facing != new_facing:
		_facing = new_facing
		var target_offset = get_viewport_rect().size.x * _look_ahead_factor * _facing
		if _in_air == false:
			var tween = create_tween()
			tween.tween_property(self, "position:x", target_offset, 1)
		elif _in_air == true:
			var tween = create_tween()
			tween.tween_property(self, "position:x", target_offset, .75)


func _on_player_is_in_air():
	drag_vertical_enabled = true
	_in_air = true

func _on_player_is_on_ground():
	drag_vertical_enabled = false
	_in_air = false
