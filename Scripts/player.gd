class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 250.0
const _accel : float = 300.0
const _decel : float = 450.0
const _jump_force : float = 260.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _slide_speed : float = 60
const _wall_jump_force : float = 245
const _pushoff_force : float = 280.0
const _dash_speed: float = 300
const _dash_decel: float = 1000
var _hit_time : float = 0.15

var _can_dash: bool = true
var _can_slide: bool = true

var _player_score = 0

var x_direction
var y_direction
var last_face_left : bool = false
var last_face_right: bool = true
const _death_height_y : float = 150.0
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _dash_timer = $Timers/DashTimer
@onready var _just_dashed = $Timers/JustDashed
@onready var _slide_delay = $Timers/SlideDelay
@onready var _detect_right = $Detection/Right
@onready var _detect_left = $Detection/Left
@onready var _label = $Label
@onready var _score = $Score
@onready var dash_feedback = $DashFeedback
@onready var hitbox = $Hitbox
@onready var jumpsfx = $SFX/Jumpsfx
@onready var sfx = $SFX

var _state_machine : StateMachine = StateMachine.new()

# Setup signals
signal is_in_air()
signal is_on_ground()


func _ready():
	PlayerManager.player = self
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_process)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", Callable(), Callable(), Callable(), _state_attack_ph_process)
	_state_machine.change_state("normal")
	_score.text = str("Score: ", _player_score)
	PlayerManager.current_score = _player_score

func _process(delta : float):
	_state_machine.state_process(delta)
	_label.text = str("State:", _state_machine.get_current_state())
	dash_feedback.text = str("Can_Dash: ", _can_dash)
	
	
func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	x_direction = Input.get_axis("left", "right")
	if x_direction > 0:
		last_face_right = true
		last_face_left = false
	if x_direction < 0:
		last_face_right = false
		last_face_left = true
	y_direction = Input.get_axis("up", "down")


func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	

func _state_normal_ph_process(delta : float):
	
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	if x_direction:
		velocity.x = move_toward(velocity.x, _max_move_speed * x_direction, _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
		
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			jumpsfx.play()
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
		and (_detect_left.is_colliding() \
		or _detect_right.is_colliding()):
		sfx.get_child(3).play()
		_state_machine.change_state("wall_slide")
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()
	
	if Input.is_action_just_pressed("dash"):
		if _can_dash == true:
			_can_dash = false
			_just_dashed.start()
			sfx.get_child(2).play()
			_state_machine.change_state("dash")
	
	if last_face_right == true:
		hitbox.position.x = 15
	if last_face_left == true:
		hitbox.position.x = -15
	
	if Input.is_action_just_pressed("Basic Attack"):
		_state_machine.change_state("attack")
	
func _game_over():
	
	SceneManager.restart_scene()


func _state_wall_slide_ph_process(delta: float):
	velocity.y = _slide_speed
	if Input.is_action_just_pressed("jump"):
		sfx.get_child(1).play()
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
	
	if x_direction\
	or y_direction:
		velocity.x = _dash_speed * x_direction
		velocity.y = _dash_speed * y_direction
	else:
		if last_face_left == true:
			velocity.x = -_dash_speed
		elif last_face_right == true:
			velocity.x = _dash_speed
		velocity.x = move_toward(velocity.x, 0.0, _dash_decel * delta)
		velocity.y = move_toward(velocity.y, 0.0, _dash_decel* delta)

	
	
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

func _get_score (amount):
	_player_score += amount
	_score.text = str("Score: ", _player_score)
	sfx.get_child(4).play()
	if amount > 1 :
		sfx.get_child(6).play()
	PlayerManager.current_score = _player_score

func _state_attack_ph_process(delta: float):
		# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	hitbox.monitoring = true
	_hit_time -= 1 * delta
	if _hit_time <= 0:
		hitbox.monitoring = false
		_state_machine.change_state("normal")
	move_and_slide()
