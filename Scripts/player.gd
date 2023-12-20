class_name Player
extends CharacterBody2D


# Set Variables for overall control feel
const _max_move_speed : float = 95.0
const _accel : float = 120.0
const _decel : float = 160.0
const _jump_force : float = 180.0
const _gravity : float = 500.0
const _death_height_y : float = 150.0
@onready var _coyote_timer : Timer = $CoyoteTimer
@onready var _jump_buffer_timer : Timer = $JumpBufferTimer

var _state_machine : StateMachine = StateMachine.new()

# Establish the score variable and display on ui requires CanvasLayer/ScoreText nodes to be setup.
var _score : int = 0
@onready var _score_text : Label = get_node("CanvasLayer/ScoreText")


func _ready():
	_state_machine.add_state("normal", Callable(), Callable(), Callable(), _state_normal_ph_precess)
	_state_machine.add_state("dash", Callable(), Callable(), Callable(), Callable())
	_state_machine.add_state("wall_slide", Callable(), Callable(), Callable(), Callable())
	_state_machine.change_state("normal")

func _process(delta : float):
	_state_machine.state_process(delta)

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func _state_normal_ph_precess(delta : float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	var was_on_floor = is_on_floor()
	
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
		game_over()

func game_over():
	# Currently set to restart level, can be changed easily here.
	SceneManager.restart_scene()
	
func add_score(amount : float):
	# Enables scorekeeping and calls it "Arts:" can be changed easily.
	_score += amount
	_score_text.text = str("Arts: ", _score)
