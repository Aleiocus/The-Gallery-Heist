extends Area2D


@onready var sprite = $Sprite
@onready var shape = $Shape
@export var art_data : ArtData

func _ready():
	sprite.texture = art_data.texture
	shape.shape.size = art_data.size
# BUG IF 2 ARTWORKS ARE LOADING, THE LAST ARTDATA IS USED TO MAKE THE SIZE IDK WHY
