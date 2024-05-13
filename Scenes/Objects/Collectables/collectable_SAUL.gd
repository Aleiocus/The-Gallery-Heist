extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _sprite = $Sprite
@onready var _collected_sfx = $PersistentNodesContainer/Collected
@onready var _persistent_node = $PersistentNodesContainer

@export var _letter : Level.SaulLetter

const _collected_anim_scale : float = 9.0
const _collected_tween_time : float = 0.8
const _collected_shake_time : float = 0.2

func _ready():
	_sprite.play(Level.SaulLetter.keys()[_letter])

func _collected(player : Player):
	process_mode = Node.PROCESS_MODE_ALWAYS
	_collected_sfx.play()
	_sprite.speed_scale = _collected_anim_scale
	World.level.pause_manager.set_gameplay_pause(true)
	World.level.level_camera.shake(LevelCamera.ShakeLevel.medium, _collected_shake_time)
	
	var camera : Camera2D = get_viewport().get_camera_2d()
	var camera_local_start : Vector2 = camera.global_position - get_viewport_rect().size / camera.zoom / 2.0
	var tween : Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", camera_local_start + World.level.interface.get_letters_ui_position(), _collected_tween_time)
	
	await tween.finished
	World.level.level_camera.shake(LevelCamera.ShakeLevel.medium, _collected_shake_time)
	World.level.pause_manager.set_gameplay_pause(false)
	World.level.found_letter(_letter)
	_persistent_node.detach()
	super._collected(player)
