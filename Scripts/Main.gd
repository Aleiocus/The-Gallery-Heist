extends Node2D

@onready var camera_2d : Camera2D = $Camera2D
@onready var label : Label = $Label
@onready var player : Player = $Player
@onready var main_theme : AudioStreamPlayer2D = $MainTheme
var high_score

func _ready():
	for node in get_tree().get_nodes_in_group("Enemy"):
		node._give_score.connect(_give_score)
	
func _give_score(amount):
	player._get_score(amount)

func _process(delta : float):
	high_score = World.high_score
	label.text = str("High Score: ", high_score, "0")

func _input(event : InputEvent):
	if Input.is_action_just_pressed("Toggle Camera (temporary)"):
		camera_2d.make_current()

func _on_button_toggled(toggled_on : bool):
	main_theme.stream_paused = toggled_on
