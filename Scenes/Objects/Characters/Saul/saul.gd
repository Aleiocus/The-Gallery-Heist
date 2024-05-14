class_name Player
extends "res://Scenes/Objects/Characters/character.gd"

signal respawned
signal interacted

@onready var _cling_timer : Timer = $Timers/ClingTime
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _variable_jump_timer : Timer = $Timers/VariableJumpTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _dash_cooldown : Timer = $Timers/DashCooldown
@onready var _dash_timer : Timer = $Timers/DashTimer
@onready var _footstep_timer : Timer = $Timers/FootstepTimer
@onready var _cancel_slide_delay : Timer = $Timers/CancelSlideDelay
@onready var _wall_grab_cooldown : Timer = $Timers/WallGrabCooldown
@onready var _water_timer : Timer = $Timers/WaterTimer
@onready var _look_offset_timer : Timer = $Timers/LookOffsetTimer

@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _dash_trail : Node2D = $DashTrail
@onready var _detect_right : RayCast2D = $Detection/Right
@onready var _detect_left : RayCast2D = $Detection/Left
var _default_collider_size : Vector2
@onready var _sfx : Dictionary = {
	"jump":$Sounds/Jump, "dash":$Sounds/Dash, "hit_wall":$Sounds/HitWall,
	"died":$Sounds/Died, "footstep":$Sounds/Footstep,
	"slide":$Sounds/Slide, "splash":$Sounds/Splash, "water_ambience":$Sounds/WaterAmbience
}

@onready var _walk_dust_particles : GPUParticles2D = $Particles/WalkDust
@onready var _slide_dust_particles : GPUParticles2D = $Particles/SlideDust
@onready var _jump_particles : GPUParticles2D = $Particles/Jump
@onready var _damage_particles : GPUParticles2D = $Particles/Damge
@onready var _bubbles_particles : GPUParticles2D = $Particles/Bubbles
@onready var _splash_sprite : AnimatedSprite2D = $Splash

# Set Variables for overall control feel
var _facing : Vector2 = Vector2.RIGHT
const _max_move_speed : float = 250.0
const _max_fall_speed : float = 860.0
const _accel : float = 450.0
const _decel : float = 1000.0
const _jump_force : float = 300.0
const _variable_jump_cutoff : float = 0.5
const _run_anim_threshold : float = 150.0
const _slide_speed : float = 60.0
const _slide_speed_fast : float = 120.0
const _walk_footstep_time : float = 0.6
const _run_footstep_time : float = 0.3
var _is_look_offset_applied : bool
const _fall_anim_intensity_thresholds : Array = [0.0, _max_fall_speed * 0.3, _max_fall_speed * 0.7, _max_fall_speed] # when to play each fall animation. from least to most intense
const _jump_anim_intensity_thresholds : Array = [_jump_force, _jump_force * 0.8, 0.0] # when to play each jump animation. from most to least intense

const _max_swim_speed : float = 140.0
const _water_enter_max_speed : float = 80.0
const _out_of_water_push : float = 200.0
const _water_accel : float = 320.0
const _water_decel : float = 150.0
const _max_air : int = 5
var _air : int = _max_air
var _was_on_water_surface : bool = false
const _water_collider_size : Vector2 = Vector2(28, 14)
const _splash_sprite_spawn_offset : Vector2 = Vector2(0, -12)
var _water_muffle_effect : AudioEffectLowPassFilter = AudioEffectLowPassFilter.new()

# NOTE: both _dash_locks and _can_dash affects ability to dash. except the former is set by other scripts, and the latter is set by self
var _dash_locks : int = 0
var _can_dash : bool = true
const _dash_speed: float = 300
const _dash_shake_duration : float = 0.3

const _wall_push_force : float = 230.0 # push is in the x axis, jump is in the y
const _wall_jump_force : float = 260.0

const _damage_shake_duration : float = 0.3
const _damage_pause_time : float = 0.14

var _dummy_locks : int = 0
var _dummy_prev_state : String

const _master_bus_idx : int = 0
var _state_machine : StateMachine = StateMachine.new()

