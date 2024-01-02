extends RigidBody2D

signal _pick_up()


func _pickup_item ():
	emit_signal("_pick_up")
