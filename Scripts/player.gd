class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 175.0
const _accel : float = 180.0
const _decel : float = 375.0
const _jump_force : float = 200.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _push_force : float = 20.0
const _death_height_y : float = 150.0
@onready var _coyote_timer : Timer = $CoyoteTimer
@onready var _jump_buffer_timer : Timer = $JumpBufferTimer
var _state_machine : StateMachine = StateMachine.new()

# Setup signals
signal is_in_air()
signal is_on_ground()

# Setup detection
@onready var _item_pos : Node2D = $ItemPos
@onready var _right_ray : RayCast2D = $RightRay
@onready var _left_ray : RayCast2D = $LeftRay
var _item : PickupItem = null

func _ready():
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_process)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), Callable())
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), Callable())
	_state_machine.change_state("normal")

func _process(delta : float):
	_state_machine.state_process(delta)

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	
	# TODO: what do we do if player is holding item?
	#       do we force drop it, keep it, or prevent player
	#       from changing state to begine with

func _state_normal_ph_process(delta : float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	var direction : float = Input.get_axis("left", "right")
	if direction:
		velocity.x = move_toward(velocity.x, _max_move_speed * direction, _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
	
	# Pickup objects
	# when interact is pressed and nothing is in hand, check left and right colliders, free 
	if Input.is_action_just_pressed("interact") and _item == null:
		var found_item : bool = false
		
		var left = _left_ray.get_collider()
		if left and left.is_in_group("Pickup"):
			_item = left
			found_item = true
		var right = _right_ray.get_collider()
		if found_item == false and right and right.is_in_group("Pickup"):
			_item = right
			found_item = true
		
		if found_item:
			_item.pickup()
			
			_item.get_parent().remove_child(_item)
			_item_pos.add_child(_item)
			_item.position = Vector2.ZERO
			print ("pickup!")
		
	elif Input.is_action_just_pressed("interact") and _item:
		_item.drop()
		
		var global_pos : Vector2 = _item.global_position
		_item_pos.remove_child(_item)
		# this assumes that the item was directly a child of scene root
		get_tree().current_scene.add_child(_item)
		_item.global_position = global_pos
		_item = null
		print ("drop!")
		
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	move_and_slide()
	var was_on_floor = is_on_floor()
	
	# Push rigidbodies
	for i in get_slide_collision_count():
		var col : KinematicCollision2D = get_slide_collision(i)
		if col.get_collider() is RigidBody2D:
			col.get_collider().apply_central_impulse(
				-col.get_normal() * _push_force
			)
	
	# Emit signals to camera
	if is_on_floor() == false:
		emit_signal("is_in_air")
	elif is_on_floor() == true:
		emit_signal("is_on_ground")
		
	# Coyote Timer
	if was_on_floor && !is_on_floor():
		# just jumped
		_coyote_timer.start()
	elif was_on_floor == false && is_on_floor():
		# jump landed
		if _jump_buffer_timer.is_stopped() == false:
			velocity.y = -_jump_force
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()

func _game_over():
	# Currently set to restart level, can be changed easily here.
	SceneManager.restart_scene()
