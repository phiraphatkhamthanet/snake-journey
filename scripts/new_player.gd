
extends CharacterBody3D

signal ammo_changed(current: int)
signal health_changed(current: float, maximum: float)
signal died

@export_group("Movement")
@export var move_speed: float = 10.0
@export var jump_velocity: float = 5.0
## กด Shift ค้างเพื่อวิ่ง: ความเร็วคูณค่านี้
@export var sprint_multiplier: float = 1.6
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8

@export_group("Third Person (ตอนใช้สกิล)")
## ตำแหน่งกล้อง TPS เทียบกับ Head (x=ขวา, y=สูง, z=ถอยหลัง)
@export var tps_camera_offset: Vector3 = Vector3(1.8, 0.8, 9.0)
## ความสูงจุดหมุนกล้องใน TPS (ประมาณระดับสายตา)
@export var tps_head_height: float = 4.24
## ความเร็วสลับมุมมอง (1/วินาที) ยิ่งมากยิ่งเร็ว
@export var tps_transition_speed: float = 5.0
## ไม่ให้กล้อง TPS ทะลุกำแพงด้านหลัง
@export var tps_camera_collision: bool = true

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Knockback (โดนรถ/สัตว์ชน)")
## คูณแรงกระแทกจากรถ/สัตว์ (ที่ส่งมาเป็น impulse ใหญ่ ๆ) ให้เป็นความเร็วของผู้เล่น
@export var knockback_scale: float = 0.3
@export var knockback_max_up: float = 7.0
## ยิ่งมากยิ่งหยุดกระเด็นเร็ว (1/วินาที)
@export var knockback_decay: float = 6.0

@export_group("Death / Result")
## ตายแล้วรอกี่วินาทีก่อนโชว์หน้า Result (ใช้เมื่อตายจากกล้วย/กระสุน; รถและสัตว์ใช้ค่าของตัวเอง)
@export var death_result_delay: float = 1.5
@export var death_result_hold: float = 2.0
## ซีนที่จะไปต่อหลังหน้า Result (ว่าง = ค้างที่ Result ให้กดปุ่ม Menu)
@export var death_next_scene: PackedScene

@export_group("Weapon")
@export var damage: float = 20.0
@export var fire_rate: float = 0.15
@export var automatic: bool = false

@export_group("Ammo")
@export var starting_ammo: int = 30
@export var max_ammo: int = 150

@export_group("Weapon Sounds")
@export var empty_sound_cooldown: float = 0.3

@export_group("Recoil")
@export var recoil_strength: float = 0.045
@export var recoil_rotation: float = 8.0
@export var recoil_recovery: float = 12.0
@export var camera_recoil: float = 2.0

@export_group("Muzzle Flash")
@export var muzzle_flash_duration: float = 0.06

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var weapon_holder: Node3D = $Head/Camera3D/weapon_holder
@onready var model: Node3D = $Sketchfab_Scene

@onready var muzzle_flash: GPUParticles3D = $Head/Camera3D/weapon_holder/gun/flash
@onready var muzzle_light: OmniLight3D = $Head/Camera3D/weapon_holder/gun/flash/OmniLight3D

@onready var ammo_label: Label = $UI/AmmoLabel
@onready var ui_layer: CanvasLayer = $UI

@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var empty_sound: AudioStreamPlayer = $EmptySound

# NEW: เสียงเมื่อได้รับ Damage
@onready var hurt_sound: AudioStreamPlayer = $hurt

var health: float = 100.0
var ammo: int = 0
var is_dead: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO

var shoot_timer: float = 0.0
var empty_sound_timer: float = 0.0
var muzzle_flash_timer: float = 0.0

var weapon_start_position: Vector3
var weapon_start_rotation: Vector3

var fps_camera_position: Vector3
var fps_head_y: float = 0.0
var fps_cull_mask: int = 0
var tps_active: bool = false
var tps_blend: float = 0.0

var camera_recoil_offset: float = 0.0
var camera_recoil_target: float = 0.0
var look_pitch: float = 0.0


func _ready() -> void:
	add_to_group("Player")

	setup_sprint_input()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	weapon_start_position = weapon_holder.position
	weapon_start_rotation = weapon_holder.rotation
	look_pitch = head.rotation.x

	muzzle_flash.emitting = false
	muzzle_light.visible = false

	set_model_layer(model)

	health = max_health
	ammo = clampi(starting_ammo, 0, max_ammo)

	# HP บนหน้าจอ
	var hp_hud: Control = preload("res://scripts/player_hp_hud.gd").new()
	ui_layer.add_child(hp_hud)
	hp_hud.bind(self)

	# TPS: จำค่ากล้อง FPS ไว้ แล้วฟังสัญญาณสกิล
	fps_camera_position = camera.position
	fps_head_y = head.position.y
	fps_cull_mask = camera.cull_mask
	raycast.add_exception(self)
	TimeSlow.slow_changed.connect(_on_skill_changed)
	set_tps(TimeSlow.is_slowing, true)

	update_ammo_ui()

	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)

			look_pitch -= event.relative.y * mouse_sensitivity
			look_pitch = clampf(
				look_pitch,
				deg_to_rad(-89),
				deg_to_rad(89)
			)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	update_camera_view(delta)


