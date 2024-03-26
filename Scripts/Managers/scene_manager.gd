extends CanvasLayer

signal scene_changed

@onready var _transition_rect : TextureRect = $ScreenTransition

const _tween_time : float = 1.2
var _is_transitioning : bool


func change_scene(scene_path : String):
	if _is_transitioning: return
	_is_transitioning = true
	
	# block mouse
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# get screen frame
	await get_tree().process_frame
	var viewport_img : Image = get_viewport().get_texture().get_image()
	var texture : ImageTexture = ImageTexture.create_from_image(viewport_img)
	_transition_rect.texture = texture
	
	# change scene
	get_tree().change_scene_to_file(scene_path)
	get_tree().process_frame.connect(
		# there is no emit_deferred, so we do it manually
		func(): scene_changed.emit(),
		CONNECT_ONE_SHOT
	)
	
	# transition out
	var transition_tween : Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	transition_tween.tween_property(
		_transition_rect.material, "shader_parameter/factor", -1.0, _tween_time
	)
	await transition_tween.finished
	
	# cleanup
	_transition_rect.texture = null
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.material.set_shader_parameter("factor", 1.0)
	_is_transitioning = false

func restart_scene():
	change_scene(get_tree().current_scene.scene_file_path)
