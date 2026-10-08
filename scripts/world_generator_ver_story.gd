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

@export_category("Story Final Settings")
@export var final_chunk_scene: PackedScene  # ด่านพิเศษฉากจบเมื่อผ่านทุกเลเวล
@export var next_scene: PackedScene  # ซีนใหม่ที่จะเปลี่ยนไปเมื่อจบด่านสุดท้าย
@export var change_scene_delay: float = 1.0  # เวลาหน่วงก่อนเปลี่ยนซีน (วินาที)
@export var total_levels: int = 3
@export var chunks_per_level: int = 20

@export_category("Generation")
@export var chunk_length: float = 120.0
@export var chunks_ahead: int = 4
@export var chunks_behind: int = 2

@export_category("UI & Timer")
@export var time_label: Label

var highest_chunk: int = 0
var generated_chunks: Dictionary = {}

var elapsed_time: float = 0.0
var is_timer_running: bool = true
var max_story_chunks: int = 0  # จำนวน Chunk ทั้งหมดของ Story (20 * 3 = 60)

func _ready() -> void:
	add_to_group("world_generator")
	max_story_chunks = chunks_per_level * total_levels
	
	for chunk_index in range(-chunks_behind, chunks_ahead + 1):
		create_chunk(chunk_index)

	highest_chunk = chunks_ahead

func _process(delta: float) -> void:
	# จับเวลาใน Story Mode
	if is_timer_running:
		elapsed_time += delta
		update_timer_ui()

	if player == null:
		return

	var player_chunk := get_player_chunk()

	# หยุดเวลาและเปลี่ยนซีนเมื่อผู้เล่นวิ่งมาถึง Chunk ฉากจบ (และเล่นมาเกิน 1 วินาทีแล้วเพื่อป้องกัน Bug วาร์ป)
	if is_timer_running and player_chunk >= max_story_chunks + 1 and elapsed_time > 1.0:
		finish_story_mode()

	generate_ahead(player_chunk)
	remove_old_chunks(player_chunk)

## เรียกจากหน้า Result ตอนผู้เล่นตาย: หยุดจับเวลา
func stop_timer() -> void:
	is_timer_running = false


func get_player_chunk() -> int:
	if player == null:
		return 0
	return floori(-player.global_position.z / chunk_length)

func generate_ahead(player_chunk: int) -> void:
	var target_chunk := player_chunk + chunks_ahead

	# อนุญาตให้สร้างล่วงหน้าไปถึง max_story_chunks + 1 เพื่อให้ด่านจบถูกโหลด
	while highest_chunk < target_chunk and highest_chunk <= max_story_chunks + 1:
		highest_chunk += 1
		create_chunk(highest_chunk)

func create_chunk(chunk_index: int) -> void:
	if generated_chunks.has(chunk_index):
		return

	var selected_scene: PackedScene = null

	# เช็คว่าถึงด่านจบพิเศษหรือยัง
	if chunk_index == max_story_chunks + 1:
		selected_scene = final_chunk_scene
	elif chunk_index <= max_story_chunks:
		selected_scene = get_random_chunk_for_index(chunk_index)

	if selected_scene == null:
		return

	var chunk := selected_scene.instantiate()
	$Chunks.add_child(chunk)
	chunk.position = Vector3(0, 0, -chunk_index * chunk_length)
	generated_chunks[chunk_index] = chunk

# แก้ไขในไฟล์ ฟังก์ชัน get_random_chunk_for_index()

func get_random_chunk_for_index(chunk_index: int) -> PackedScene:
	if chunk_index <= 0:
		return chunk_scenes.pick_random() if not chunk_scenes.is_empty() else null

	# คำนวณ Level Index (0, 1, 2) ให้ถูกต้อง (ใช้ chunk_index - 1 เพื่อให้ Chunk 1-20 อยู่ใน Level 0)
	var level_index := floori(float(chunk_index - 1) / chunks_per_level)
	level_index = clamp(level_index, 0, total_levels - 1)

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

	# ถ้าระดับนั้นไม่มี Scene กำหนดไว้ ให้ดึง Level 0 มาใช้สำรอง
	if current_scenes.is_empty():
		current_scenes = chunk_scenes
		current_chances = chunk_chances

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

func update_timer_ui() -> void:
	if time_label:
		var total_sec := int(elapsed_time)
		var hrs := total_sec / 3600
		var mins := (total_sec % 3600) / 60
		var secs := total_sec % 60
		time_label.text = "Time %02d:%02d:%02d" % [hrs, mins, secs]

# ฟังก์ชันนี้ถูกเรียกอัตโนมัติเมื่อผู้เล่นวิ่งถึง Chunk ฉากจบ
func finish_story_mode() -> void:
	if not is_timer_running:
		return

	is_timer_running = false

	print("================================")
	print("🎉 STORY MODE CLEAR")
	print("Elapsed Time: ", elapsed_time)

	# ส่งเวลารอบนี้ไปให้ ScoreManager
	ScoreManager.save_story_time(elapsed_time)

	print("Current Session Time: ", ScoreManager.current_session_time)
	print("Best Story Time: ", ScoreManager.best_time_story)

	print("================================")

	# เปลี่ยนไป Victory Scene
	if next_scene != null:

		if change_scene_delay > 0.0:
			await get_tree().create_timer(change_scene_delay).timeout

		get_tree().change_scene_to_packed(next_scene)

	else:

		print("⚠️ WARNING: next_scene is not assigned!")
