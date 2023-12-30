class_name Pickup
extends Node

var in_range : bool = false
var in_hand : bool = false

func _on_pickup_zone_body_entered(body):
	if body.is_in_group("Player"):
		in_range = true
		print ("in range")
	else:
		pass
func _on_pickup_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_range = false
		print ("leaving range")
	else:
		pass
func _process(delta):
	if Input.is_action_just_pressed("interact") and in_range == true and in_hand != true:
		in_hand = true
		print("pickup")
	elif Input.is_action_just_pressed("interact") and in_hand == true:
		in_hand = false
		print("drop")
	if in_hand == true:
		print("holding")
