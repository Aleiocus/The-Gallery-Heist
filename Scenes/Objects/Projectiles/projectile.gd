@tool
extends Area2D

@export var _lifetime : float :
	set(value):
		_lifetime = max(value, 0.0)
@export var _damage : int = 1 :
	set(value):
		_damage = max(value, 0)
@export var _gravity : float
@export var _damping : float = 1.0
@export var _ignore_solid_objects : bool = false
@export var _rotate_to_face_direction : bool = true

@onready var _lifetime_timer : Timer = $Lifetime

var _shoot_direction : Vector2
var _shoot_force : float
var _ignore : Array[Object]

var _velocity : Vector2


func setup(
	shoot_direction : Vector2, shoot_force : float, ignore : Array[Object] = []
):
	_shoot_direction = shoot_direction
	_shoot_force = shoot_force
	_ignore = ignore
	
	if _lifetime != 0.0:
		_lifetime_timer.wait_time = _lifetime
		_lifetime_timer.start()
	
	_velocity = _shoot_direction * _shoot_force

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	_velocity.y += _gravity
	_velocity *= _damping
	position += _velocity * delta
	
	if _rotate_to_face_direction:
		rotation = _velocity.angle()

# overrride
func _impact(hit_character : Character):
	queue_free()

func _on_lifetime_timeout():
	_impact(null)

func _on_body_entered(body : Node2D):
	if body in _ignore:
		return
	
	if body is Character:
		var damage_taken : bool =\
			body.take_damage(_damage, (body.global_position - global_position).normalized())
		if damage_taken:
			_impact(body)
	
	elif _ignore_solid_objects == false:
		_impact(null)
