extends Node3D

@export var move_speed: float = 10.0      # ความเร็วการเคลื่อนที่
@export var despawn_time: float = 2.0    # ระยะเวลาวิ่งก่อนจะเกิดใหม่ (วินาที)

@export_category("Player Hit Settings")
@export var knockback_force: float = 80.0             # แรงดีดไปข้างหน้า (ตามแกน X)
@export var knockback_up_force: float = 40.0          # แรงดีดพุ่งขึ้นฟ้า
@export var delay_before_change_scene: float = 3.0    # เวลาหน่วงก่อนเปลี่ยนซีน (วินาที)
@export var next_scene: PackedScene                   # ซีนที่จะเปลี่ยนไปหลังโดนชน

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
		print("ชน PhysicalBone3D แล้ว! ผลักกระเด็นทันที...")
		
		# 1. รีเซ็ตความเร็วเดิมก่อนส่งแรงกระแทกใหม่
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		
		# 2. คำนวณทิศทางแรงกระเด็น (ไปข้างหน้า + พุ่งขึ้นฟ้า)
		var knockback_impulse := Vector3.RIGHT * knockback_force + Vector3.UP * knockback_up_force
		
		# 3. ผลักกระดูกชิ้นที่ชนโดยตรง (ใส่ออฟเซ็ตเล็กน้อยเพื่อให้กระดูกหมุนคว้างตามธรรมชาติ)
		var random_offset := Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		body.apply_impulse(knockback_impulse, random_offset)

		# 4. ถ้าต้องการให้ตัวผู้เล่น (CharacterBody3D) รับรู้แรงด้วย
		var player_owner = body.owner
		if player_owner and player_owner.has_method("apply_knockback"):
			player_owner.apply_knockback(knockback_impulse)

		# 5. รอ 3 วินาทีให้เห็นตัวละครลอยกระเด็น แล้วเปลี่ยนซีน
		await get_tree().create_timer(delay_before_change_scene).timeout
		
		if next_scene != null:
			get_tree().change_scene_to_packed(next_scene)
		else:
			get_tree().reload_current_scene()
