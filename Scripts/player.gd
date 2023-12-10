class_name Player
extends CharacterBody2D

# Set Variables for overall control feel
const _move_speed : float = 100.0
const _jump_force : float = 200.0
const _gravity : float = 500.0
const _death_height_y : float = 150.0

# Establish the score variable and display on ui requires CanvasLayer/ScoreText nodes to be setup.
var _score : int = 0
@onready var _score_text : Label = get_node("CanvasLayer/ScoreText")

func _physics_process(delta : float):
	# Enable gravity and movement. I will be updating this to have mappable controls!
	if not is_on_floor():
		velocity.y += _gravity * delta
	velocity.x = 0

	# Movement Control
	var direction : float = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * _move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, 20)
		 
	# Allow player to jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -_jump_force
	
	# Engage physics engine
	move_and_slide()
	
	# Fall too far and die
	if global_position.y > _death_height_y:
		game_over()
		
func game_over ():
	# Currently set to restart level, can be changed easily here.
	get_tree().reload_current_scene()
	
func add_score (amount : float):
	# Enables scorekeeping and calls it "Arts:" can be changed easily.
	_score += amount
	_score_text.text = str("Arts: ", _score)
