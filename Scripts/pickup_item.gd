class_name PickupItem
extends RigidBody2D

@onready var _collider : CollisionShape2D = $shape

func pickup():
	# disable collision
	_collider.disabled = true
	freeze = true

func drop():
	_collider.disabled = false
	freeze = false
