extends Node3D

@export var player: CharacterBody3D

@export_category("Chunks Level 0")
@export var chunk_scenes: Array[PackedScene]
@export var chunk_chances: Array[float]

@export_category("Chunks Level 1")
@export var chunk_scenes1: Array[PackedScene]
@export var chunk_chances1: Array[float]

@export_category("Chunks Level 2")
@export var chunk_scenes2: Array[PackedScene]
@export var chunk_chances2: Array[float]

@export_category("Generation")
@export var chunk_length: float = 120.0
@export var chunks_ahead: int = 4
@export var chunks_behind: int = 2
@export var chunks_per_level: int = 20

@export_category("UI Settings")
@export var score_label: Label

var highest_chunk: int = 0
var generated_chunks: Dictionary = {}

var score: int = 0
var max_passed_chunk: int = 0
var score_frozen: bool = false  # true หลังผู้เล่นตาย คะแนนจะไม่เพิ่มอีก

func _ready() -> void:
	add_to_group("world_generator")
	for chunk_index in range(-chunks_behind, chunks_ahead + 1):
		create_chunk(chunk_index)

	highest_chunk = chunks_ahead
	update_score_ui()

func _process(_delta: float) -> void:
	if player == null:
		return

	var player_chunk := get_player_chunk()

	# คำนวณคะแนนระยะทาง (Endless Score)
	if not score_frozen and player_chunk > max_passed_chunk:
		var gained := player_chunk - max_passed_chunk
		max_passed_chunk = player_chunk
		score += gained
		
		# อัปเดต UI และบันทึก High Score
		update_score_ui()
		ScoreManager.save_endless_score(score)

	generate_ahead(player_chunk)
	remove_old_chunks(player_chunk)

## เรียกจากหน้า Result ตอนผู้เล่นตาย: หยุดนับคะแนน
func freeze_score() -> void:
	score_frozen = true


func get_player_chunk() -> int:
	return floori(-player.global_position.z / chunk_length)

func generate_ahead(player_chunk: int) -> void:
	var target_chunk := player_chunk + chunks_ahead

	while highest_chunk < target_chunk:
		highest_chunk += 1
		create_chunk(highest_chunk)

func create_chunk(chunk_index: int) -> void:
	if generated_chunks.has(chunk_index):
		return

	var selected_scene := get_random_chunk_for_index(chunk_index)

	if selected_scene == null:
		return

	var chunk := selected_scene.instantiate()
	$Chunks.add_child(chunk)
	chunk.position = Vector3(0, 0, -chunk_index * chunk_length)
	generated_chunks[chunk_index] = chunk

func get_random_chunk_for_index(chunk_index: int) -> PackedScene:
	# posmod ทำให้วนลูป 0 -> 1 -> 2 -> 0 -> 1 -> 2... ไปเรื่อยๆ
	var level_index := posmod(floori(float(chunk_index) / chunks_per_level), 3)

	var current_scenes: Array[PackedScene] = []
	var current_chances: Array[float] = []

	match level_index:
		0:
			current_scenes = chunk_scenes
			current_chances = chunk_chances
		1:
			current_scenes = chunk_scenes1
			current_chances = chunk_chances1
		2:
			current_scenes = chunk_scenes2
			current_chances = chunk_chances2

	if current_scenes.is_empty():
		return null

	if current_chances.size() != current_scenes.size():
		return current_scenes.pick_random()

	var total_weight := 0.0
	for chance in current_chances:
		total_weight += chance

	if total_weight <= 0.0:
		return current_scenes.pick_random()

	var random_value := randf_range(0.0, total_weight)
	var current_weight := 0.0

	for i in range(current_scenes.size()):
		current_weight += current_chances[i]
		if random_value <= current_weight:
			return current_scenes[i]

	return current_scenes.back()

func remove_old_chunks(player_chunk: int) -> void:
	var minimum_chunk := player_chunk - chunks_behind
	for chunk_index in generated_chunks.keys():
		if chunk_index < minimum_chunk:
			generated_chunks[chunk_index].queue_free()
			generated_chunks.erase(chunk_index)

func update_score_ui() -> void:
	if score_label:
		score_label.text = "Score: " + str(score)
