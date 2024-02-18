extends Node2D

@onready var camera_2d = $Camera2D
@onready var label_6 = $Label6
@onready var player = $Player
@onready var main_theme = $MainTheme
var high_score
var _pause

func _ready():
	for node in get_tree().get_nodes_in_group("Enemy"):
		node._give_score.connect(_give_score)
	
func _give_score(amount):
	player._get_score(amount)

func _process(delta):
	high_score = PlayerManager.high_score
	label_6.text = str("High Score: ", high_score,"0")
	
func _input(event):
	if Input.is_action_just_pressed("Toggle Camera (temporary)"):
		camera_2d.make_current()


func _on_button_toggled(toggled_on):
	if toggled_on == false:
		main_theme.play(_pause)
	if toggled_on == true:
		_pause = main_theme.get_playback_position()
		main_theme.stop()
