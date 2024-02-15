class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 250.0
const _accel : float = 300.0
const _decel : float = 400.0
const _jump_force : float = 250.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _slide_speed : float = 60
const _wall_jump_force : float = 240
const _pushoff_force : float = 130.0
const _dash_speed: float = 280
var _can_dash: bool = true
var _can_slide: bool = true

const _death_height_y : float = 150.0
@onready var _coyote_timer : Timer = $CoyoteTimer
@onready var _jump_buffer_timer : Timer = $JumpBufferTimer
@onready var _dash_timer = $DashTimer
@onready var _just_dashed = $JustDashed
@onready var _slide_delay = $SlideDelay
@onready var _detect_right = $Detection/Right
@onready var _detect_left = $Detection/Left
var _state_machine : StateMachine = StateMachine.new()

# Setup signals
signal is_in_air()
signal is_on_ground()


func _ready():
	PlayerManager.player = self
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_process)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), _state_wall_slide_ph_process)
	_state_machine.change_state("normal")

func _process(delta : float):
	_state_machine.state_process(delta)
	print(_state_machine.get_current_state())
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
		and _can_slide == true \
		and direction \
		and (_detect_left.is_colliding() \
		or _detect_right.is_colliding()):
		_state_machine.change_state("wall_slide")
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()
	
	if Input.is_action_just_pressed("dash"):
		if _can_dash == true:
			_can_dash = false
			_just_dashed.start()
			_state_machine.change_state("dash")
	
	

func _game_over():
	# Currently set to restart level, can be changed easily here.
	SceneManager.restart_scene()

func _state_wall_slide_ph_process(delta: float):

	velocity.y = _slide_speed
	if Input.is_action_just_pressed("jump"):
		_slide_delay.start()
		_can_slide = false
		if _detect_left.is_colliding():
			velocity.x = _pushoff_force
		elif _detect_right.is_colliding():
			velocity.x = -_pushoff_force
		velocity.y = -_wall_jump_force
		_state_machine.change_state("normal")
	if is_on_floor() == true:
		_state_machine.change_state("normal")
	if not _detect_left.is_colliding() \
	 and not _detect_right.is_colliding():
		_state_machine.change_state("normal")
	move_and_slide()

	
func _state_dash_ph_process(delta: float):
	
	var x_direction : float = Input.get_axis("left", "right")
	if x_direction:
		velocity.x = _dash_speed * x_direction
	var y_direction : float = Input.get_axis("up", "down")
	if y_direction:
		velocity.y = _dash_speed * y_direction
	
	
	move_and_slide()
	_dash_timer.start()
	if _dash_timer.is_stopped() == false:
		_state_machine.change_state("normal")
	if is_on_wall():
		_state_machine.change_state("wall_slide")




func _on_just_dashed_timeout():
	if is_on_floor():
		_can_dash = true
	else:
		_just_dashed.start()


func _on_slide_delay_timeout():
	_can_slide = true

