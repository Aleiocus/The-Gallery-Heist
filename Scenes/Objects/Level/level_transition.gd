extends TextureRect

signal screen_hidden

enum _TransitionDirection {left_to_right, right_to_left, up_to_down, down_to_up, scaled}

const _transitions : Array[Dictionary] = [
	{"texture":"res://Resources/Textures/SceneTrainsitions/ArrowHorizontal.png", "transition":_TransitionDirection.left_to_right},
	{"texture":"res://Resources/Textures/SceneTrainsitions/ArrowVertical.png", "transition":_TransitionDirection.down_to_up},
	{"texture":"res://Resources/Textures/SceneTrainsitions/Rectangle.png", "transition":_TransitionDirection.scaled},
]
const _transition_positions : Dictionary = {
	# based on edges of TransitionTemplate.png
	"center":Vector2(160,20), "left":Vector2(-800,20), "right":Vector2(1120,20), "up":Vector2(160,-800), "down":Vector2(160,840)
}
var _transition_tween : Tween
const _tween_time : float = 0.8
const _transition_tex_scale : Vector2 = Vector2.ONE * 4.0
const _transition_tex_size : Vector2 = Vector2(320, 320) # based on transition template size

func _ready():
	position = _transition_positions["center"]
	scale = _transition_tex_scale

func transition():
	# setup
	if _transition_tween && _transition_tween.is_valid():
		_transition_tween.kill()
	
	var random_trans : Dictionary = _transitions.pick_random()
	texture = load(random_trans["texture"])
	
	# cover screen
	_transition_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	match random_trans["transition"]:
		_TransitionDirection.left_to_right:
			_transition_tween.tween_property(self, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["left"])
		_TransitionDirection.right_to_left:
			_transition_tween.tween_property(self, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["right"])
		_TransitionDirection.up_to_down:
			_transition_tween.tween_property(self, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["up"])
		_TransitionDirection.down_to_up:
			_transition_tween.tween_property(self, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["down"])
		_TransitionDirection.scaled:
			_transition_tween.tween_property(self, "scale", _transition_tex_scale, _tween_time)\
				.from(Vector2.ZERO)
	await _transition_tween.finished
	
	screen_hidden.emit()
	
	# uncover screen
	_transition_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	match random_trans["transition"]:
		_TransitionDirection.left_to_right:
			_transition_tween.tween_property(self, "position", _transition_positions["right"], _tween_time)
		_TransitionDirection.right_to_left:
			_transition_tween.tween_property(self, "position", _transition_positions["left"], _tween_time)
		_TransitionDirection.up_to_down:
			_transition_tween.tween_property(self, "position", _transition_positions["down"], _tween_time)
		_TransitionDirection.down_to_up:
			_transition_tween.tween_property(self, "position", _transition_positions["up"], _tween_time)
		_TransitionDirection.scaled:
			_transition_tween.tween_property(self, "scale", Vector2.ZERO, _tween_time)
	await _transition_tween.finished
	
	# cleanup
	texture = null
	position = _transition_positions["center"]
	scale = _transition_tex_scale
