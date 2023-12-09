extends CharacterBody2D

#Set Variables for overall control feel
var move_speed : float = 100
var jump_force : float = 200
var gravity : float = 500

#Establish the score variable and display on ui requires CanvasLayer/ScoreText nodes to be setup.
var score : int = 0
@onready var score_text : Label = get_node("CanvasLayer/ScoreText")


func _physics_process(delta):
	#Enable gravity and movement. I will be updating this to have mappable controls!
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = 0
	if Input.is_key_pressed(KEY_A):
		velocity.x -= move_speed
	if Input.is_key_pressed(KEY_D):
		velocity.x += move_speed
		
	#Allow player to jump
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = -jump_force
	
	#Engage physics engine
	move_and_slide()
	
	#Fall too far and die
	if global_position.y > 150:
		game_over()
		
func game_over ():
	#Currently set to restart level, can be changed easily here.
	get_tree().reload_current_scene()
	
func add_score (amount):
	#Enables scorekeeping and calls it "Arts:" can be changed easily.
	score += amount
	score_text.text = str("Arts: ", score)
