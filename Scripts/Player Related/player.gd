class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _max_move_speed : float = 250.0
const _accel : float = 450.0
const _decel : float = 600.0
const _jump_force : float = 260.0
const _run_anim_threshold : float = 230.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _wall_jump_force : float = 260
const _pushoff_force : float = 200.0
var _hit_time : float = 0.2

var _can_dash : bool = true
const _dash_speed: float = 300
const _dash_decel: float = 1000

const _slide_speed : float = 60
var _pop_up : float = 50

var _player_health = 2
var _player_score = 0

var _direction : Vector2
var _last_direction : Vector2
var _taking_hit : bool = false
const _death_height_y : float = 150.0
@onready var _cling_time = $Timers/ClingTime
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _dash_cooldown = $Timers/DashCooldown
@onready var _dash_timer = $Timers/DashTimer
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
@onready var _sprite = $Sprite
# TEMP
@onready var _attack_sprite = $Hitbox/AttackSprite

var _state_machine : StateMachine = StateMachine.new()

func _ready():
	World.player = self
	_state_machine.add_state("normal", Callable(), Callable(), _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("dash", _state_dash_switch_to, _state_dash_switch_from, Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", _state_wall_slide_switch_to, Callable(), Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", Callable(), Callable(), Callable(), _state_attack_ph_process)
	_state_machine.change_state("normal")
	_score.text = str("Score: ", _player_score)
	World.current_score = _player_score

func _process(delta : float):
	_state_machine.state_process(delta)
	if velocity.x > 0 :
		_sprite.flip_h = false
	if velocity.x < 0 :
		_sprite.flip_h = true
	
	
	_label.text = str("State: ", _state_machine.get_current_state())
	_dash_feedback.text = str("Can_Dash: ", _can_dash)
	_health_feedback.text = str("Health: ", _player_health, "/3")

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
#putting direction here because it is used in multiple instances and I can't find a
#easy way to pass it through states.
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))

func get_score(amount : float):
	_player_score += amount
	_score.text = str("Score: ", _player_score, "0")
	_sfx["coin_pickup"].play()
	if amount > 1 :
		_sfx["pie_pickup"].play()
		if _player_health < 3:
			_player_health += 1
	World.current_score = _player_score

func take_damage (amount, force, direction : int):
	_taking_hit = true
	if _player_health > 0:
		_player_health -= amount
		velocity.x = (velocity.x + force) * direction
		velocity.y = -_pop_up
		_sfx["damage"].play()
	if _player_health <= 0:
		_game_over()
	_took_hit.start()

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()

func _state_normal_process(delta : float):
	# animation
	if is_on_floor():
		if velocity.x == 0:
			_sprite.play("Idle")
		elif abs(velocity.x) > _run_anim_threshold:
			_sprite.play("Run")
		else:
			_sprite.play("Walk")
	if velocity.y > 0:
		_sprite.play("Falling")

func _state_normal_ph_process(delta : float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	if _direction.x and _taking_hit == false:
		velocity.x = move_toward(velocity.x, _max_move_speed * sign(_direction.x), _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
	
	
	# Allow player to jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			_sprite.play("Jump")
			_sfx["jump"].play()
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	var was_on_floor = is_on_floor()
	move_and_slide()
	
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
		and _slide_delay.is_stopped() \
		and (_detect_left.is_colliding() \
		or _detect_right.is_colliding()):
		_sfx["hit_wall"].play()
		_state_machine.change_state("wall_slide")
		return
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		_game_over()
	
	if _can_dash == false && _dash_cooldown.is_stopped() && is_on_floor():
		_can_dash = true
	
	if Input.is_action_just_pressed("dash") && _can_dash && is_on_floor() == false && _direction:
		_last_direction = _direction
		_state_machine.change_state("dash")
		return
	
	if Input.is_action_just_pressed("Basic Attack"):
		_attack_sprite.visible = true
		_hitbox.monitoring = true
		_sfx["hit"].play()
		_state_machine.change_state("attack")

func _state_wall_slide_switch_to(from : StringName):
	_can_dash = true
	_sprite.play("Cling")
	_cling_time.start()
	velocity = Vector2(0,0)
	
func _state_wall_slide_ph_process(delta: float):
	if _cling_time.is_stopped():
		_sprite.play("Sliding")
		velocity.y = _slide_speed
	if Input.is_action_just_pressed("jump") :
		_sfx["jump"].play()
		_slide_delay.start()
		_sprite.play("Wall Jump")
		if _detect_left.is_colliding():
			velocity.x = _pushoff_force
		elif _detect_right.is_colliding():
			velocity.x = -_pushoff_force
		velocity.y = -_wall_jump_force
		_state_machine.change_state("normal")
		return
	
	if (is_on_floor() or
	(_detect_left.is_colliding() == false and _detect_right.is_colliding() == false)):
		_state_machine.change_state("normal")
	
	move_and_slide()

func _state_dash_switch_to(from : StringName):
	_sfx["dash"].play()
	_dash_timer.start()
	velocity = Vector2(0,0)
	_can_dash = false

func _state_dash_ph_process(delta: float):
	velocity.x = _dash_speed * _last_direction.x
	velocity.y = (_dash_speed * _last_direction.y) * 0.8
	
	move_and_slide()
	
	if _dash_timer.is_stopped() or is_on_floor() or is_on_wall():
		_dash_timer.stop()
		_state_machine.change_state("normal")
		return

func _state_dash_switch_from(to: StringName):
	_dash_cooldown.start()

func _game_over():
	_sfx["game_over"].play()
	SceneManager.restart_scene()

func _state_attack_ph_process(delta: float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	_hit_time -= 1 * delta
	if _hit_time <= 0:
		# TODO: _hit_time is never reset when it reaches zero
		_hitbox.monitoring = false
		_attack_sprite.visible = false
		_state_machine.change_state("normal")
	move_and_slide()

#This is in place to pass the input value to other things that players expect to respond to input
#such as attack direction
func get_direction() -> Vector2:
	print(_direction)
	return _direction

func _on_took_hit_timeout():
	_taking_hit = false
