extends Line2D

var _queue : Array
@export var _max_length : int


func _process(_delta):
	var pos = global_position
	_queue.push_front(pos)
	if _queue.size() > _max_length:
		_queue.pop_back()
	clear_points()
	for point in _queue:
		add_point(pos)
