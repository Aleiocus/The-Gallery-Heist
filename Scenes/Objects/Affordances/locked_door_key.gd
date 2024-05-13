@tool
class_name LockedDoorKey
extends Area2D

signal insert_animation_finished

## helper to show which door requires this key
@export var _show_owner_door : bool = false :
	set(value):
		_show_owner_door = value
		queue_redraw()

enum State {idle, follow, insert}

var _owner_door : LockedDoor = null
var _state : State = State.idle
const _keys_avoidance_offset : float = 400.0
const _min_player_distance : float = 14.0
const _follow_lerp_factor : float = 2.0
const _insert_tween_time : float = 1.2

func get_state() -> State:
	return _state

func set_owner_door(door : LockedDoor):
	if door == _owner_door: return
	
	if _owner_door:
		# notify previous owner. only 1 door for each key
		_owner_door.remove_key(self)
	_owner_door = door
	
	# redraw in case _show_owner_door is on
	queue_redraw()

func insert_in_door():
	_state = State.insert
	# animate into door
	var tween : Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", _owner_door.get_center(), _insert_tween_time)
	await tween.finished
	
	insert_animation_finished.emit()
	queue_free()

func _ready():
	if Engine.is_editor_hint(): return
	
	if _owner_door == null:
		push_error("Key has no owner door")
	set_notify_transform(true)

func _notification(what : int):
	if Engine.is_editor_hint(): return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		# our position has changes, redraw in case _show_owner_door is on 
		queue_redraw()

func _process(delta : float):
	if Engine.is_editor_hint(): return
	
	if _state == State.follow:
		var player_distance : float = global_position.distance_to(World.level.player.global_position)
		if player_distance >= _min_player_distance:
			var target_pos : Vector2 = World.level.player.global_position
			for area in get_overlapping_areas():
				if area is LockedDoorKey:
					# avoid other keys
					target_pos += (global_position - area.global_position).normalized() * _keys_avoidance_offset * delta
			
			global_position = lerp(global_position, target_pos, _follow_lerp_factor * delta)

func _draw():
	if Engine.is_editor_hint() == false: return
	
	if _owner_door && _show_owner_door:
		draw_line(
			Vector2.ZERO, _owner_door.get_center() - global_position,
			Color.WHITE
		)

func _on_body_entered(body : Node2D):
	if body is Player && _state == State.idle:
		_state = State.follow
