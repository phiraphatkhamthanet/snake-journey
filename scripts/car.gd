extends Node3D

@export var move_speed: float = 10.0      # ความเร็วการเคลื่อนที่
@export var despawn_time: float = 2.0    # ระยะเวลาวิ่งก่อนจะเกิดใหม่ (วินาที)

@export_category("Player Hit Settings")
@export var knockback_force: float = 80.0             # แรงดีดไปข้างหน้า (ตามแกน X)
@export var knockback_up_force: float = 40.0          # แรงดีดพุ่งขึ้นฟ้า
@export var delay_before_change_scene: float = 3.0    # เวลาหน่วงก่อนเปลี่ยนซีน (วินาที)
@export var next_scene: PackedScene        
		   # ซีนที่จะเปลี่ยนไปหลังโดนชนปกติ
@export_category("Sound System")
@export_enum("alien_sfx", "carmel_sfx", "monkey_sfx", "honk_sfx", "elephant_sfx", "tiger_sfx", "horse_sfx") var Sound: String = "honk_sfx"

@export_category("Ad System")
@export var ad_scenes: Array[PackedScene]             # อาร์เรย์เก็บซีนโฆษณาหลายๆ ซีนสำหรับสุ่ม
@export var max_hits_for_ad: int = 2                  # จำนวนครั้งที่โดนชนแล้วจะสุ่มโฆษณา

# ตัวแปร static เพื่อให้นับจำนวนครั้งสะสมข้ามการ Reload Scene ได้
static var hit_counter: int = 0

var current_time: float = 0.0
var spawn_position: Vector3              # ตัวแปรเก็บตำแหน่งเริ่มต้น
var is_hit: bool = false                 # ป้องกันการชนซ้ำ


func _ready() -> void:
	# บันทึกตำแหน่งแรกที่วางวัตถุไว้ในฉาก
	spawn_position = position


func _process(delta: float) -> void:
	# 1. เคลื่อนที่ไปตามแนวแกน X
	position.x += move_speed * delta
	
	# 2. นับเวลาสะสมเพื่อ respawn ตามปกติ
	current_time += delta
	if current_time >= despawn_time:
		respawn()


func respawn() -> void:
	position = spawn_position  # ย้ายกลับไปจุดเริ่มต้น
	current_time = 0.0          # รีเซ็ตตัวนับเวลาใหม่


## ฟังก์ชันเชื่อมต่อสัญญาณ body_entered จาก Area3D
func _on_area_3d_body_entered(body: Node) -> void:
	if is_hit:
		return

	# ตรวจสอบว่าเป็น PhysicalBone3D ของผู้เล่นหรือไม่
	if body is PhysicalBone3D:
		is_hit = true
		
		var sound_node = AudioManager.get(Sound)
		if sound_node and sound_node.has_method("play"):
			sound_node.play()
		
		# เพิ่มจำนวนครั้งที่โดนชน
		hit_counter += 1
		print("ชน PhysicalBone3D แล้ว! จำนวนครั้งที่โดนชนสะสม: ", hit_counter)
		
		# 1. รีเซ็ตความเร็วเดิมก่อนส่งแรงกระแทกใหม่
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		
		# 2. คำนวณทิศทางแรงกระเด็น (ไปข้างหน้า + พุ่งขึ้นฟ้า)
		var knockback_impulse := Vector3.RIGHT * knockback_force + Vector3.UP * knockback_up_force
		
		# 3. ผลักกระดูกชิ้นที่ชนโดยตรง (ใส่ออฟเซ็ตเล็กน้อยเพื่อให้กระดูกหมุนคว้างตามธรรมชาติ)
		var random_offset := Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		body.apply_impulse(knockback_impulse, random_offset)

		# 4. ถ้าต้องการให้ตัวผู้เล่น (CharacterBody3D) รับรู้แรงด้วย
		var player_owner: Node = body.owner
		if player_owner and player_owner.has_method("apply_knockback"):
			player_owner.apply_knockback(knockback_impulse)

		# 5. รอตามเวลาที่กำหนดให้เห็นตัวละครลอยกระเด็น
		await get_tree().create_timer(delay_before_change_scene).timeout
		
		# 6. ตรวจสอบเงื่อนไขการเปลี่ยน Scene / สุ่มแสดงโฆษณา
		if hit_counter >= max_hits_for_ad:
			# รีเซ็ตค่างวดนับกลับไปเป็น 0
			hit_counter = 0
			
			# เช็คว่ามี Scene โฆษณาอยู่ใน Array หรือไม่
			if not ad_scenes.is_empty():
				# ระบุประเภท PackedScene ชัดเจนแทนการใช้ :=
				var random_ad: PackedScene = ad_scenes.pick_random()
				print("โดนชนครบกำหนด! สุ่มเปลี่ยนไปซีนโฆษณา...")
				get_tree().change_scene_to_packed(random_ad)
			else:
				print("ไม่มี Scene ใน ad_scenes! กำลังรีโหลดฉากเดิม...")
				get_tree().reload_current_scene()
		else:
			# หากยังไม่ครบตามจำนวนครั้ง ให้ย้ายไป next_scene หรือ reload ฉากเดิม
			if next_scene != null:
				get_tree().change_scene_to_packed(next_scene)
			else:
				get_tree().reload_current_scene()
