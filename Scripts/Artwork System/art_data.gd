@tool
extends Resource
class_name ArtData

@export var title: String = "" :
	set(value):
		title = value
		emit_changed()

@export var artist: String = "" :
	set(value):
		artist = value
		emit_changed()

@export var texture: AtlasTexture :
	set(value):
		texture = value
		emit_changed()

@export var size: Vector2 :
	set(value):
		size = value
		emit_changed()
