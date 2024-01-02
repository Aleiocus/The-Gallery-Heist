extends RigidBody2D

var _in_hand : bool = false

func _physics_process(delta):
	if _in_hand == true:
		self.position = get_node("../Player/ItemPos").global_position
func _pickup_item():
	if _in_hand == false:
		_in_hand = true
	elif _in_hand == true:
		pass
