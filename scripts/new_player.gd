
extends CharacterBody3D

signal ammo_changed(current: int)

# =========================
# Movement
# =========================
@export_group("Movement")
@export var move_speed: float = 10.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8

# =========================
# Weapon
# =========================
@export_group("Weapon")
@export var damage: float = 20.0
@export var fire_rate: float = 0.15
@export var automatic: bool = false

# =========================
# Ammo
# =========================
@export_group("Ammo")
@export var starting_ammo: int = 30
@export var max_ammo: int = 150

var ammo: int = 0

# =========================
# Weapon Sounds
# =========================
@export_group("Weapon Sounds")
@export var empty_sound_cooldown: float = 0.3

# =========================
# Recoil
# =========================
@export_group("Recoil")
@export var recoil_strength: float = 0.045
@export var recoil_rotation: float = 8.0
@export var recoil_recovery: float = 12.0
@export var camera_recoil: float = 2.0

# =========================
# Muzzle Flash
# =========================
@export_group("Muzzle Flash")
@export var muzzle_flash_duration: float = 0.06

# =========================
# Nodes
# =========================
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

@onready var weapon_holder: Node3D = $Head/Camera3D/weapon_holder
@onready var model: Node3D = $Sketchfab_Scene

@onready var muzzle_flash: GPUParticles3D = $Head/Camera3D/weapon_holder/gun/flash

@onready var muzzle_light: OmniLight3D = $Head/Camera3D/weapon_holder/gun/flash/OmniLight3D

@onready var ammo_label: Label = $UI/AmmoLabel

# Audio Nodes
@onready var shoot_sound: AudioStreamPlayer = $ShootSound
@onready var empty_sound: AudioStreamPlayer = $EmptySound

# =========================
# Variables
# =========================
var shoot_timer: float = 0.0
var empty_sound_timer: float = 0.0
var muzzle_flash_timer: float = 0.0

var weapon_start_position: Vector3
var weapon_start_rotation: Vector3

var camera_recoil_offset: float = 0.0
var camera_recoil_target: float = 0.0
var look_pitch: float = 0.0


# =========================
# Ready
# =========================
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	weapon_start_position = weapon_holder.position
	weapon_start_rotation = weapon_holder.rotation
	look_pitch = head.rotation.x

	muzzle_flash.emitting = false
	muzzle_light.visible = false

	set_model_layer(model)

	# Initialize Ammo
	ammo = clampi(starting_ammo, 0, max_ammo)
	update_ammo_ui()
	ammo_changed.emit(ammo)


# =========================
# Input
# =========================
func _unhandled_input(event: InputEvent) -> void:
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


# =========================
# Physics
# =========================
func _physics_process(delta: float) -> void:
	var time_factor: float = 1.0 / Engine.time_scale
	var real_delta: float = delta * time_factor

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta * time_factor * time_factor

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity * time_factor

	# Movement
	var input_dir := Input.get_vector(
		"left", "right", "forward", "back"
	)

	var direction := (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	velocity.x = direction.x * move_speed * time_factor
	velocity.z = direction.z * move_speed * time_factor

	move_and_slide()

	# Update cooldowns using real time
	shoot_timer = maxf(shoot_timer - real_delta, 0.0)

	empty_sound_timer = maxf(
		empty_sound_timer - real_delta,
		0.0
	)

	# Shooting
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if automatic:
			if Input.is_action_pressed("shoot"):
				shoot()
		else:
			if Input.is_action_just_pressed("shoot"):
				shoot()

	recover_recoil(real_delta)
	update_muzzle_flash(real_delta)


# =========================
# Shoot
# =========================
func shoot() -> void:
	# Check fire rate
	if shoot_timer > 0.0:
		return

	# No Ammo
	if ammo <= 0:
		play_empty_sound()
		return

	shoot_timer = fire_rate

	# Consume ammo
	ammo -= 1

	update_ammo_ui()
	ammo_changed.emit(ammo)

	# Gunshot sound
	play_shoot_sound()

	# Weapon effects
	apply_recoil()
	play_muzzle_flash()

	# Hitscan
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var target = raycast.get_collider()
		var hit_position = raycast.get_collision_point()

		print("Hit: ", target.name)
		print("Position: ", hit_position)

		if target.has_method("take_damage"):
			target.take_damage(damage)


# =========================
# Shoot Sound
# =========================
func play_shoot_sound() -> void:
	if shoot_sound.stream == null:
		return

	# Restart sound on every shot
	shoot_sound.stop()
	shoot_sound.play()


# =========================
# Empty Ammo Sound
# =========================
func play_empty_sound() -> void:
	if empty_sound_timer > 0.0:
		return

	empty_sound_timer = empty_sound_cooldown

	if empty_sound.stream == null:
		return

	empty_sound.stop()
	empty_sound.play()


# =========================
# Add Ammo
# =========================
func add_ammo(amount: int) -> void:
	if amount <= 0:
		return

	ammo = mini(ammo + amount, max_ammo)

	update_ammo_ui()
	ammo_changed.emit(ammo)

	print("Ammo: ", ammo, "/", max_ammo)


# =========================
# Update Ammo UI
# =========================
func update_ammo_ui() -> void:
	if ammo_label:
		ammo_label.text = str(ammo)


# =========================
# Recoil
# =========================
func apply_recoil() -> void:
	weapon_holder.position.z += recoil_strength

	weapon_holder.rotation.x += deg_to_rad(
		recoil_rotation
	)

	camera_recoil_target += deg_to_rad(
		camera_recoil
	)


func recover_recoil(delta: float) -> void:
	var weight := minf(recoil_recovery * delta, 1.0)

	weapon_holder.position = weapon_holder.position.lerp(
		weapon_start_position,
		weight
	)

	weapon_holder.rotation = weapon_holder.rotation.lerp(
		weapon_start_rotation,
		weight
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


# =========================
# Muzzle Flash
# =========================
func play_muzzle_flash() -> void:
	muzzle_flash.restart()

	muzzle_light.visible = true
	muzzle_flash_timer = muzzle_flash_duration


func update_muzzle_flash(delta: float) -> void:
	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta

	if muzzle_flash_timer <= 0.0:
		muzzle_light.visible = false


# =========================
# Model Layer
# =========================
func set_model_layer(node: Node) -> void:
	if node is VisualInstance3D:
		node.layers = 2

	for child in node.get_children():
		set_model_layer(child)
