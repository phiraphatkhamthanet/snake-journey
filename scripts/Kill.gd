extends Area3D

@export_category("Player Hit Settings")
@export var knockback_force: float = 80.0
@export var knockback_up_force: float = 40.0
@export var delay_before_change_scene: float = 3.0
@export var next_scene: PackedScene
@export var result_hold_time: float = 2.0

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

		_trigger_result()

## เลือกซีนที่จะไปต่อ (ตัดสินตอนชน เพราะหลังชนโหนดนี้อาจถูกลบไปพร้อม Chunk)
func _pick_target() -> PackedScene:
	if hit_counter >= max_hits_for_ad:
		hit_counter = 0
		if not ad_scenes.is_empty():
			return ad_scenes.pick_random()
	return next_scene


## สั่งให้ Result (ซึ่งอยู่ในซีน World ตลอด) รอแล้วแสดงตัวเอง จากนั้นค่อยไปโฆษณา/next_scene
func _trigger_result() -> void:
	var result_control := get_tree().get_first_node_in_group("result_screen")
	if result_control == null:
		push_warning("ไม่พบ Result ในฉาก (group result_screen)")
		return
	result_control.trigger_death(delay_before_change_scene, result_hold_time, _pick_target())
