@tool
extends Path2D
class_name PathObject

## makes platform move back and forth between start and end point, when off the platform will teleport back to the start after reahcing the end
@export var _loop : bool = true
## use smoothness when the platform reaches the end,
@export var _smooth_follow : bool = true
## speed per second :)
@export var _speed_per_sec : float = 80.0
@export_range(0.0, 1.0) var _starting_offset_ratio : float :
	set(value):
		_starting_offset_ratio = value
		if is_node_ready() == false:
			await ready
		
		_path_follow.progress_ratio = _starting_offset_ratio
## the start factor between the start and end position
@onready var _path_follow : PathFollow2D = $PathFollow2D

# TODO: "zero length interval" error in some levels. doesn't seem to be because
#       curve resource is missing or has no points

func _ready():
	if Engine.is_editor_hint(): return
	
	if curve == null:
		push_error("Path object has no curve set")
		return
	
	# speed is in pixel rather than ratio in order to easily control it and so
	# that changing path length doesn't affect it
	var speed_to_time : float = curve.get_baked_length() / _speed_per_sec
	
	var move_tween : Tween = create_tween().set_loops()
	if _loop:
		if _smooth_follow:
			move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		move_tween.tween_property(_path_follow, "progress_ratio", 1.0, speed_to_time / 2.0)
		move_tween.tween_property(_path_follow, "progress_ratio", 0.0, speed_to_time / 2.0)
	else:
		move_tween.tween_property(_path_follow, "progress_ratio", 1.0, speed_to_time).from(0.0)
