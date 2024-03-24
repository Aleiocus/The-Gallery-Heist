@tool
extends Area2D

@onready var sprite : Sprite2D = $Sprite
@onready var shape : CollisionShape2D = $Shape
@export var art_data : ArtData : 
	set(value):
		if art_data != null:
			art_data.changed.disconnect(_update_artwork)
		
		art_data = value
		if art_data != null:
			art_data.changed.connect(_update_artwork)
		_update_artwork()

func _update_artwork():
	if is_inside_tree() == false:
		await ready
	
	print("UPDATE")
	if art_data:
		sprite.texture = art_data.texture
		shape.shape.size = art_data.size
	else:
		sprite.texture = null
		shape.shape.size = Vector2.ZERO
		
