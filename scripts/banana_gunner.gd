
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal died

@export_group("Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var gravity: float = 9.8

@export_group("Combat")
@export var attack_damage: float = 10.0
@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0
@export var punch_hit_time: float = 0.4

@export_group("Health Bar")
@export var show_health_bar: bool = true
@export var health_bar_height: float = 6.8

@export_group("Animations")
@export var idle_animation: StringName = &"Melee-Library--OLD/Idle"
@export var run_animation: StringName = &"Melee-Library--OLD/run"
@export var punch_animation: StringName = &"Melee-Library--OLD/SlashATK1"

@export_group("Gun")
@export var bullet_scene: PackedScene
@export var bullet_damage: float = 25.0
@export var bullet_speed: float = 45.0
@export var shoot_range: float = 45.0
@export var shoot_cooldown: float = 1.2
@export var aim_height: float = 2.3
@export var spread_degrees: float = 2.0
@export var face_tolerance: float = 0.97
@export var require_line_of_sight: bool = true

@export_group("Gun Visual")
@export var shoot_animation: StringName = &""
@export var shoot_pose_time: float = 0.35
@export var muzzle_flash_time: float = 0.06
@export var gun_recoil_distance: float = 0.35

@export_group("Ad System")
@export var ad_scenes: Array[PackedScene]
@export var max_hits_for_ad: int = 2
@export var delay_before_change_scene: float = 3.0
@export var result_hold_time: float = 2.0
@export var next_scene: PackedScene

# ใช้ตัวนับเดียวกับ banana_man.gd
const BananaManScript = preload("res://scripts/banana_man.gd")

@onready var detection_area: Area3D = $DetectionArea
@onready var punch_hitbox: Area3D = $punch
@onready var animation_player: AnimationPlayer = $"Fast Run/AnimationPlayer"
@onready var muzzle: Marker3D = $Muzzle
@onready var muzzle_flash: Node3D = $Muzzle/Flash
@onready var gun_mesh: Node3D = $Gun

var health: float
var player: CharacterBody3D = null

var attack_timer: float = 0.0
var punch_timer: float = 0.0
var shoot_timer: float = 0.0
var pose_timer: float = 0.0
var flash_timer: float = 0.0

var is_attacking: bool = false
var is_dead: bool = false
var has_hit_this_punch: bool = false

var health_bar: Node3D = null
var gun_rest_position: Vector3


func _ready() -> void:
	health = max_health
	gun_rest_position = gun_mesh.position
	muzzle_flash.visible = false

	shoot_timer = shoot_cooldown * 0.5

	if show_health_bar:
		create_health_bar()

	detection_area.body_entered.connect(
		_on_detection_area_body_entered
	)
	detection_area.body_exited.connect(
		_on_detection_area_body_exited
	)
	animation_player.animation_finished.connect(
		_on_animation_finished
	)

	play_animation(idle_animation)
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	attack_timer = maxf(attack_timer - delta, 0.0)
	shoot_timer = maxf(shoot_timer - delta, 0.0)
	pose_timer = maxf(pose_timer - delta, 0.0)

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			muzzle_flash.visible = false

	gun_mesh.position = gun_mesh.position.lerp(
		gun_rest_position,
		minf(15.0 * delta, 1.0)
	)

	if is_attacking:
		velocity.x = 0.0
		velocity.z = 0.0

		punch_timer += delta
		if punch_timer >= punch_hit_time:
			punch_hit()

		move_and_slide()
		return

	if is_instance_valid(player):
		chase_player(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		play_animation(idle_animation)

	move_and_slide()


# =====================================
# MOVEMENT AND COMBAT
# =====================================

func chase_player(delta: float) -> void:
	var to_player: Vector3 = (
		player.global_position - global_position
	)
	to_player.y = 0.0

	var distance: float = to_player.length()

	if distance <= 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var direction: Vector3 = to_player / distance

	var target_angle: float = atan2(
		direction.x,
		direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		minf(8.0 * delta, 1.0)
	)

	# ระยะประชิด: ใช้ระบบต่อย
	if distance <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0

		if attack_timer <= 0.0:
			start_punch()
		else:
			play_animation(idle_animation)

		return

	var can_shoot_here: bool = (
		distance <= shoot_range
		and (
			not require_line_of_sight
			or has_line_of_sight()
		)
	)

	if can_shoot_here:
		velocity.x = 0.0
		velocity.z = 0.0
		play_animation(idle_animation)

		var facing: float = (
			global_transform.basis.z.dot(direction)
		)

		if shoot_timer <= 0.0 and facing >= face_tolerance:
			shoot()
	else:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		play_animation(run_animation)


func start_punch() -> void:
	if is_dead or is_attacking:
		return

	if not animation_player.has_animation(punch_animation):
		push_warning(
			"Punch animation not found: " + str(punch_animation)
		)
		return

	is_attacking = true
	has_hit_this_punch = false
	punch_timer = 0.0
	attack_timer = attack_cooldown

	animation_player.play(punch_animation)
	print("Gun Banana Man attacking!")


func punch_hit() -> void:
	if is_dead or not is_attacking:
		return

	if has_hit_this_punch:
		return

	has_hit_this_punch = true

	for body in punch_hitbox.get_overlapping_bodies():
		if not body.is_in_group("Player"):
			continue

		var was_dead: bool = body.get("is_dead") == true

		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			print("Gun Banana Man hit Player!")

		if not was_dead and body.get("is_dead") == true:
			on_player_killed()

		break


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name != punch_animation:
		return

	is_attacking = false
	has_hit_this_punch = false
	punch_timer = 0.0

	if not is_dead:
		play_animation(idle_animation)


func play_animation(anim_name: StringName) -> void:
	if is_dead or is_attacking:
		return

	# ป้องกัน idle/run ทับท่ายิง
	if pose_timer > 0.0:
		return

	if not animation_player.has_animation(anim_name):
		return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)


# =====================================
# GUN SYSTEM
# =====================================

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

	var hit: Dictionary = (
		get_world_3d().direct_space_state.intersect_ray(query)
	)

	if hit.is_empty():
		return true

	var collider: Object = hit["collider"]

	return (
		collider is Node
		and (collider as Node).is_in_group("Player")
	)


func shoot() -> void:
	if is_dead or bullet_scene == null:
		return

	if not is_instance_valid(player):
		return

	shoot_timer = shoot_cooldown

	var origin: Vector3 = muzzle.global_position
	var dir: Vector3 = (
		get_aim_point() - origin
	).normalized()

	var spread: float = tan(deg_to_rad(spread_degrees))

	dir = (
		dir
		+ Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * spread
	).normalized()

	var bullet: Node3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = origin

	# bullet.gd ควรรองรับ launch(dir, shooter, damage, speed)
	bullet.launch(dir, self, bullet_damage, bullet_speed)

	muzzle_flash.visible = true
	flash_timer = muzzle_flash_time

	gun_mesh.position = (
		gun_rest_position
		+ Vector3(0.0, 0.0, -gun_recoil_distance)
	)

	if (
		shoot_animation != &""
		and animation_player.has_animation(shoot_animation)
	):
		pose_timer = shoot_pose_time
		animation_player.play(shoot_animation)


# =====================================
# HEALTH SYSTEM
# =====================================

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)

	print("Gun Banana Man HP: ", health)

	if health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	velocity = Vector3.ZERO

	died.emit()
	animation_player.stop()

	print("Gun Banana Man died!")
	queue_free()


