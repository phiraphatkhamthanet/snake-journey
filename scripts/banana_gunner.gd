extends "res://scripts/banana_man.gd"
## กล้วยถือปืน: ยืนยิงใส่ผู้เล่นจากระยะไกล
## ถ้าผู้เล่นเข้าใกล้ (<= attack_range) จะกลับไปต่อยแบบ Banana_man เดิม

@export_group("Gun")
@export var bullet_scene: PackedScene
@export var bullet_damage: float = 10.0
@export var bullet_speed: float = 45.0
@export var shoot_range: float = 45.0
@export var shoot_cooldown: float = 1.2
@export var aim_height: float = 2.3
@export var spread_degrees: float = 2.0
@export var face_tolerance: float = 0.97
@export var require_line_of_sight: bool = true

@export_group("Gun Visual")
## ถ้าอยากให้เล่นท่าทางตอนยิง ใส่ชื่อ animation ที่นี่ (ว่าง = ไม่เล่น)
@export var shoot_animation: StringName = &""
@export var shoot_pose_time: float = 0.35
@export var muzzle_flash_time: float = 0.06
@export var gun_recoil_distance: float = 0.35

@onready var muzzle: Marker3D = $Muzzle
@onready var muzzle_flash: Node3D = $Muzzle/Flash
@onready var gun_mesh: Node3D = $Gun

var shoot_timer: float = 0.0
var pose_timer: float = 0.0
var flash_timer: float = 0.0
var gun_rest_position: Vector3


func _ready() -> void:
	super._ready()
	gun_rest_position = gun_mesh.position
	muzzle_flash.visible = false
	# ให้ยิงนัดแรกช้าลงนิดหน่อย ไม่ยิงทันทีที่เห็น
	shoot_timer = shoot_cooldown * 0.5


func _physics_process(delta: float) -> void:
	shoot_timer = maxf(shoot_timer - delta, 0.0)
	pose_timer = maxf(pose_timer - delta, 0.0)

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

	# ปืนเด้งกลับที่เดิมหลังโดนแรงถีบ
	gun_mesh.position = gun_mesh.position.lerp(
		gun_rest_position, minf(15.0 * delta, 1.0)
	)

	super._physics_process(delta)


func play_animation(anim_name: StringName) -> void:
	# ไม่ให้ idle/run ทับท่ายิง
	if pose_timer > 0.0:
		return
	super.play_animation(anim_name)


func chase_player(delta: float) -> void:
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0

	var distance: float = to_player.length()

	if distance <= 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	# ใกล้มาก -> ต่อยแบบเดิม
	if distance <= attack_range:
		super.chase_player(delta)
		return

	var direction: Vector3 = to_player / distance

	var target_angle: float = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		minf(8.0 * delta, 1.0)
	)

	var can_shoot_here: bool = (
		distance <= shoot_range
		and (not require_line_of_sight or has_line_of_sight())
	)

	if can_shoot_here:
		# หยุดยืนยิง
		velocity.x = 0.0
		velocity.z = 0.0
		play_animation(idle_animation)

		var facing: float = global_transform.basis.z.dot(direction)
		if shoot_timer <= 0.0 and facing >= face_tolerance:
			shoot()
	else:
		# ยังไกล/มีของบัง -> วิ่งเข้าไป
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		play_animation(run_animation)


func get_aim_point() -> Vector3:
	return player.global_position + Vector3.UP * aim_height


func has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false

	var query := PhysicsRayQueryParameters3D.create(
		muzzle.global_position,
		get_aim_point()
	)
	query.exclude = [get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(
		query
	)

	if hit.is_empty():
		return true

	var collider: Object = hit["collider"]
	return collider is Node and (collider as Node).is_in_group("Player")


func shoot() -> void:
	if is_dead or bullet_scene == null or not is_instance_valid(player):
		return

	shoot_timer = shoot_cooldown

	var origin: Vector3 = muzzle.global_position
	var dir: Vector3 = (get_aim_point() - origin).normalized()

	# สุ่มส่ายนิดหน่อย
	var spread: float = tan(deg_to_rad(spread_degrees))
	dir = (dir + Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * spread).normalized()

	var bullet: Node3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = origin
	bullet.launch(dir, self, bullet_damage, bullet_speed)

	# เอฟเฟกต์: แฟลชปากกระบอก + ปืนสะบัด
	muzzle_flash.visible = true
	flash_timer = muzzle_flash_time
	gun_mesh.position = gun_rest_position + Vector3(
		0.0, 0.0, -gun_recoil_distance
	)

	if shoot_animation != &"" and animation_player.has_animation(shoot_animation):
		pose_timer = shoot_pose_time
		animation_player.play(shoot_animation)
