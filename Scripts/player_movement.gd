extends CharacterBody2D

# Set Variables for overall control feel
var move_speed : float = 100
var jump_force : float = 200
var gravity : float = 500

# Establish the score variable and display on ui requires CanvasLayer/ScoreText nodes to be setup.
var score : int = 0
@onready var score_text : Label = get_node("CanvasLayer/ScoreText")

func _physics_process(delta):
	# Enable gravity and movement. I will be updating this to have mappable controls!
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0

	# Movement Control
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, 20)


	# Allow player to jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_force
	
	# Engage physics engine
	move_and_slide()
	
	# Fall too far and die
	if global_position.y > 150:
		game_over()
		
func game_over ():
	# Currently set to restart level, can be changed easily here.
	get_tree().reload_current_scene()
	
func add_score (amount):
	# Enables scorekeeping and calls it "Arts:" can be changed easily.
	score += amount
	score_text.text = str("Arts: ", score)
