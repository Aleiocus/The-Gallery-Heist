class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 200.0
const _accel : float = 180.0
const _decel : float = 400.0
const _jump_force : float = 250.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _slide_speed : float = 55
const _wall_jump_force : float = 240
const _pushoff_force : float = 130.0
const _dash_force: float = 375

const _death_height_y : float = 150.0
@onready var _coyote_timer : Timer = $CoyoteTimer
@onready var _jump_buffer_timer : Timer = $JumpBufferTimer
@onready var _dash_timer = $DashTimer
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
	PlayerManager.player = self
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_process)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), _state_wall_slide_ph_process)
	_state_machine.change_state("normal")

func _process(delta : float):
	_state_machine.state_process(delta)

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	

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
		
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	move_and_slide()
	var was_on_floor = is_on_floor()

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
	
	if is_on_wall() == true \
		and is_on_floor() == false\
		and velocity.y != 0 :
		_state_machine.change_state("wall_slide")
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()
	
	if Input.is_action_just_pressed("dash"):
		_state_machine.change_state("dash")


func _game_over():
	# Currently set to restart level, can be changed easily here.
	SceneManager.restart_scene()

func _state_wall_slide_ph_process(delta: float):
	
	velocity.y = _slide_speed
	move_and_slide()
	
	if is_on_wall() == false:
		_state_machine.change_state("normal")
	if is_on_floor() == true:
		_state_machine.change_state("normal")
		
	if Input.is_action_just_pressed("jump") \
		and Input.is_action_pressed("left"):
			velocity.y = -_wall_jump_force
			velocity.x = -_pushoff_force
			_state_machine.change_state("normal")
	if Input.is_action_just_pressed("jump") \
		and Input.is_action_pressed("right"):
			velocity.y = -_wall_jump_force
			velocity.x = _pushoff_force
			_state_machine.change_state("normal")

func _state_dash_ph_process(delta: float):
	var _direction = global_position.direction_to(get_global_mouse_position())
	velocity = _direction * _dash_force 
	_dash_timer.start()
	var dashing: bool = true
	if _dash_timer.is_stopped() == false:
		_state_machine.change_state("normal")
	if is_on_wall():
		_state_machine.change_state("wall_slide")
	move_and_slide()

