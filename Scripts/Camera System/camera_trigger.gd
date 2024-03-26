@tool
class_name CameraTrigger
extends Area2D

@export var _change_state : bool = false :
	set(value):
		_change_state = value
		notify_property_list_changed()
@export var _change_zoom : bool = false :
	set(value):
		_change_zoom = value
		notify_property_list_changed()
@export var _change_lock : bool = false :
	set(value):
		_change_lock = value
		notify_property_list_changed()

@export_group("Camera State")
@export var _trigger_state : LevelCamera.CameraState :
	set(value):
		_trigger_state = value
		notify_property_list_changed()
@export var _idle_position : Vector2

@export_group("Axis Lock")
@export var _release_x_bound : bool = true :
	set(value):
		_release_x_bound = value
		notify_property_list_changed()
@export var _release_y_bound : bool = true :
	set(value):
		_release_y_bound = value
		notify_property_list_changed()
@export var _x_bound : Vector2
@export var _y_bound : Vector2

@export_group("Camera Properties")
@export var _zoom : Vector2 = Vector2.ONE


func _on_body_entered(body : Node2D):
	if body is Player:
		apply_camera_state()

func apply_camera_state():
	var camera : LevelCamera = World.level.level_camera
	
	if _change_state == false && _change_zoom == false && _change_lock == false:
		push_warning("Camera trigger has no effect")
	
	if _change_state:
		match _trigger_state:
			LevelCamera.CameraState.idle:
				camera.set_state_idle(_idle_position)
			LevelCamera.CameraState.follow:
				camera.set_state_follow()
	
	if _change_zoom:
		camera.set_target_zoom(_zoom)
	
	if _change_lock:
		if _release_x_bound == true:
			camera.remove_axis_bound(true)
		elif _release_x_bound == false:
			camera.set_axis_bound(true, _x_bound)
		
		if _release_y_bound == true:
			camera.remove_axis_bound(false)
		elif _release_y_bound == false:
			camera.set_axis_bound(false, _y_bound)

func _validate_property(property: Dictionary):
	var hide_prop : Callable = func():
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	
	# hide properties that aren't used
	match property["name"]:
		"_trigger_state", "_idle_position":
			if _change_state == false:
				hide_prop.call()
			
			if property["name"] == "_idle_position":
				if _trigger_state != LevelCamera.CameraState.idle:
					hide_prop.call()
		
		"_zoom":
			if _change_zoom == false:
				hide_prop.call()
		
		"_x_bound", "_y_bound", "_release_x_bound", "_release_y_bound":
			if _change_lock == false:
				hide_prop.call()
		
			else:
				if property["name"] == "_x_bound":
					if _release_x_bound:
						hide_prop.call()
				
				elif property["name"] == "_y_bound":
					if _release_y_bound:
						hide_prop.call()
