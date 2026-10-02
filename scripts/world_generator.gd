extends Node3D

@export var player: CharacterBody3D
@export var chunk_scenes: Array[PackedScene]
@export var chunk_length: float = 20.0
@export var grid_size: float = 1.0
@export var chunk_rows: int = 5

@export var chunks_ahead: int = 4
@export var chunks_behind: int = 2

var highest_chunk: int = 0
var generated_chunks: Dictionary = {}


func _ready() -> void:
	for chunk_index in range(-chunks_behind, chunks_ahead + 1):
		create_chunk(chunk_index)

	highest_chunk = chunks_ahead


func _process(_delta: float) -> void:
	var player_chunk := get_player_chunk()

	generate_ahead(player_chunk)
	remove_old_chunks(player_chunk)


func get_player_chunk() -> int:
	return floori(
		-player.global_position.z / chunk_length
	)


func generate_ahead(player_chunk: int) -> void:
	var target_chunk := player_chunk + chunks_ahead

	while highest_chunk < target_chunk:
		highest_chunk += 1
		create_chunk(highest_chunk)


func create_chunk(chunk_index: int) -> void:
	if generated_chunks.has(chunk_index):
		return

	var selected_scene: PackedScene = chunk_scenes.pick_random()
	var chunk := selected_scene.instantiate()

	$Chunks.add_child(chunk)

	chunk.position = Vector3(
		0,
		0,
		-chunk_index * chunk_length
	)

	generated_chunks[chunk_index] = chunk


func remove_old_chunks(player_chunk: int) -> void:
	var minimum_chunk := player_chunk - chunks_behind

	for chunk_index in generated_chunks.keys():
		if chunk_index < minimum_chunk:
			generated_chunks[chunk_index].queue_free()
			generated_chunks.erase(chunk_index)
