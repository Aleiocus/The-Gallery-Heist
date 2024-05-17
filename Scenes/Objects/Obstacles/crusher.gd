@tool
extends AnimatableBody2D

## how many tiles wide the crusher should be
@export var _width : int :
	set(value):
		_width = max(value, 2)
		_build_crusher()
## the max point that the crusher will reach before retracting back
@export var _max_extent : float :
	set(value):
		_max_extent = max(value, 0.0)
		_build_crusher()
## speed of the crush
@export var _crush_time : float = 1.0 :
	set(value):
		_crush_time = max(value, 0.1)
## speed of the retraction after cushing
@export var _retract_time : float = 1.0 :
	set(value):
		_retract_time = max(value, 0.1)
## cooldown time after a crush (x) and retraction (y) where the crusher will not move
@export var _cooldown_time : Vector2 = Vector2.ONE :
	set(value):
		_cooldown_time.x = max(value.x, 0.0)
		_cooldown_time.y = max(value.y, 0.0)
## the start factor between the crushers position and max extent, setting this to 1 will start the crusher at the max extent
@export_range(0, 1) var _starting_offset_factor : float :
	set(value):
		_starting_offset_factor = value
		_build_crusher()

@onready var _chain_sprites : Node2D = $ChainSprites
@onready var _base_sprites : Node2D = $BaseSprites
@onready var _crusher_sprites : Node2D = $CrusherSprites
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _damage_area : Area2D = $DamageArea
@onready var _damage_area_collider : CollisionShape2D = $DamageArea/CollisionShape2D
@onready var _cooldown_timer : Timer = $CooldownTimer

var _textures : Dictionary # {name:AtlasTexture}
const _hurtbox_height : float = World.level.tile_size / 4.0
const _half_tile : Vector2 = Vector2.ONE * World.level.tile_size / 2.0

@onready var _starting_pos : Vector2 = global_position
var _end_pos : Vector2
var _animation_offset_sign : int = 1
var _knockback_direction : Vector2

const _debug_height_color : Color = Color("ffffff64")
const _debug_offset_color : Color = Color.WHITE


func _ready():
	# setup textures. all crusher textures in one place to take advantage of reference counting
	# so we only need to animate one base_center texture for example and all sprites using base_center texture will animate
	var setup_texture : Callable = func(region_position : Vector2) -> AtlasTexture:
		var texture : AtlasTexture = AtlasTexture.new()
		texture.atlas = preload("res://Resources/Textures/crusher.png")
		texture.region.position = region_position
		texture.region.size = Vector2.ONE * World.level.tile_size
		return texture
	
	_textures["base_left"] = setup_texture.call(Vector2(0, World.level.tile_size))
	_textures["base_center"] = setup_texture.call(Vector2(World.level.tile_size, World.level.tile_size))
	_textures["base_right"] = setup_texture.call(Vector2(World.level.tile_size * 2, World.level.tile_size))
	_textures["chain"] = setup_texture.call(Vector2(0, World.level.tile_size * 2))
	_textures["spike"] = setup_texture.call(Vector2(0, World.level.tile_size * 4))
	_textures["crusher_left"] = setup_texture.call(Vector2(0, World.level.tile_size * 3))
	_textures["crusher_center"] = setup_texture.call(Vector2(World.level.tile_size, World.level.tile_size * 3))
	_textures["crusher_right"] = setup_texture.call(Vector2(World.level.tile_size * 2, World.level.tile_size * 3))
	
	if Engine.is_editor_hint(): return
	
	_knockback_direction = Vector2.DOWN.rotated(rotation)
	
	# starting pos
	_end_pos = _starting_pos + Vector2.DOWN.rotated(rotation) * _max_extent
	global_position = lerp(_starting_pos, _end_pos, _starting_offset_factor)
	
	# TODO: crusher goes out of sync at the very start. putting 2 crushers next
	#       to each other with the same variables and with one having a starting offset or 0 and the other 1
	#       shows the out of sync, it only happens at the very start for some reason and only
	#       when a scene containing the crusher is the starting scene. waiting for a bit
	#       before starting the crusher seems to fix it but it's hacky and stupid
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var is_initial_crush : bool = true
	var initial_crush_time : float = remap(
		global_position.length_squared(), _starting_pos.length_squared(), _end_pos.length_squared(), _crush_time, 0.0
	)
	
	while true:
		# crush
		_damage_area_collider.disabled = false
		var crush_time : float = initial_crush_time if is_initial_crush else _crush_time
		is_initial_crush = false
		var tween : Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_method(_tween_movement, global_position, _end_pos, crush_time)
		await tween.finished
		# wait 2 physics frames before disabling to allow collider time to update bodies in range
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		_damage_area_collider.disabled = true
		
		# cooldown
		if _cooldown_time.x:
			_cooldown_timer.wait_time = _cooldown_time.x
			_cooldown_timer.start()
			await _cooldown_timer.timeout
		
		# retract
		tween = create_tween()
		tween.tween_method(_tween_movement, global_position, _starting_pos, _retract_time)
		await tween.finished
		
		# coodown
		if _cooldown_time.y:
			_cooldown_timer.wait_time = _cooldown_time.y
			_cooldown_timer.start()
			await _cooldown_timer.timeout

