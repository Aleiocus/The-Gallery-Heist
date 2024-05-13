class_name Level
extends Node2D

signal score_changed

enum SaulLetter {S, A, U, L}

# level dependencies
@onready var player : Player = $Saul
@onready var interface : CanvasLayer = $UI
@onready var pause_manager : MarginContainer = $UI/PauseManager
@onready var level_camera : LevelCamera = $LevelCamera
@onready var tilemap : TileMap = $TileMap
@onready var music_player : Node = $Audio/MusicPlayer
@onready var dialogue_player : MarginContainer = $UI/DialoguePlayer
const tile_size : int = 16

@onready var _screen_transition : TextureRect = $UI/ScreenTransition

var _score : int = 0
var _found_letters : Dictionary = {
	SaulLetter.S:false,
	SaulLetter.A:false,
	SaulLetter.U:false,
	SaulLetter.L:false,
}

var _player_starting_position : Vector2
var _checkpoint : Checkpoint = null


func _ready():
	player.died.connect(_on_player_died)
	
	# initial checkpoint is spawn point
	_player_starting_position = player.global_position

func add_score(amount : int = 1):
	_score += amount
	interface.set_score(_score)
	score_changed.emit()

func get_score() -> int:
	return _score

func set_checkpoint(checkpoint : Checkpoint):
	if _checkpoint:
		_checkpoint.uncheck()
	
	_checkpoint = checkpoint

func found_letter(letter : SaulLetter):
	assert(_found_letters[letter] == false, "Letter already found, make sure the level only has 1 of each letter")
	_found_letters[letter] = true
	interface.show_letters_found(_found_letters)

func is_water_tile(global_pos : Vector2) -> bool:
	var tileset : TileSet = tilemap.tile_set
	# ensure tileset has "water" custom data first to avoid errors
	var has_water_var : bool = false
	for i in tileset.get_custom_data_layers_count():
		if tileset.get_custom_data_layer_name(i) == "water":
			has_water_var = true
			break
	if has_water_var == false: return false
	
	var layers_count : int = tilemap.get_layers_count()
	for i in layers_count:
		# check all layers for a water tile
		var data : TileData = tilemap.get_cell_tile_data(
			i, tilemap.local_to_map(global_pos)
		)
		if data && data.get_custom_data("water") == true:
			return true
	
	return false

func is_breathable_tile(global_pos : Vector2) -> bool:
	if is_water_tile(global_pos): return false
	
	var tileset : TileSet = tilemap.tile_set
	if tileset.get_physics_layers_count() == 0: return true
	
	var layers_count : int = tilemap.get_layers_count()
	for i in layers_count:
		# check all layers for collidable tile
		var data : TileData = tilemap.get_cell_tile_data(
			i, tilemap.local_to_map(global_pos)
		)
		if data && data.get_collision_polygons_count(0) > 0:
			# found a solid tile so not breathable. this makes 2 assumptions:
			# 1- if a tile has a collider it's not breathable even if the collider doesn't cover the whole tile
			# 2- only checks for physics layer 0 assuming that any solid layer will be put at idx 0 while other more "stylized" colliders (collide with enemy only etc..) will be at other indicies
			return false
	
	return true

func _on_player_died():
	_screen_transition.transition()
	await _screen_transition.screen_hidden
	
	if _checkpoint:
		player.reset_from_checkpoint(_checkpoint.get_spawn_position())
	else:
		player.reset_from_checkpoint(_player_starting_position)
