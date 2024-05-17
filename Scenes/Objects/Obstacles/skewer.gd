@tool
extends Area2D

## the height of the skewer in tiles
@export var _height : int :
	set(value):
		_height = max(value, 1)
		_build_skewer()
## the time it takes to fully stab
@export var _stab_time : float = 0.5 :
	set(value):
		_stab_time = max(value, 0.0)
## the time it takes to fully retract
@export var _retract_time : float = 1.0 :
	set(value):
		_retract_time = max(value, 0.0)
## additional width to how far the skewer can detect the player from
@export var _detection_width : float :
	set(value):
		_detection_width = max(value, 0.0)
		_build_skewer()
## don't change this!
@export var _sprite_frames : SpriteFrames

@onready var _sprites_container : Node2D = $Sprites
@onready var _hurtbox : Area2D = $HurtBox
@onready var _hurtbox_collider : CollisionShape2D = $HurtBox/CollisionShape2D
@onready var _collider : CollisionShape2D = $CollisionShape2D

var _stab_tween : Tween

func _ready():
	if Engine.is_editor_hint(): return
	
	_hurtbox.monitoring = false
	_hurtbox.custom_knockback_direction = Vector2.UP.rotated(rotation)
	
	# wait for calls to _build_skewer to finish before hidding preview
	await get_tree().process_frame
	_animation_stab(false, true)

func _build_skewer():
	if is_node_ready() == false:
		await ready
	
	for sprite : AnimatedSprite2D in _sprites_container.get_children():
		sprite.queue_free()
	
	for i in _height:
		var sprite : AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.position.y = -i * World.level.tile_size - World.level.tile_size / 2.0
		sprite.sprite_frames = _sprite_frames
		# use animations as preview
		_sprites_container.add_child(sprite)
	_animation_stab(true, true)
	
	_hurtbox_collider.shape.size = Vector2(
		World.level.tile_size,
		World.level.tile_size * _height
	)
	_hurtbox_collider.position = Vector2(
		0.0, -_hurtbox_collider.shape.size.y / 2.0
	)
	
	_collider.shape.size =\
		_hurtbox_collider.shape.size + Vector2(_detection_width, 0.0)
	_collider.position = _hurtbox_collider.position

func _animation_stab(extend_ : bool, is_instant : bool):
	if _stab_tween && _stab_tween.is_valid():
		_stab_tween.kill()
	
	if is_instant == false:
		# TODO: use tween to animate properly
		#_stab_tween = create_tween()
		pass
	
	for i in _sprites_container.get_child_count():
		var sprite : AnimatedSprite2D = _sprites_container.get_child(i)
		if extend_:
			var anim : String = "extend" if i != _sprites_container.get_child_count()-1 else "stab"
			sprite.play(anim)
		else:
			sprite.play("retract")

func _on_body_entered(body : Node2D):
	if body is Player:
		_hurtbox.set_deferred("monitoring", true)
		_animation_stab(true, false)

func _on_body_exited(body : Node2D):
	if body is Player:
		_hurtbox.set_deferred("monitoring", false)
		_animation_stab(false, false)
