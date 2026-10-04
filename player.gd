extends CharacterBody3D

@export_category("Player Properties")
@export var follow_lerp_factor : float = 5.0
@export var ragdoll_crawl_force : float = 67 # แรงผลักสำหรับเลื้อยในสถานะ Ragdoll
@export var ragdoll_jump_force : float = 67

@onready var lead_bone: PhysicalBone3D = find_child("Physical Bone Body", true, false) 

@onready var model = $"Root Scene/RootNode/SnakeArmature"
@onready var spring_arm: Node3D = $CameraPivot
@onready var main_collision: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var ragdoll: PhysicalBoneSimulator3D = find_child("PhysicalBoneSimulator3D", true, false)

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2
var is_ragdoll := false

func _ready() -> void:
	if ragdoll == null:
		return
	is_ragdoll = true

	# 1. หยุด Animation
	if animation_player:
		animation_player.stop()

	# 2. ปิดการชนของ CharacterBody3D เพื่อให้กระดูกมีอิสระและลอดสิ่งกีดขวางได้
	if main_collision:
		main_collision.set_deferred("disabled", true)

	# 3. เริ่มการจำลองระบบกระดูกฟิสิกส์
	ragdoll.physical_bones_start_simulation()

func _physics_process(delta: float) -> void:
	if is_ragdoll:
		process_ragdoll_movement(delta)

	# ให้กล้องเล็งตามตำแหน่งตัวละครตลอดเวลา
	if spring_arm:
		spring_arm.global_position = lerp(spring_arm.global_position, global_position, delta * follow_lerp_factor)

# --- โหมด Ragdoll (ลอดช่อง/ไถลตัว) ---
func process_ragdoll_movement(delta: float) -> void:
	if lead_bone == null:
		return

	# 1. ย้ายตำแหน่ง Node หลักตามกระดูก เพื่อไม่ให้ตำแหน่งจริงหลุดจากโมเดล
	global_position = lead_bone.global_position

	# 2. รับ Input เพื่อผลักกระดูกให้เลื้อยไปข้างหน้าตามมุมกล้อง
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("left", "right")
	move_direction.z = Input.get_axis("forward", "back")

	if move_direction != Vector3.ZERO:
		var cam_y_rot = spring_arm.rotation.y if spring_arm else 0.0
		move_direction = move_direction.rotated(Vector3.UP, cam_y_rot).normalized()
		# ส่งแรงผลักตรงไปยังกระดูกหลัก
		lead_bone.apply_central_impulse(move_direction * ragdoll_crawl_force * delta)
		
	# 3. การกระโดด (Jump)
	if Input.is_action_just_pressed("jump") and is_ragdoll_grounded():
		# ส่งแรงเด้งขึ้นด้านบน
		lead_bone.apply_central_impulse(Vector3.UP * ragdoll_jump_force)

func is_ragdoll_grounded() -> bool:
	if lead_bone == null:
		return false

	var space_state = get_world_3d().direct_space_state
	# ยิงลำแสงจากตำแหน่งกระดูกลงไปด้านล่าง 0.6 เมตร
	var query = PhysicsRayQueryParameters3D.create(
		lead_bone.global_position,
		lead_bone.global_position + Vector3.DOWN * 0.6
	)
	
	# กำหนดไม่ให้ Raycast ชนกระดูกตัวเอง
	query.exclude = [lead_bone.get_rid()]

	var result = space_state.intersect_ray(query)
	return not result.is_empty()

## ฟังก์ชันรับแรงดีดกระเด็น (ถูกเรียกจากสคริปต์รถ)
func apply_knockback(force: Vector3) -> void:
	if ragdoll == null:
		return

	# วนลูปส่งแรงกระแทกเข้าไปยังกระดูกทุกชิ้นใน PhysicalBoneSimulator3D
	for child in ragdoll.get_children():
		if child is PhysicalBone3D:
			# 1. รีเซ็ตความเร็วเดิมก่อนรับแรงใหม่
			child.linear_velocity = Vector3.ZERO
			child.angular_velocity = Vector3.ZERO
			
			# 2. ส่งแรงดีดกระเด็นพุ่งออกไป พร้อมใส่ออฟเซ็ตเล็กน้อยเพื่อให้ตัวละครหมุนคว้างกลางอากาศ
			var offset := Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
			child.apply_impulse(force * 2.0, offset)