func create_health_bar() -> void:
	health_bar = Node3D.new()
	health_bar.set_script(
		preload("res://scripts/enemy_health_bar.gd")
	)
	health_bar.position = Vector3(
		0.0,
		health_bar_height,
		0.0
	)

	add_child(health_bar)
	health_changed.connect(health_bar.update_health)


# =====================================
# PLAYER DETECTION
# =====================================

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body is CharacterBody3D:
		player = body


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null


# =====================================
# AD SYSTEM
# =====================================

func on_player_killed() -> void:
	# ใช้ตัวนับเดียวกับ Banana Man ตัวปกติ
	BananaManScript.hit_counter += 1

	print(
		"Gun Banana Man: Player deaths = ",
		BananaManScript.hit_counter
	)

	_trigger_result()


func _pick_target() -> PackedScene:
	if BananaManScript.hit_counter >= maxi(max_hits_for_ad, 1):
		BananaManScript.hit_counter = 0

		if not ad_scenes.is_empty():
			print("สุ่มโฆษณาจาก Gun Banana Man")
			return ad_scenes.pick_random()

		push_warning(
			"ครบจำนวนครั้งแล้ว แต่ยังไม่ได้ตั้งค่า Ad Scenes"
		)

	return next_scene


func _trigger_result() -> void:
	var result_control: Node = (
		get_tree().get_first_node_in_group("result_screen")
	)

	if result_control == null:
		push_warning(
			"ไม่พบ Result ในกลุ่ม result_screen"
		)
		return

	if not result_control.has_method("trigger_death"):
		push_warning(
			"Result ไม่มีฟังก์ชัน trigger_death()"
		)
		return

	var target: PackedScene = _pick_target()

	result_control.trigger_death(
		delay_before_change_scene,
		result_hold_time,
		target
	)
