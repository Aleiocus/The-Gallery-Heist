extends Line2D

@export var _max_length : int
@onready var _point_timer : Timer = $PointTimer
var _is_active : bool = false


func set_active(active : bool):
	_is_active = active

func _on_point_timer_timeout():
	global_position = Vector2.ZERO
	
	if _is_active:
		add_point(World.level.player.global_position)
		if points.size() >= _max_length:
			remove_point(0)
	
	else:
		# remove remaining points
		if points.size():
			remove_point(0)
