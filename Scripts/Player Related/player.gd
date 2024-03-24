class_name Player
extends CharacterBody2D

signal died

@onready var _cling_time : Timer = $Timers/ClingTime
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _dash_cooldown : Timer = $Timers/DashCooldown
@onready var _dash_timer : Timer = $Timers/DashTimer
@onready var _dash_trail : Line2D = $DashTrail
@onready var _dust_trail : GPUParticles2D = $DustTrail
@onready var _slide_delay : Timer = $Timers/SlideDelay
@onready var _detect_right : RayCast2D = $Detection/Right
@onready var _detect_left : RayCast2D = $Detection/Left
@onready var _label : Label = $Label
@onready var _score : Label = $Score
@onready var _dash_feedback : Label = $DashFeedback
@onready var _hitbox : Area2D = $Hitbox
@onready var _health_feedback : Label = $HealthFeedback
@onready var _sfx : Dictionary = {
	# TODO: some sounds are not the responsability of this class like coin sfx
	"jump":$SFX/Jump, "dash":$SFX/Dash, "hit_wall":$SFX/HitWall, "coin_pickup":$SFX/CoinPickup,
	"hurt":$SFX/Hurt, "pie_pickup":$SFX/PiePickup, "hit":$SFX/Hit, "hit_confirm":$SFX/HitConfirm, "damage":$SFX/Damage,
	"game_over":$SFX/GameOver
}
@onready var _took_hit : Timer = $Timers/TookHit
@onready var _sprite : AnimatedSprite2D = $Sprite
# TEMP
@onready var _attack_sprite : Sprite2D = $Hitbox/AttackSprite

# Set Variables for overall control feel
var _direction : Vector2
const _max_move_speed : float = 250.0
const _accel : float = 450.0
const _decel : float = 600.0
const _jump_force : float = 260.0
const _run_anim_threshold : float = 150.0
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
const _hit_time : float = 0.2
var _hit_timer : float = _hit_time
const _slide_speed : float = 60
var _pop_up : float = 50

var _can_dash : bool = true
var _dash_direction : Vector2
const _dash_speed: float = 300
const _dash_decel: float = 1000
const _dash_shake_duration : float = 0.2

const _wall_jump_force : float = 260
const _pushoff_force : float = 200.0

const _max_health : int = 2
var _health : int = _max_health
const _damage_shake_duration : float = 0.3
var _player_score : float = 0

var _taking_hit : bool = false

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
	_health_feedback.text = str("Health: ", _health, "/", _max_health)

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	# putting direction here because it is used in multiple instances and I can't find a
	# easy way to pass it through states.
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	
	# Fell off the world
	if global_position.y > Level.death_height_y:
		take_damage(0, 0.0, 0, true)

func get_score(amount : float):
	_player_score += amount
	_score.text = str("Score: ", _player_score, "0")
	_sfx["coin_pickup"].play()
	if amount > 1 :
		_sfx["pie_pickup"].play()
		if _health < _max_health:
			_health += 1
	World.current_score = _player_score

func take_damage(amount : int, force : float, direction : int, is_one_shot : bool = false):
	_taking_hit = true
	if is_one_shot:
		_health = 0
	else:
		_health -= amount
	
	if _health > 0:
		velocity.x = (velocity.x + force) * direction
		velocity.y = -_pop_up
		World.level_camera.shake(LevelCamera.ShakeLevel.low, _damage_shake_duration)
		_sfx["damage"].play()
		
	else:
		# die
		_sfx["game_over"].play()
		died.emit()
	
	_took_hit.start()

# This is in place to pass the input value to other things that players expect to
# respond to input such as attack direction
func get_direction() -> Vector2:
	return _direction

func _state_normal_switch_from(to : String):
	_coyote_timer.stop()
	_jump_buffer_timer.stop()

func _state_normal_process(delta : float):
	# animation
	if is_on_floor():
		if velocity.x == 0:
			_play_animation("Idle")
		elif abs(velocity.x) > _run_anim_threshold:
			var x_input_dir : float = Input.get_axis("left", "right")
			if sign(x_input_dir) == sign(velocity.x):
				_play_animation("Run")
			else:
				_play_animation("Skidding")
		else:
			_play_animation("Walk")
		
	else:
		if velocity.y > 0:
			_play_animation("Falling", true)
		else:
			_play_animation("Jump", true)
	
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
			_sfx["jump"].play()
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# Coyote Timer
	if was_on_floor && is_on_floor() == false:
		# just jumped
		_coyote_timer.start()
	elif was_on_floor == false && is_on_floor():
		# jump landed
		_play_animation("Landing")
		if _jump_buffer_timer.is_stopped() == false:
			velocity.y = -_jump_force
	
	# TODO: is_on_wall is true when climbing on other bodies like scorpion (if hurtbox is off) :')
	if is_on_wall() == true \
		and is_on_floor() == false\
		and _slide_delay.is_stopped() \
		and (_detect_left.is_colliding() \
		or _detect_right.is_colliding()):
		_sfx["hit_wall"].play()
		_state_machine.change_state("wall_slide")
		return
	
	if _can_dash == false && _dash_cooldown.is_stopped() && is_on_floor():
		_can_dash = true
	
	if Input.is_action_just_pressed("dash") && _can_dash && _direction:
		_dash_direction = _direction
		_state_machine.change_state("dash")
		return
	
	if Input.is_action_just_pressed("Basic Attack"):
		_attack_sprite.visible = true
		_hitbox.monitoring = true
		_sfx["hit"].play()
		_state_machine.change_state("attack")

func _state_wall_slide_switch_to(from : StringName):
	_play_animation("Cling")
	_cling_time.start()
	velocity = Vector2(0,0)
	
func _state_wall_slide_ph_process(delta: float):
	if _cling_time.is_stopped():
		_play_animation("Sliding")
		velocity.y = _slide_speed
	
	if Input.is_action_just_pressed("jump") :
		_sfx["jump"].play()
		_slide_delay.start()
		_play_animation("Wall Jump", true)
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
	World.level_camera.shake(LevelCamera.ShakeLevel.low, _dash_shake_duration)
	_sfx["dash"].play()
	_dash_trail.set_active(true)
	_dash_timer.start()
	velocity = Vector2(0,0)
	_can_dash = false

func _state_dash_switch_from(to: StringName):
	_dash_cooldown.start()
	_dash_trail.set_active(false)

func _state_dash_ph_process(delta: float):
	# Trying to reduce the power of vertical dashes, which affect diagonal 
	# dashes
	velocity.x = _dash_speed * _dash_direction.x
	velocity.y = (_dash_speed * _dash_direction.y) * 0.8
	
	move_and_slide()
	
	if _dash_timer.is_stopped() or is_on_wall():
		_dash_timer.stop()
		_state_machine.change_state("normal")
		return

func _state_attack_ph_process(delta: float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	move_and_slide()
	
	_hit_timer -= delta
	if _hit_timer <= 0.0:
		_hit_timer = _hit_time
		_hitbox.monitoring = false
		_attack_sprite.visible = false
		_state_machine.change_state("normal")

# use instead of _sprite.play() to avoid replaying the same animation from the start when it's already playing
func _play_animation(anim_name : String, ignore_if_playing : bool = false):
	if ignore_if_playing && anim_name == _sprite.animation:
		return
	
	_sprite.play(anim_name)

func _on_took_hit_timeout():
	_taking_hit = false
