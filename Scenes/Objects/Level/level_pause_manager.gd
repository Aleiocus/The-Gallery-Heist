extends MarginContainer

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed

# gameplay pausing is called by scripts like SAUL letters or player damage for gameplay related pausing
# while _menu_pause is for pressing ESC to show pause menu
var _gameplay_pause_locks : int
var _menu_pause : bool = false

func _input(event : InputEvent):
	if event.is_action_pressed("pause"):
		_toggle_menu_pause()

func _exit_tree():
	# in case of quiting while paused
	get_tree().paused = false

func set_gameplay_pause(pause : bool):
	if pause: _gameplay_pause_locks += 1
	else: _gameplay_pause_locks -= 1
	
	assert(_gameplay_pause_locks >= 0, "Bug detected, a lock is being removed without being added first.")
	get_tree().paused = !(_menu_pause == false && _gameplay_pause_locks == 0)

func _toggle_menu_pause():
	_menu_pause = !_menu_pause
	self.visible = _menu_pause
	
	if _menu_pause == false && _gameplay_pause_locks == 0:
		get_tree().paused = false
	if _menu_pause && _gameplay_pause_locks == 0:
		get_tree().paused = true

func _on_resume_pressed():
	_pressed_sfx.play()
	_toggle_menu_pause()

func _on_restart_pressed():
	# TODO: restart from checkpoint rather than this to not risk breaking levels that depend
	#       on a setup() func or previous context
	_pressed_sfx.play()
	SceneManager.restart_scene()

func _on_quit_pressed():
	_pressed_sfx.play()
	# main menu
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _on_mouse_entered():
	_hovered_sfx.play()
