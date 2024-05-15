@tool
extends StaticBody2D

enum _State {restore, solid, destoy, empty}

## the number of tiles in the platform
@export var _count : int :
	set(value):
		_count = max(value, 1)
		
		if is_node_ready() == false:
			await ready
		
		for sprite in _sprites_container.get_children():
			sprite.queue_free()
		
		for i in _count:
			var sprite : Sprite2D = Sprite2D.new()
			sprite.texture = AtlasTexture.new()
			sprite.texture.atlas = preload("res://Resources/Textures/unstable_platform.png")
			var region_x : int
			if _count == 1:
				region_x = 16 # lone piece
			elif i == 0:
				region_x = 0 # left edge
			elif i == _count-1:
				region_x = 32 # right edge
			else:
				region_x = 16 # center
			
			sprite.texture.region = Rect2i(
				region_x, 0, 16, 16
			)
			sprite.position = Vector2(8.0 + i * 16.0, 8.0)
			_sprites_container.add_child(sprite)
		
		_collider.shape.size = Vector2(
			16 * _count,
			16
		)
		_collider.position = _collider.shape.size / 2.0
		
		_detection_collider.shape.size = Vector2(_collider.shape.size.x, 1.0)
		_detection_collider.position = Vector2(
			_detection_collider.shape.size.x / 2.0,
			0.0
		)
		
		_particles.amount = min(_count * _particles_per_sprite, _max_particles)
		_particles.position = Vector2(8.0 * _count, 8.0)
		_particles.process_material.emission_box_extents.x = _particles.position.x
## how long until the platform is fully destroyed
@export var _destroy_time : float = 3.2 :
	set(value):
		_destroy_time = max(value, 0.0)
## how long until the platform is fully restored
@export var _restore_time : float = 1.6 :
	set(value):
		_restore_time = max(value, 0.0)
## the platform will remain destroyed for this time before being restored
@export var _cooldown_time : float = 1.4 :
	set(value):
		_cooldown_time = max(value, 0.0)

@onready var _sprites_container : Node2D = $Sprites
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _detection_collider : CollisionShape2D = $PlayerDetection/CollisionShape2D
@onready var _particles : GPUParticles2D = $GPUParticles2D
@onready var _timer : Timer = $Timer

const _destroyed_transparency : float = 0.4
const _particles_per_sprite : int = 10
const _max_particles : int = 100
var _current_state = _State.solid
const _stages_count : int = 3
var _curr_stage : int


func _on_detection_body_entered(body : Node2D):
	if body is Player && _current_state == _State.solid:
		_current_state = _State.destoy
		_curr_stage = 0
		_timer.wait_time = _destroy_time / _stages_count
		_on_timer_timeout()

func _on_timer_timeout():
	match _current_state:
		_State.destoy:
			_particles.restart()
			_curr_stage += 1
			for sprite in _sprites_container.get_children():
				sprite.texture.region.position.y += 16
			
			var region_x : float = _sprites_container.get_child(0).texture.region.position.y
			if _curr_stage == _stages_count:
				# fully destroyed
				_current_state = _State.empty
				_collider.disabled = true
				_detection_collider.disabled = true
				_timer.wait_time = _cooldown_time
			
			_timer.start()
		
		_State.empty:
			# cooldown before rebuilding
			_current_state = _State.restore
			_curr_stage = 0
			_timer.wait_time = _restore_time / _stages_count
			_timer.start()
		
		_State.restore:
			modulate.a = _destroyed_transparency
			_curr_stage += 1
			for sprite in _sprites_container.get_children():
				sprite.texture.region.position.y -= 16
			
			if _curr_stage == _stages_count:
				# fully restored
				_current_state = _State.solid
				_collider.disabled = false
				_detection_collider.disabled = false
				modulate.a = 1.0
			
			else:
				_timer.start()