func _ready():
	_max_health = 4
	_damage_cooldown_time = 1.6
	_health = _max_health
	_knockback = 130.0
	
	_default_collider_size = _collider.shape.size
	_water_muffle_effect.cutoff_hz = 640
	
	_state_machine.add_state("normal", Callable(), _state_normal_switch_from, _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("dash", _state_dash_switch_to, _state_dash_switch_from, Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", _state_wall_slide_switch_to, _state_wall_slide_switch_from, Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("swim", _state_swim_switch_to, _state_swim_switch_from, Callable(), _state_swim_ph_process)
	_state_machine.add_state("dummy", _state_dummy_switch_to, Callable(), Callable(), Callable())
	_state_machine.add_state("dead", _state_dead_switch_to, _state_dead_switch_from, Callable(), Callable())
	_state_machine.change_state("normal")
	
	await get_tree().process_frame # wait for level to get ready
	World.level.interface.setup(_max_health, _max_air)

func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	if _facing.x > 0:
		_sprite.flip_h = false
	if _facing.x < 0:
		_sprite.flip_h = true
	
	if _state_machine.get_current_state() != "dead":
		# interaction
		if Input.is_action_just_pressed("interact"):
			interacted.emit()
		
		# check water
		if _state_machine.get_current_state() != "swim" && World.level.is_water_tile(global_position):
			_state_machine.change_state("swim")

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func _exit_tree():
	# in case we exit scene while player is in water
	for i in AudioServer.get_bus_effect_count(_master_bus_idx):
		if AudioServer.get_bus_effect(_master_bus_idx, i) == _water_muffle_effect:
			AudioServer.remove_bus_effect(_master_bus_idx, i)
			break

func set_dummy_locks(lock : bool):
	match lock:
		true : _dummy_locks += 1
		false : _dummy_locks -= 1
	assert(_dummy_locks >= 0, "Bug detected, a lock is being removed without being added first.")
	
	if _dummy_locks == 0:
		_state_machine.change_state(_dummy_prev_state)
	
	elif _dummy_locks > 0:
		if _state_machine.get_current_state() != "dead":
			_dummy_prev_state = _state_machine.get_current_state()
			_state_machine.change_state("dummy")

func can_dash():
	return _can_dash && _dash_locks == 0

func refill_dash():
	if _can_dash == false && _dash_locks == 0:
		_set_can_dash(true)
		
		if _dash_cooldown.is_stopped() == false:
			_dash_cooldown.stop()

func set_dash_lock(lock : bool):
	match lock:
		true : _dash_locks += 1
		false : _dash_locks -= 1
	assert(_dash_locks >= 0, "Bug detected, a lock is being removed without being added first.")
	
	if _dash_locks == 0:
		World.level.interface.set_dash_locked(false)
	
	elif _dash_locks > 0:
		World.level.interface.set_dash_locked(true)
		_set_can_dash(false)
	

func heal(amount : int):
	if _health == _max_health: return
	
	var old_health : int = _health
	_health = min(_health + amount, _max_health)
	World.level.interface.set_health(old_health, _health)

func take_damage(damage : int, knockback_direction : Vector2, is_deadly : bool = false) -> bool:
	if _state_machine.get_current_state() == "dead" || _state_machine.get_current_state() == "dummy":
		return false
	
	var old_health : int = _health
	var applied : bool = super.take_damage(damage, knockback_direction, is_deadly)
	if applied:
		_play_animation("Damaged")
		World.level.interface.set_health(old_health, _health)
		World.level.pause_manager.set_gameplay_pause(true)
		get_tree().create_timer(_damage_pause_time).timeout.connect(
			func(): World.level.pause_manager.set_gameplay_pause(false)
		)
	
	return applied

func reset_from_checkpoint(checkpoint_position : Vector2):
	assert(_state_machine.get_current_state() == "dead")
	
	global_position = checkpoint_position
	# wait for hurtbox Area2D to update its collision
	# otherwise objects that apply continuous damage like spikes
	# will damage player on respawn because they haven't yet
	# detected that player has exited them
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	World.level.interface.set_health(_health, _max_health)
	_health = _max_health
	World.level.interface.set_air(_air, _max_air)
	_air = _max_air
	_facing = Vector2.RIGHT
	_direction = Vector2.RIGHT
	_dash_locks = 0
	_dummy_locks = 0
	_state_machine.change_state("normal")
	
	respawned.emit()

func get_facing() -> Vector2:
	return _facing

func _damage_taken(damage : int, die : bool):
	if die:
		_sfx["died"].play()
		_state_machine.call_deferred("change_state", "dead")
	else:
		World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _damage_shake_duration)
		_damage_particles.restart()
		_damaged_sfx.play()
		
		if _state_machine.get_current_state() == "wall_slide":
			# stop wall slide on damage
			_state_machine.change_state("normal")
			return

func _jump(force : float, replace_veloctiy : bool = false):
	# a helper function that handles common jump logic, use this instead of applying jump force directly
	if replace_veloctiy:
		velocity.y = -force
	else:
		velocity.y = Utilities.soft_clamp(velocity.y, -force, force)
	_variable_jump_timer.start()
	_jump_particles.restart()
	_sfx["jump"].play()

# use instead of _sprite.play() to avoid replaying the same animation from the start when it's already playing
func _play_animation(anim_name : String, ignore_if_playing : bool = false):
	if ignore_if_playing && anim_name == _sprite.animation:
		return
	_sprite.play(anim_name)

func _get_ray_colliding_with_tilemap() -> Vector2:
	if _detect_left.is_colliding() and _detect_left.get_collider() is TileMap:
		return Vector2.LEFT
	elif _detect_right.is_colliding() and _detect_right.get_collider() is TileMap:
		return Vector2.RIGHT
	return Vector2.ZERO

func _set_can_dash(dash : bool):
	# Note: use this instead of setting _can_dash directly
	# so it also updates the interface
	_can_dash = dash
	if _dash_locks == 0:
		World.level.interface.set_dash(dash)

func _state_normal_switch_from(to : String):
	_look_offset_timer.stop()
	_is_look_offset_applied = false
	World.level.level_camera.player_look_offset(0)
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	_footstep_timer.stop()
	_walk_dust_particles.emitting = false

func _state_normal_process(delta : float):
	# animation
	if is_on_floor():
		if velocity.x == 0:
			if _direction.y == 0:
				_play_animation("Idle")
			else:
				_play_animation("Looking Up" if _direction.y == -1 else "Looking Down")
		elif abs(velocity.x) > _run_anim_threshold:
			var x_input_dir : float = Input.get_axis("left", "right")
			if sign(x_input_dir) == sign(velocity.x):
				_play_animation("Run")
			else:
				_play_animation("Skidding")
		else:
			_play_animation("Walk")
		
	else:
		if velocity.y >= 0:
			# falling
			var fall_anim_idx : int
			for i in range(_fall_anim_intensity_thresholds.size()-1, -1, -1):
				if velocity.y >= _fall_anim_intensity_thresholds[i]:
					fall_anim_idx = i
					break 
			_play_animation("Fall " + str(fall_anim_idx + 1), true)
		elif velocity.y < 0:
			# jumping
			var jump_anim_idx : int
			for i in _jump_anim_intensity_thresholds.size():
				if -velocity.y >= _jump_anim_intensity_thresholds[i]:
					jump_anim_idx = i
					break
			_play_animation("Jump " + str(jump_anim_idx + 1), true)

func _state_normal_ph_process(delta : float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y = Utilities.soft_clamp(velocity.y, _gravity * delta, _max_fall_speed)
	
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = Utilities.soft_clamp(velocity.x, _accel * delta * sign(_direction.x), _max_move_speed)
	else:
		# TODO: decel exploit. we only apply horizontal decel if no vertical input is held which leads
		#       to decel working differently when releasing movement key vs holding key of other direction
		#       this leads to weird precision and an exploit with wall jumping while moving towards the wall.
		#       the solution is to apply deceleration at all times like in real life. it will also requires
		#       increasing speed values to acount for the constant deceleration
		velocity.x = Utilities.soft_clamp(velocity.x, _decel * delta * -sign(velocity.x), 0.0)
	
	_walk_dust_particles.emitting = is_on_floor() and velocity.x > 230 or is_on_floor() and velocity.x < -230
	
	# footsteps
	if is_on_floor() and _footstep_timer.is_stopped() and velocity.x:
		if _direction.x:
			_sfx["footstep"].play()
			if abs(velocity.x) > _run_anim_threshold:
				_footstep_timer.wait_time = _run_footstep_time
			else:
				_footstep_timer.wait_time = _walk_footstep_time
			
		else:
			# TODO: slide sfx for as long as we're slidding
			#_footstep_timer.wait_time = ?
			#_sfx["slide"].play()
			pass
		
		_footstep_timer.start()
	
	# camera look offset
	if velocity.x == 0 && is_on_floor() && _direction.y:
		if _is_look_offset_applied == false:
			_is_look_offset_applied = true
			_look_offset_timer.start()
		elif _look_offset_timer.is_stopped() && _is_look_offset_applied:
			World.level.level_camera.player_look_offset(int(_direction.y))
	else:
		_is_look_offset_applied = false
		_look_offset_timer.stop()
		World.level.level_camera.player_look_offset(0)
	
	# jump
	var just_jumped : bool = false
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or _coyote_timer.is_stopped() == false:
			just_jumped = true
			_jump(_jump_force)
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	var was_on_floor : bool = is_on_floor()
	move_and_slide()
	
	# jump helpers
	if was_on_floor == false and is_on_floor():
		# just landed
		if _jump_buffer_timer.is_stopped() == false:
			_jump_buffer_timer.stop()
			just_jumped = true
			_jump(_jump_force)
	elif was_on_floor and is_on_floor() == false and just_jumped == false && velocity.y >= 0.0:
		# just fell off
		_coyote_timer.start() 
	
	# variable jump cutoff
	if Input.is_action_just_released("jump") && _variable_jump_timer.is_stopped() == false:
		_variable_jump_timer.stop()
		if velocity.y < 0.0:
			# multiply y velocity by a limiting factor to cutoff the jump force
			velocity.y *= _variable_jump_cutoff
	
	# wall slide
	if (is_on_floor() == false and Input.is_action_pressed("wall_grab") and
	_wall_grab_cooldown.is_stopped()):
		var ray_dir : Vector2 = _get_ray_colliding_with_tilemap()
		if ray_dir != Vector2.ZERO:
			_facing = ray_dir
			
			_sfx["hit_wall"].play()
			_state_machine.change_state("wall_slide")
			return
	
	# dashing
	if (_can_dash == false && _dash_locks == 0 &&
	_dash_cooldown.is_stopped() && is_on_floor()):
		_set_can_dash(true)
	
	if Input.is_action_just_pressed("dash") && _can_dash && _dash_locks == 0:
		_state_machine.change_state("dash")
		return

func _state_wall_slide_switch_to(from : String):
	velocity = Vector2(0,0)
	_cling_timer.start()
	_play_animation("Cling")

func _state_wall_slide_switch_from(to : String):
	_slide_dust_particles.emitting = false
	_cancel_slide_delay.stop()
	_wall_grab_cooldown.start()

func _state_wall_slide_ph_process(delta: float):
	if _cling_timer.is_stopped():
		_slide_dust_particles.emitting = true
		_play_animation("Sliding")
		if Input.is_action_pressed("down"):
			velocity.y = _slide_speed_fast
		else:
			velocity.y = _slide_speed
	
	# cancel sliding
	if Input.is_action_just_released("wall_grab"):
		_cancel_slide_delay.start()
	elif Input.is_action_pressed("wall_grab") == false and _cancel_slide_delay.is_stopped():
		_state_machine.change_state("normal")
		return
	
	if Input.is_action_just_pressed("dash") && _can_dash && _dash_locks == 0:
		_facing = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
		_state_machine.change_state("dash")
		return
	
	# jump off
	if Input.is_action_just_pressed("jump"):
		_jump(_jump_force, true)
		_facing *= -1
		velocity.x = _wall_push_force * _facing.x
		_play_animation("Wall Jump", true)
		_state_machine.change_state("normal")
		return
	
	# wall out of reach
	var ray_dir : Vector2 = _get_ray_colliding_with_tilemap()
	if is_on_floor() or (_facing != ray_dir):
		_state_machine.change_state("normal")
		return
	
	move_and_slide()

func _state_dash_switch_to(from : String):
	World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _dash_shake_duration)
	_set_can_dash(false)
	#BUG: IF DASH IS PRESSED AFTER PRESSING DOWN INPUT AND NO OTHER INPUT IS USED
	# THE PLAYER WILL DASH INTO THE GROUND
	velocity = _dash_speed * _facing.normalized()
	_dash_trail.set_active(true, _sprite.flip_h)
	_sfx["dash"].play()
	_dash_timer.start()
	_play_animation("Dashing")

func _state_dash_switch_from(to: String):
	_dash_cooldown.start()
	_dash_timer.stop()
	_dash_trail.set_active(false)

func _state_dash_ph_process(delta: float):
	move_and_slide()
	
	if _dash_timer.is_stopped() or is_on_wall():
		_state_machine.change_state("normal")
		return
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		_jump(_jump_force)
		_state_machine.change_state("normal")
		return

func _state_swim_switch_to(from : String):
	_splash_sprite.splash(global_position + _splash_sprite_spawn_offset)
	
	# limit enter speed so if player is going super fast a damp effect is applied like real life
	velocity = velocity.clamp(Vector2.ONE * -_water_enter_max_speed, Vector2.ONE * _water_enter_max_speed)
	_sfx["splash"].play()
	_collider.shape.size = _water_collider_size
	_was_on_water_surface = true
	_set_can_dash(false)
	
	_sfx["water_ambience"].play()
	AudioServer.add_bus_effect(_master_bus_idx, _water_muffle_effect)

func _state_swim_switch_from(to : String):
	if to != "dummy":
		# if player leaves water with a slow speed they'll fall right back leading to state continuously
		# changing. this kicks the player up when they leave
		velocity.y = Utilities.soft_clamp(velocity.y, -_out_of_water_push, _out_of_water_push)
		_collider.shape.size = _default_collider_size
		World.level.interface.set_air_active(false)
		World.level.interface.set_air(_air, _max_air)
		_set_can_dash(true)
		_jump_buffer_timer.stop()
		_bubbles_particles.emitting = false
		_air = _max_air
		_water_timer.stop()
		_sfx["water_ambience"].stop()
	
	AudioServer.remove_bus_effect(0, 0)

func _state_swim_ph_process(delta : float):
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = Utilities.soft_clamp(velocity.x, _water_accel * sign(_direction.x) * delta, _max_swim_speed)
	else:
		velocity.x = Utilities.soft_clamp(velocity.x, _water_decel * delta * -sign(velocity.x), 0.0)
	
	if _direction.y:
		velocity.y = Utilities.soft_clamp(velocity.y, _max_swim_speed * sign(_direction.y) * delta, _max_swim_speed)
	else:
		velocity.y = Utilities.soft_clamp(velocity.y, _water_decel * delta * -sign(velocity.y), 0.0)
	
	if velocity != Vector2.ZERO:
		_play_animation("Water Swim")
	else:
		_play_animation("Water Idle")
	
	# surface
	var is_on_surface : bool =\
		World.level.is_breathable_tile(global_position - Vector2(0.0, World.level.tile_size))
	var is_3_tiles_from_surface : bool =\
		World.level.is_breathable_tile(global_position - Vector2(0.0, World.level.tile_size * 3))
	
	_bubbles_particles.emitting = (is_on_surface == false and is_3_tiles_from_surface == false)
	
	if Input.is_action_just_pressed("jump"):
		if is_3_tiles_from_surface:
			_jump(_jump_force)
		else:
			_jump_buffer_timer.start()
	else:
		if is_3_tiles_from_surface && _jump_buffer_timer.is_stopped() == false:
			# apply jump buffer
			_jump_buffer_timer.stop()
			_jump(_jump_force)
	
	move_and_slide()
	
	if is_on_surface:
		if _was_on_water_surface == false:
			# just reached surface
			World.level.interface.set_air(_air, _max_air)
			_air = _max_air
			World.level.interface.set_air_active(false)
			_water_timer.stop()
	else:
		if _was_on_water_surface:
			# just sank below surface
			World.level.interface.set_air_active(true)
			_water_timer.start()
		
		if _water_timer.is_stopped():
			_water_timer.start()
			if _air > 0:
				World.level.interface.set_air(_air, _air-1)
				_air -= 1
			else:
				# damage time :)
				take_damage(1, Vector2.UP)
	
	_was_on_water_surface = is_on_surface
	
	# check out of water
	if World.level.is_water_tile(global_position) == false:
		_state_machine.change_state("normal")

func _state_dummy_switch_to(from : String):
	# NOTE: for now dummy state is used to stop player from receiving input, basically a state that intentionally does nothing
	#       in the future we can use this to play some animation like an animation for collecting links
	#       or a teleport animation without the player interupting.
	velocity = Vector2.ZERO
	match from:
		# TODO: acount for player being in mid-air
		#       also this needs to be tested with all states
		"normal":
			_play_animation("Idle")
		"swim":
			_play_animation("Water Idle")
		"wall_slide":
			_play_animation("Sliding")

func _state_dead_switch_to(from : String):
	velocity = Vector2.ZERO
	_facing.x = 1 # ensure sprite is not flipped or the death animation text will be backward
	_collider.disabled = true
	_sprite.flip_h = false
	
	_play_animation("Die")
	# TODO: give camera a "dying" state to zoom in player and follow in a more custom way (World.level.level_camera.set_state_dying())
	#       this would require making cam trigger ignore that state which means changing the state() variable in the trigger
	#       for the level camera state enum to an array of strings which will break every camera trigger in the game
	await _sprite.animation_finished
	died.emit()

func _state_dead_switch_from(to : String):
	_collider.disabled = false
