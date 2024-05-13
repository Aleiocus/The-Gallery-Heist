@tool
class_name LockedDoor
extends StaticBody2D

## the keys required to open this door. drag and drop from the Scene tab
@export var _required_keys : Array[LockedDoorKey] :
	set(value):
		if _required_keys.is_empty():
			# NOTE: in godot export arrays are shared between all isntances
			#       this has been officially my most hated and stupid feature for a while now
			#       a workaround is to cut the connection between instances arrays
			#       by setting them to a new array, it's like "make unique" but for arrays
			_required_keys = [] as Array[LockedDoorKey]
		
		# ensure new array has no duplicates
		var value_no_duplicates : Array[LockedDoorKey] = []
		for v in value:
			if v == null || value_no_duplicates.has(v) == false:
				value_no_duplicates.append(v)
		
		# remove ownership from previous keys
		# backward iteration to avoid deleting keys while iteraing on them (set_owner_door(null) causes deletion)
		for i in range(_required_keys.size()-1, -1, -1):
			var key : LockedDoorKey = _required_keys[i]
			if key != null:
				key.set_owner_door(null)
		
		_required_keys = value_no_duplicates
		for key in _required_keys:
			if key != null:
				key.set_owner_door(self)
## the size of the door in tiles
@export var _size : Vector2i :
	set(value):
		_size.x = max(3, value.x)
		_size.y = max(3, value.y)
		_build_door()
## how far the door detects the keys that the player is holding
@export var _detection_radius : float :
	set(value):
		_detection_radius = max(0.0, value)
		_build_door()

@onready var _sprites_container : Node2D = $Sprites
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _lock_sprite : AnimatedSprite2D = $Lock
@onready var _detection_collider : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var _status_label : Label = $Status


func _ready():
	if Engine.is_editor_hint(): return
	
	# remove null entried when the game starts
	for i in range(_required_keys.size()-1, -1, -1):
		if _required_keys[i] == null: _required_keys.remove_at(i)
	
	_update_door()

func remove_key(key : LockedDoorKey):
	_required_keys.erase(key)

func get_center() -> Vector2:
	return global_position + Vector2(_size) * World.level.tile_size / 2.0

func _on_detection_area_entered(area : Area2D):
	if (area is LockedDoorKey && area in _required_keys &&
	area.get_state() == LockedDoorKey.State.follow):
		# insert key
		remove_key(area)
		area.insert_animation_finished.connect(_on_key_insert_animation_finished)
		area.insert_in_door()

func _on_key_insert_animation_finished():
	_update_door()

func _build_door():
	if is_node_ready() == false:
		await ready
	
	for sprite in _sprites_container.get_children():
		sprite.queue_free()
	
	var half_tile : Vector2 = Vector2.ONE * World.level.tile_size / 2.0
	for w in _size.x:
		for h in _size.y:
			var sprite : Sprite2D = Sprite2D.new()
			sprite.texture = AtlasTexture.new()
			sprite.texture.atlas = preload("res://Resources/Textures/locked_door.png")
			sprite.texture.region.size = Vector2.ONE * World.level.tile_size
			sprite.position = Vector2(w, h) * World.level.tile_size + half_tile
			_sprites_container.add_child(sprite)
			
			# sprite position in texture
			if w > 0 && w < _size.x-1 && h > 0 && h < _size.y-1: # center
				sprite.texture.region.position = Vector2(World.level.tile_size, World.level.tile_size)
			elif w == 0 && h == 0: # top left
				sprite.texture.region.position = Vector2(0.0, 0.0)
			elif w == _size.x-1 && h == 0: # top right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, 0.0)
			elif w > 0 && w < _size.x-1 && h == 0: # top center
				sprite.texture.region.position = Vector2(World.level.tile_size, 0.0)
			elif w == 0 && h > 0 && h < _size.y-1: # center left
				sprite.texture.region.position = Vector2(0.0, World.level.tile_size)
			elif w == _size.x-1 && h > 0 && h < _size.y-1: # center right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, World.level.tile_size)
			elif w == 0 && h == _size.y-1: # bottom left
				sprite.texture.region.position = Vector2(0.0, World.level.tile_size * 2)
			elif w == _size.x-1 && h == _size.y-1: # bottom right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, World.level.tile_size * 2)
			elif w > 0 && w < _size.x-1 && h == _size.y-1: # bottom center
				sprite.texture.region.position = Vector2(World.level.tile_size, World.level.tile_size * 2)
	
	# lock sprite
	_lock_sprite.position = _size * World.level.tile_size / 2.0
	_lock_sprite.scale = Vector2.ONE * min(_size.x / 2.0, _size.y / 2.0)
	
	var door_size : Vector2 = _size * World.level.tile_size
	_detection_collider.shape.radius = _detection_radius
	_detection_collider.position = door_size / 2.0
	
	_collider.shape.size = door_size
	_collider.position = door_size / 2.0
	
	_status_label.position = Vector2(
		door_size.x / 2.0 - _status_label.size.x / 2.0,
		-_status_label.size.y
	)

func _update_door():
	_status_label.text = str(_required_keys.size())
	_status_label.position = Vector2(
		(_size.x * World.level.tile_size) / 2.0 - _status_label.size.x / 2.0,
		-_status_label.size.y
	)
	
	if _required_keys.size() == 0:
		# all keys inserted!
		_lock_sprite.play("unlock")
		await _lock_sprite.animation_finished
		queue_free()
