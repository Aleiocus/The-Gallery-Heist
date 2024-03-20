@tool
extends Area2D

@export var _texture : Texture2D :
	set(value):
		_texture = value
		
		if is_node_ready() == false:
			# make sure node is ready so @onready vars are set
			await ready
		
		# update sprite and collider
		_sprite.texture = _texture
		if value != null:
			_collider.shape.size = _texture.get_size()

@onready var _sprite : Sprite2D = $Sprite2D
@onready var _collider : CollisionShape2D = $CollisionShape2D
