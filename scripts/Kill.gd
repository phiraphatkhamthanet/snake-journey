extends Area3D

@export_category("Player Hit Settings")
@export var knockback_force: float = 80.0
@export var knockback_up_force: float = 40.0
@export var delay_before_change_scene: float = 3.0
@export var next_scene: PackedScene

@export_category("Sound System")
@export_enum("alien_sfx", "carmel_sfx", "monkey_sfx", "honk_sfx", "elephant_sfx", "tiger_sfx", "horse_sfx") var Sound: String = "honk_sfx"

@export_category("Ad System")
@export var ad_scenes: Array[PackedScene]
@export var max_hits_for_ad: int = 2

static var hit_counter: int = 0

var is_hit: bool = false


func _on_body_entered(body: Node3D) -> void:

	if is_hit:
		return

	# ตรวจว่าเป็น PhysicalBone3D ของ Player หรือไม่
	if body is PhysicalBone3D:

		is_hit = true

		# ==========================================
		# เล่นเสียง
		# ==========================================

		var sound_node = AudioManager.get(Sound)
		if sound_node and sound_node.has_method("play"):
			sound_node.play()

		# ==========================================
		# เพิ่มจำนวนครั้งที่โดนชน
		# ==========================================

		hit_counter += 1

		print(
			"โดนวัวชน! จำนวนครั้งที่โดนชนสะสม: ",
			hit_counter
		)

		# ==========================================
		# Knockback
		# ==========================================

		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

		var knockback_direction := Vector3.RIGHT

		var knockback_impulse := (
			knockback_direction * knockback_force
			+ Vector3.UP * knockback_up_force
		)

		var random_offset := Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2)
		)

		body.apply_impulse(
			knockback_impulse,
			random_offset
		)

		# ==========================================
		# ส่งแรงให้ Player หลักด้วย
		# ==========================================

		var player_owner: Node = body.owner

		if player_owner and player_owner.has_method("apply_knockback"):
			player_owner.apply_knockback(knockback_impulse)

		# ==========================================
		# รอก่อนเปลี่ยน Scene
		# ==========================================

		await get_tree().create_timer(
			delay_before_change_scene
		).timeout

		_change_scene()


func _change_scene() -> void:

	# ==========================================
	# ครบจำนวนครั้ง → สุ่มโฆษณา
	# ==========================================

	if hit_counter >= max_hits_for_ad:

		hit_counter = 0

		if not ad_scenes.is_empty():

			var random_ad: PackedScene = ad_scenes.pick_random()

			print(
				"โดนชนครบ ",
				max_hits_for_ad,
				" ครั้ง! สุ่มโฆษณา..."
			)

			get_tree().change_scene_to_packed(
				random_ad
			)

		else:

			print(
				"ไม่มี Scene ใน ad_scenes! "
				+ "กำลังไป Next Scene..."
			)

			if next_scene != null:
				get_tree().change_scene_to_packed(
					next_scene
				)
			else:
				get_tree().reload_current_scene()

		return

	# ==========================================
	# ยังไม่ครบ → Next Scene
	# ==========================================

	if next_scene != null:

		print(
			"โดนชนครั้งที่ ",
			hit_counter,
			"/",
			max_hits_for_ad,
			" → ไป Next Scene"
		)

		get_tree().change_scene_to_packed(
			next_scene
		)

	else:

		print("ไม่มี next_scene! กำลัง Reload Scene...")

		get_tree().reload_current_scene()
