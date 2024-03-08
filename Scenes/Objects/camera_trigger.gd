@tool
extends Area2D

@export var _is_starting_state : bool = false # only 1 trigger can be set as default, this is not enforced so if multiple triggers have this on the last one in the tree will apply
@export var _trigger_state : LevelCamera.CameraState :
	set(value):
		_trigger_state = value
		notify_property_list_changed()
@export var _target_zoom : Vector2 = Vector2.ONE

@export var _idle_position : Vector2
@export var _clamped_limits : Rect2


func _ready():
	if Engine.is_editor_hint() == false && _is_starting_state:
		_apply_camera_state()

func _on_body_entered(body : Node2D):
	if body is Player && _trigger_state != World.level_camera.get_state():
		_apply_camera_state()

func _apply_camera_state():
	match _trigger_state:
		LevelCamera.CameraState.idle:
			World.level_camera.change_state_idle(_idle_position, _target_zoom)
		LevelCamera.CameraState.clamped:
			World.level_camera.change_state_clamped(_clamped_limits, _target_zoom)
		LevelCamera.CameraState.free:
			World.level_camera.change_state_free(_target_zoom)

func _validate_property(property: Dictionary):
	# TODO: hide properties instead of disabling them
	if (property["name"] == "_idle_position" &&
	_trigger_state != LevelCamera.CameraState.idle):
		property["usage"] |= PROPERTY_USAGE_READ_ONLY
	
	elif (property["name"] == "_clamped_limits" &&
	_trigger_state != LevelCamera.CameraState.clamped):
		property["usage"] |= PROPERTY_USAGE_READ_ONLY
