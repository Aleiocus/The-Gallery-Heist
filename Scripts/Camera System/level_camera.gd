class_name LevelCamera
extends Camera2D

# TODO: addon to show camera constraints when a trigger node is selected
enum CameraState {idle, clamped, free}
enum ShakeLevel {low, medium, high}

# TEMP: forces free state if other states are giving you a headach
@export var _debug_force_free : bool = false

@onready var _shake_timer : Timer = $ShakeTimer

var _curr_state : CameraState
const _speed : float = 110.0
const _zoom_speed : float = 1.6
var _target_zoom : Vector2 = Vector2.ONE

const _look_ahead_offset : float = 22.0
const _player_velocity_factor : float = 0.6
const _distance_factor : float = 1.4
var _target_position : Vector2
var _clamp_limits : Rect2

const _shake_data : Dictionary = {
	ShakeLevel.low:{"max_offset":1.0},
	ShakeLevel.medium:{"max_offset":4.0},
	ShakeLevel.high:{"max_offset":9.0}
}
var _curr_shake_level : ShakeLevel


func _ready():
	if _debug_force_free:
		change_state_free(Vector2.ONE)

func _process(delta : float):
	# update zoom
	if zoom != _target_zoom:
		zoom.x = move_toward(zoom.x, _target_zoom.x, _zoom_speed * delta)
		zoom.y = move_toward(zoom.y, _target_zoom.y, _zoom_speed * delta)
	var player : Player = World.level.player
	
	# calc camera movement speed
	var distance_speed_modifier : float
	var final_speed : float
	if _curr_state == CameraState.idle:
		distance_speed_modifier =\
			global_position.distance_to(_target_position) * _distance_factor
		final_speed = (_speed + distance_speed_modifier) * delta
	elif _curr_state == CameraState.clamped || _curr_state == CameraState.free:
		distance_speed_modifier =\
			global_position.distance_to(player.global_position) * _distance_factor
		final_speed = (_speed + distance_speed_modifier) * delta
	
	# calc destination
	var target_position : Vector2
	if _curr_state == CameraState.idle:
		target_position = _target_position
	elif _curr_state == CameraState.clamped || _curr_state == CameraState.free:
		var velocity_offset : float = player.velocity.length() * _player_velocity_factor
		target_position = Vector2(
			player.global_position.x + sign(player.velocity.x) * (_look_ahead_offset + velocity_offset),
			player.global_position.y + sign(player.velocity.y) * (velocity_offset)
		)
	
	if _curr_state == CameraState.clamped:
		# clamp
		target_position.x = clamp(target_position.x, _clamp_limits.position.x, _clamp_limits.size.x)
		target_position.y = clamp(target_position.y, _clamp_limits.position.y, _clamp_limits.size.y)
	
	global_position = Vector2(
		move_toward(global_position.x, target_position.x, final_speed),
		move_toward(global_position.y, target_position.y, final_speed)
	)
	
	# shake
	if _shake_timer.is_stopped() == false:
		var max_offset : float = _shake_data[_curr_shake_level]["max_offset"]
		offset.x = randf_range(-max_offset, max_offset)
		offset.y = randf_range(-max_offset, max_offset)

func shake(shake_level : ShakeLevel, duration : float):
	_curr_shake_level = shake_level
	
	_shake_timer.wait_time = duration
	_shake_timer.start()

func get_state() -> CameraState:
	return _curr_state

func change_state_idle(position_ : Vector2, zoom_ : Vector2):
	if _debug_force_free: return
	
	_target_position = position_
	_target_zoom = zoom_
	_curr_state = CameraState.idle

func change_state_clamped(limits : Rect2, zoom_ : Vector2):
	if _debug_force_free: return
	
	_clamp_limits = limits
	_target_zoom = zoom_
	_curr_state = CameraState.clamped

func change_state_free(zoom_ : Vector2):
	_target_zoom = zoom_
	_curr_state = CameraState.free

func _on_shake_timer_timeout():
	offset = Vector2.ZERO
