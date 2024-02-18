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

var _direction : Vector2
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
@onready var _dash_feedback = $DashFeedback
@onready var _hitbox = $Hitbox
@onready var _health_feedback = $HealthFeedback
@onready var _sfx : Dictionary = {
	# TODO: some sounds are not the responsability of this class like coin sfx
	"jump":$SFX/Jump, "dash":$SFX/Dash, "hit_wall":$SFX/HitWall, "coin_pickup":$SFX/CoinPickup,
	"hurt":$SFX/Hurt, "pie_pickup":$SFX/PiePickup, "hit":$SFX/Hit, "hit_confirm":$SFX/HitConfirm, "damage":$SFX/Damage,
	"game_over":$SFX/GameOver
}
@onready var _took_hit = $Timers/TookHit

var _state_machine : StateMachine = StateMachine.new()

func _ready():
	World.player = self
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_process)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", Callable(), Callable(), Callable(), _state_attack_ph_process)
	_state_machine.change_state("normal")
	_score.text = str("Score: ", _player_score)
	World.current_score = _player_score

func _process(delta : float):
	_state_machine.state_process(delta)
	_label.text = str("State: ", _state_machine.get_current_state())
	_dash_feedback.text = str("Can_Dash: ", _can_dash)
	_health_feedback.text = str("Health: ", _player_health,"/3")

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	_direction = Input.get_vector("left", "right", "up", "down")

func get_direction() -> Vector2:
	return _direction

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()

func _state_normal_ph_process(delta : float):
	
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	if _direction.x and _taking_hit == false:
		velocity.x = move_toward(velocity.x, _max_move_speed * _direction.x, _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
	
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			_sfx["jump"].play()
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	move_and_slide()
	var was_on_floor = is_on_floor()
		
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
		_sfx["hit_wall"].play()
		_state_machine.change_state("wall_slide")
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()
	
	if Input.is_action_just_pressed("dash"):
		if _can_dash == true:
			_can_dash = false
			_just_dashed.start()
			_sfx["dash"].play()
			_state_machine.change_state("dash")
	
	if Input.is_action_just_pressed("Basic Attack"):
		_hitbox.monitoring = true
		_sfx["hit"].play()
		_state_machine.change_state("attack")
		if _direction.y and is_on_floor():
			velocity.y = -_jump_force
	
func _game_over():
	_sfx["game_over"].play()
	SceneManager.restart_scene()

func _state_wall_slide_ph_process(delta: float):
	velocity.y = _slide_speed
	if Input.is_action_just_pressed("jump"):
		_sfx["jump"].play()
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
	if _direction.x or _direction.y:
		velocity.x = _dash_speed * _direction.x
		velocity.y = _dash_speed * _direction.y
	else:
		velocity.x = _dash_speed * _direction.x
		velocity.x = move_toward(velocity.x, 0.0, _dash_decel * delta)
		velocity.y = move_toward(velocity.y, 0.0, _dash_decel * delta)
	
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

func _get_score(amount : float):
	_player_score += amount
	_score.text = str("Score: ", _player_score, "0")
	_sfx["coin_pickup"].play()
	if amount > 1 :
		_sfx["pie_pickup"].play()
		if _player_health < 3:
			_player_health += 1
	World.current_score = _player_score

func _state_attack_ph_process(delta: float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	_hit_time -= 1 * delta
	if _hit_time <= 0:
		_hitbox.monitoring = false
		_state_machine.change_state("normal")
	move_and_slide()

func _take_damage (amount, force, direction : int):
	_taking_hit = true
	if _player_health > 0:
		_player_health -= amount
		velocity.x = (velocity.x + force) * direction
		velocity.y = -_pop_up
		_sfx["damage"].play()
	if _player_health <= 0:
		_game_over()
	_took_hit.start()

func _on_took_hit_timeout():
	_taking_hit = false
