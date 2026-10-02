extends Node3D

@export var player: CharacterBody3D
@export var chunk_scenes: Array[PackedScene]

@export var grid_size: float = 1.0
@export var chunk_rows: int = 5

@export var chunks_ahead: int = 4
@export var chunks_behind: int = 5

# กันเพิ่มอีกจำนวน Chunk
@export var safety_buffer: int = 2


var highest_chunk: int = 0
var generated_chunks: Dictionary = {}

# =========================================================
# Chunk ที่ผู้เล่น "ยืนอยู่บนพื้น" ล่าสุด
#
# สำคัญมาก:
# จะไม่เปลี่ยนค่านี้ขณะกำลังกระโดด
# =========================================================

var last_grounded_chunk: int = 0


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	if chunk_scenes.is_empty():
		push_error(
			"ข้อผิดพลาด: ไม่พบฉากใน chunk_scenes! " +
			"กรุณาเพิ่ม PackedScene ใน Inspector"
		)
		return

	# -----------------------------------------------------
	# สร้าง Chunk เริ่มต้น
	# -----------------------------------------------------

	for chunk_index in range(
		-chunks_behind,
		chunks_ahead + 1
	):
		create_chunk(chunk_index)

	highest_chunk = chunks_ahead

	# -----------------------------------------------------
	# ตั้งค่า Chunk เริ่มต้นของ Player
	# -----------------------------------------------------

	if is_instance_valid(player):
		last_grounded_chunk = get_player_chunk()


# =========================================================
# PROCESS
# =========================================================

func _process(_delta: float) -> void:

	if not is_instance_valid(player):
		return

	# -----------------------------------------------------
	# สำคัญ:
	# อัปเดต Chunk เฉพาะตอนผู้เล่นอยู่บนพื้น
	# -----------------------------------------------------

	if player.is_on_floor():

		last_grounded_chunk = get_player_chunk()

	# -----------------------------------------------------
	# ใช้ last_grounded_chunk เป็นตัวหลัก
	# -----------------------------------------------------

	generate_ahead(last_grounded_chunk)

	remove_old_chunks(last_grounded_chunk)


# =========================================================
# หาว่าผู้เล่นอยู่ Chunk ไหน
# =========================================================

func get_player_chunk() -> int:

	var chunk_length := grid_size * chunk_rows

	if chunk_length <= 0:
		chunk_length = 1.0

	return floori(
		-player.global_position.z / chunk_length
	)


# =========================================================
# สร้าง Chunk ด้านหน้า
# =========================================================

func generate_ahead(player_chunk: int) -> void:

	var target_chunk := player_chunk + chunks_ahead

	# สร้างทีละ Chunk
	if highest_chunk < target_chunk:

		highest_chunk += 1

		create_chunk(highest_chunk)


# =========================================================
# สร้าง Chunk
# =========================================================

func create_chunk(chunk_index: int) -> void:

	# ถ้ามีอยู่แล้ว ไม่ต้องสร้าง
	if generated_chunks.has(chunk_index):
		return

	# ป้องกัน Array ว่าง
	if chunk_scenes.is_empty():
		return

	# -----------------------------------------------------
	# เลือก Chunk แบบสุ่ม
	# -----------------------------------------------------

	var selected_scene: PackedScene = chunk_scenes.pick_random()

	if selected_scene == null:
		push_error("ไม่สามารถเลือก Chunk Scene ได้")
		return

	# -----------------------------------------------------
	# Instantiate
	# -----------------------------------------------------

	var chunk := selected_scene.instantiate()

	if chunk == null:
		push_error("ไม่สามารถ Instantiate Chunk ได้")
		return

	# -----------------------------------------------------
	# หา Node Chunks
	# -----------------------------------------------------

	var chunks_node := get_node_or_null("Chunks")

	if chunks_node:
		chunks_node.add_child(chunk)
	else:
		add_child(chunk)

	# -----------------------------------------------------
	# คำนวณความยาวจริงของ Chunk
	# -----------------------------------------------------

	var grid_map: GridMap = chunk.find_child(
		"GridMap",
		true,
		false
	)

	var real_chunk_length: float = (
		grid_size * chunk_rows
	)

	if grid_map:

		var cell_z_size: float = grid_map.cell_size.z

		var total_rows: int = chunk_rows

		var local_scale_z: float = chunk.scale.z

		real_chunk_length = (
			cell_z_size
			* total_rows
			* local_scale_z
		)

	# -----------------------------------------------------
	# วาง Chunk
	# -----------------------------------------------------

	chunk.position = Vector3(
		0,
		0,
		-chunk_index * real_chunk_length
	)

	# -----------------------------------------------------
	# เก็บข้อมูล
	# -----------------------------------------------------

	generated_chunks[chunk_index] = chunk


# =========================================================
# ลบ Chunk ด้านหลัง
# =========================================================

func remove_old_chunks(player_chunk: int) -> void:

	# -----------------------------------------------------
	# คำนวณ Chunk ที่อนุญาตให้ลบ
	#
	# player_chunk
	#      ↓
	#      [ผู้เล่น]
	#
	# ← safety buffer ← chunks_behind
	# -----------------------------------------------------

	var minimum_chunk := (
		player_chunk
		- chunks_behind
		- safety_buffer
	)

	# -----------------------------------------------------
	# Copy keys ก่อนลบ
	# -----------------------------------------------------

	var current_keys := generated_chunks.keys()

	for chunk_index in current_keys:

		# -------------------------------------------------
		# ถ้า Chunk อยู่ไกลด้านหลังเกินไป
		# -------------------------------------------------

		if chunk_index < minimum_chunk:

			# -------------------------------------------------
			# ห้ามลบ Chunk ที่ผู้เล่นกำลังยืนอยู่
			# -------------------------------------------------

			if chunk_index == last_grounded_chunk:
				continue

			# -------------------------------------------------
			# ลบ Node
			# -------------------------------------------------

			var chunk = generated_chunks[chunk_index]

			if is_instance_valid(chunk):
				chunk.queue_free()

			generated_chunks.erase(chunk_index)
