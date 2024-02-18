class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 250.0
const _accel : float = 300.0
const _decel : float = 475.0
const _jump_force : float = 260.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _slide_speed : float = 60
const _wall_jump_force : float = 245
const _pushoff_force : float = 280.0
const _dash_speed: float = 300
const _dash_decel: float = 1000
var _hit_time : float = 0.2

var _can_dash: bool = true
var _can_slide: bool = true
var _pop_up : float = 50

var _player_health = 2
var _player_score = 0

var x_direction
var y_direction
var last_face_left : bool = false
var last_face_right: bool = true
var look_up : bool = false
var look_down: bool = false
var _taking_hit : bool = false
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
@onready var health_feedback = $HealthFeedback
@onready var hitbox = $Hitbox
@onready var sfx = $SFX
@onready var took_hit = $Timers/TookHit


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
	_label.text = str("State: ", _state_machine.get_current_state())
	dash_feedback.text = str("Can_Dash: ", _can_dash)
	health_feedback.text = str("Health: ", _player_health,"/3")
	
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
	if y_direction > 0:
		look_down = true
	else:
		look_down = false
	if y_direction < 0 :
		look_up = true
	else:
		look_up = false
	

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	

func _state_normal_ph_process(delta : float):
	
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	if x_direction\
	and _taking_hit == false:
		velocity.x = move_toward(velocity.x, _max_move_speed * x_direction, _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
		
	
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			sfx.get_child(0).play()
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
		hitbox._face_right()
	if last_face_left == true:
		hitbox._face_left()
	if look_down == true:
		hitbox._face_down()
	if look_up == true:
		hitbox._face_up()
	
	if Input.is_action_just_pressed("Basic Attack"):
		hitbox.monitoring = true
		sfx.get_child(7).play()
		_state_machine.change_state("attack")
		if look_down == true\
		and is_on_floor():
			velocity.y = -_jump_force
	
func _game_over():
	sfx.get_child(10).play()
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
	_score.text = str("Score: ", _player_score, "0")
	sfx.get_child(4).play()
	if amount > 1 :
		sfx.get_child(6).play()
		if _player_health < 3:
			_player_health += 1
	PlayerManager.current_score = _player_score

func _state_attack_ph_process(delta: float):
		# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	_hit_time -= 1 * delta
	if _hit_time <= 0:
		hitbox.monitoring = false
		_state_machine.change_state("normal")
	move_and_slide()

func _take_damage (amount, force, direction):
	_taking_hit = true
	if _player_health > 0:
		_player_health -= amount
		velocity.x = (velocity.x + force) * direction
		velocity.y = -_pop_up
		sfx.get_child(9).play()
	if _player_health <= 0:
		_game_over()
	took_hit.start()



func _on_took_hit_timeout():
	_taking_hit = false