func _tween_movement(target_pos : Vector2):
	# position
	global_position = target_pos
	
	# don't move chain and base sprites containers
	_chain_sprites.global_position = _starting_pos
	_base_sprites.global_position = _starting_pos
	
	# move chain sprites individually
	# we instantiated all potential sprites at start so we don't remove and add sprites at runtime
	for i in range(0, _chain_sprites.get_child_count(), 2):
		for j in 2:
			var chain_sprite : Sprite2D = _chain_sprites.get_child(i+j)
			chain_sprite.position = Vector2(
				0 if j == 0 else (_width-1) * World.level.tile_size,
				min((i / 2.0) * World.level.tile_size, (global_position - _starting_pos).length())
			)
	
	var starting_pos_diff : Vector2 = global_position - _starting_pos
	# expand collider to prevent passing through chains
	_collider.shape.size.y = World.level.tile_size + starting_pos_diff.length()
	_collider.position = -starting_pos_diff.rotated(-rotation) - _half_tile + _collider.shape.size / 2.0

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	# only deal damage when squeezing character against a solid object
	# TODO: current attempt at crushing detection, it appears that get_slide_collission() doesn't
	#       count collisions after the solver moves the body out of geometry so we can't detect
	#       both crusher and tilemap at the same time. delaying this to another time to save my sanity
	#       for now the crusher kills on contact
	#for node in _damage_area.get_overlapping_bodies():
		#if node is Character:
			#if node.get_slide_collision_count() >= 2:
				#var collision_normals : Dictionary = {} # {body:combined_col_normal, ..}
				#for i in node.get_slide_collision_count():
					#var col : KinematicCollision2D = node.get_slide_collision(i)
					#if collision_normals.has(col.get_collider()) == false:
						#collision_normals[col.get_collider()] = Vector2.ZERO
					#collision_normals[col.get_collider()] += col.get_normal()
				#
				#for collider in collision_normals.keys():
					#collision_normals[collider] = collision_normals[collider].normalized()
				#
				#var collision_magnitudes : Vector2 = Vector2.ZERO
				#for collider in collision_normals.keys():
					#collision_magnitudes += collision_normals[collider]
				
				#if collision_normals.keys().size() > 1:
					#prints(
						#node.get_slide_collision_count(), 
						#collision_magnitudes, 
						#collision_magnitudes.length()
					#)
				
				#if collision_magnitudes.length() < 0.5:
				#	node.take_damage(0, _knockback_direction, true)
	
	for node in _damage_area.get_overlapping_bodies():
		if node is Character:
			node.take_damage(0, _knockback_direction, true)

func _draw():
	if Engine.is_editor_hint() == false: return
	
	var starting_pos : Vector2 = Vector2(
		_width * World.level.tile_size / 2.0 - _half_tile.x, World.level.tile_size - _half_tile.y
	)
	var end_pos : Vector2 = starting_pos + Vector2(0.0, _max_extent)
	
	# crush height
	draw_line(
		starting_pos,
		end_pos, _debug_height_color, World.level.tile_size
	)
	
	# starting offset
	draw_line(
		starting_pos,
		lerp(starting_pos, end_pos, _starting_offset_factor), _debug_offset_color, World.level.tile_size
	)

func _build_crusher():
	if is_node_ready() == false:
		await ready
	
	# cleanup sprites
	for sprite : Sprite2D in _crusher_sprites.get_children():
		sprite.queue_free()
	for sprite : Sprite2D in _base_sprites.get_children():
		sprite.queue_free()
	
	# base and crusher sprites
	for w in _width:
		var base_sprite : Sprite2D = Sprite2D.new()
		base_sprite.position = Vector2(w * World.level.tile_size, 0.0)
		if w == 0: # left
			base_sprite.texture = _textures["base_left"]
		elif w == _width-1: # right
			base_sprite.texture = _textures["base_right"]
		else: # center
			base_sprite.texture = _textures["base_center"]
		_base_sprites.add_child(base_sprite)
		
		var crusher_sprite : Sprite2D = Sprite2D.new()
		crusher_sprite.position = base_sprite.position
		if w == 0: # left
			crusher_sprite.texture = _textures["crusher_left"]
		elif w == _width-1: # right
			crusher_sprite.texture = _textures["crusher_right"]
		else: # center
			crusher_sprite.texture = _textures["crusher_center"]
		_crusher_sprites.add_child(crusher_sprite)
		
		var crusher_spike_sprite : Sprite2D = Sprite2D.new()
		crusher_spike_sprite.position = base_sprite.position + Vector2(0.0, World.level.tile_size)
		crusher_spike_sprite.texture = _textures["spike"]
		_crusher_sprites.add_child(crusher_spike_sprite)
	
	# chain sprites
	for i in int(_max_extent / World.level.tile_size) - 2:
		for j in 2: # 2 for left and right sprites
			var chain_sprite : Sprite2D = Sprite2D.new()
			chain_sprite.texture = _textures["chain"]
			_chain_sprites.add_child(chain_sprite)
	
	# colliders
	_collider.shape.size = Vector2(_width * World.level.tile_size, World.level.tile_size)
	_collider.position = -_half_tile + _collider.shape.size / 2.0
	
	_damage_area_collider.shape.size = Vector2(
		_width * World.level.tile_size,
		_hurtbox_height
	)
	_damage_area_collider.position = -_half_tile + Vector2(
		_damage_area_collider.shape.size.x / 2.0,
		World.level.tile_size + _hurtbox_height / 2.0
	)
	
	queue_redraw()

# TODO: only animate chains when the crusher is moving, gonna need a different
#       approach to animating
func _on_animation_timer_timeout():
	# manual animation using _animation_offset_sign as a shift multiplier
	# that's what I get for wanting maximum customization
	for texture_name : String in _textures.keys():
		_textures[texture_name].region.position.x += World.level.tile_size * 3 * _animation_offset_sign
	
	_animation_offset_sign = -_animation_offset_sign