# =========================
# FPS <-> TPS (ตามสกิล Time Slow)
# =========================
func _on_skill_changed(active: bool) -> void:
	set_tps(active)


func set_tps(enabled: bool, instant: bool = false) -> void:
	tps_active = enabled

	if instant:
		tps_blend = 1.0 if enabled else 0.0
		update_camera_view(0.0)


func update_camera_view(delta: float) -> void:
	# ใช้เวลาจริง ไม่ให้ช้าตาม Time Slow
	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	var target: float = 1.0 if tps_active else 0.0

	tps_blend = move_toward(
		tps_blend, target, tps_transition_speed * real_delta
	)

	var t: float = smoothstep(0.0, 1.0, tps_blend)

	head.position.y = lerpf(fps_head_y, tps_head_height, t)
	camera.position = fps_camera_position.lerp(tps_camera_offset, t)

	# เห็นตัวผู้เล่นเมื่อออกจาก FPS / ซ่อนปืนที่ติดหน้ากล้อง
	var show_body: bool = tps_blend > 0.25
	camera.cull_mask = fps_cull_mask | 2 if show_body else fps_cull_mask
	weapon_holder.visible = not show_body

	if t > 0.0 and tps_camera_collision:
		push_camera_out_of_walls()


func push_camera_out_of_walls() -> void:
	var pivot: Vector3 = head.global_position
	var wanted: Vector3 = camera.global_position

	var query := PhysicsRayQueryParameters3D.create(pivot, wanted, 1)
	query.exclude = [get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(
		query
	)

	if not hit.is_empty():
		var back: Vector3 = (pivot - hit["position"]).normalized()
		camera.global_position = hit["position"] + back * 0.4


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var time_factor: float = 1.0 / maxf(
		Engine.time_scale, 0.001
	)
	var real_delta: float = delta * time_factor

	if not is_on_floor():
		velocity.y -= gravity * delta * time_factor * time_factor

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity * time_factor

	var input_dir := Input.get_vector(
		"left", "right", "forward", "back"
	)

	var direction := (
		transform.basis * Vector3(
			input_dir.x, 0, input_dir.y
		)
	).normalized()

	# แรงกระเด็นจากรถ/สัตว์ ค่อย ๆ ลดลงตามเวลาจริง
	knockback_velocity.x *= exp(-knockback_decay * real_delta)
	knockback_velocity.z *= exp(-knockback_decay * real_delta)

	var current_speed: float = move_speed
	if is_sprinting(input_dir):
		current_speed *= sprint_multiplier

	velocity.x = (
		direction.x * current_speed + knockback_velocity.x
	) * time_factor
	velocity.z = (
		direction.z * current_speed + knockback_velocity.z
	) * time_factor

	move_and_slide()

	shoot_timer = maxf(shoot_timer - real_delta, 0.0)
	empty_sound_timer = maxf(
		empty_sound_timer - real_delta, 0.0
	)

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if automatic:
			if Input.is_action_pressed("shoot"):
				shoot()
		else:
			if Input.is_action_just_pressed("shoot"):
				shoot()

	recover_recoil(real_delta)
	update_muzzle_flash(real_delta)


func shoot() -> void:
	if is_dead or shoot_timer > 0.0:
		return

	if ammo <= 0:
		play_empty_sound()
		return

	shoot_timer = fire_rate

	ammo -= 1
	update_ammo_ui()
	ammo_changed.emit(ammo)

	play_shoot_sound()
	apply_recoil()
	play_muzzle_flash()

	raycast.force_raycast_update()

	if raycast.is_colliding():
		var target = raycast.get_collider()
		var hit_position = raycast.get_collision_point()

		print("Hit: ", target.name)
		print("Position: ", hit_position)

		if target.has_method("take_damage"):
			target.take_damage(damage)


# =========================
# Receive Damage + Hurt Sound
# =========================
func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	var previous_health: float = health

	health = maxf(health - amount, 0.0)

	if health < previous_health:
		play_hurt_sound()

	health_changed.emit(health, max_health)

	print("Player HP: ", health, "/", max_health)

	if health <= 0.0:
		die()


# =========================
# NEW: Hurt Sound
# =========================
func play_hurt_sound() -> void:
	if hurt_sound.stream == null:
		return
	hurt_sound.stop()
	hurt_sound.play()


# =========================
# Sprint (กด Shift ค้างเพื่อวิ่ง)
# =========================
# สร้าง action "sprint" (Shift) ให้อัตโนมัติถ้ายังไม่มีใน Input Map
# อยากเปลี่ยนปุ่ม: ไปเพิ่ม action ชื่อ sprint ที่ Project Settings > Input Map
func setup_sprint_input() -> void:
	if InputMap.has_action("sprint"):
		return

	InputMap.add_action("sprint")

	var shift := InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	InputMap.action_add_event("sprint", shift)


func is_sprinting(input_dir: Vector2) -> bool:
	return (
		Input.is_action_pressed("sprint")
		and input_dir.length() > 0.1
	)


## ถูกเรียกจากรถ/สัตว์ (car.gd, Kill.gd) ตอนชนผู้เล่น
func apply_knockback(impulse: Vector3) -> void:
	if is_dead:
		return

	var push: Vector3 = impulse * knockback_scale
	knockback_velocity.x = push.x
	knockback_velocity.z = push.z

	var time_factor: float = 1.0 / maxf(Engine.time_scale, 0.001)
	velocity.y = minf(push.y, knockback_max_up) * time_factor


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO

	# ตายแล้วกลับเป็นเวลาปกติ/มุมมอง FPS
	TimeSlow.stop_slow()

	died.emit()

	# รถ/สัตว์จะเรียก Result ของตัวเองก่อน (ในเฟรมเดียวกัน) ถ้าไม่มีใครเรียก ค่อยใช้ค่าของผู้เล่น
	call_deferred("_show_death_result")

	# ไม่โชว์เมาส์ตรงนี้: ถ้ามี Result จะเป็นคนโชว์เองเมื่อไม่มีโฆษณาตามมา
	# (กันเมาส์โผล่ก่อนโฆษณาในการตายครั้งที่ต้องขึ้นโฆษณา)

	print("Player died!")


func _show_death_result() -> void:
	var result: Node = get_tree().get_first_node_in_group("result_screen")
	if result and result.has_method("trigger_death"):
		result.trigger_death(
			death_result_delay, death_result_hold, death_next_scene
		)
	else:
		# ไม่มีหน้า Result ในฉากนี้ (เช่น test_scene) -> โชว์เมาส์เลย
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func add_health(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	health = minf(health + amount, max_health)

	health_changed.emit(health, max_health)

	print("Player HP: ", health, "/", max_health)


var drunk_effect: CanvasLayer = null


# น้ำยาเมา: จอบิดและสีวนเป็นเวลา seconds วินาที (เรียกซ้ำ = เริ่มนับใหม่)
func apply_drunk(seconds: float) -> void:
	if is_dead or seconds <= 0.0:
		return

	if drunk_effect == null:
		drunk_effect = preload("res://scripts/drunk_effect.gd").new()
		add_child(drunk_effect)

	drunk_effect.start(seconds)


func add_ammo(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	ammo = mini(ammo + amount, max_ammo)

	update_ammo_ui()
	ammo_changed.emit(ammo)

	print("Ammo: ", ammo, "/", max_ammo)


func update_ammo_ui() -> void:
	if ammo_label:
		ammo_label.text = "%d/%d" % [ammo, max_ammo]


func play_shoot_sound() -> void:
	if shoot_sound.stream == null:
		return

	shoot_sound.stop()
	shoot_sound.play()


func play_empty_sound() -> void:
	if empty_sound_timer > 0.0:
		return

	empty_sound_timer = empty_sound_cooldown

	if empty_sound.stream == null:
		return

	empty_sound.stop()
	empty_sound.play()


func apply_recoil() -> void:
	weapon_holder.position.z += recoil_strength
	weapon_holder.rotation.x += deg_to_rad(recoil_rotation)

	camera_recoil_target += deg_to_rad(camera_recoil)


func recover_recoil(delta: float) -> void:
	var weight := minf(recoil_recovery * delta, 1.0)

	weapon_holder.position = weapon_holder.position.lerp(
		weapon_start_position, weight
	)

	weapon_holder.rotation = weapon_holder.rotation.lerp(
		weapon_start_rotation, weight
	)

	camera_recoil_offset = lerpf(
		camera_recoil_offset,
		camera_recoil_target,
		weight
	)

	camera_recoil_target = lerpf(
		camera_recoil_target,
		0.0,
		weight
	)

	head.rotation.x = clampf(
		look_pitch + camera_recoil_offset,
		deg_to_rad(-89),
		deg_to_rad(89)
	)


func play_muzzle_flash() -> void:
	muzzle_flash.restart()
	muzzle_light.visible = true
	muzzle_flash_timer = muzzle_flash_duration


func update_muzzle_flash(delta: float) -> void:
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta

	if muzzle_flash_timer <= 0.0:
		muzzle_light.visible = false


func set_model_layer(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = 2

	for child in node.get_children():
		set_model_layer(child)
