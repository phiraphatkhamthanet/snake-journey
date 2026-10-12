
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

@export_group("Animations")
@export var idle_animation: StringName = &"Melee-Library--OLD/Idle"
@export var run_animation: StringName = &"Melee-Library--OLD/run"
@export var punch_animation: StringName = &"Melee-Library--OLD/SlashATK1"

@onready var detection_area: Area3D = $DetectionArea
@onready var punch_hitbox: Area3D = $punch
@onready var animation_player: AnimationPlayer = $"Fast Run/AnimationPlayer"

var health: float
var player: CharacterBody3D = null

var attack_timer: float = 0.0
var punch_timer: float = 0.0
var is_attacking: bool = false
var is_dead: bool = false
var has_hit_this_punch: bool = false


func _ready() -> void:
	health = max_health

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

	var direction: Vector3 = to_player.normalized()

	var target_angle: float = atan2(
		direction.x,
		direction.z
	)

	rotation.y = lerp_angle(
		rotation.y,
		target_angle,
		minf(8.0 * delta, 1.0)
	)

	if distance > attack_range:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		play_animation(run_animation)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

		if attack_timer <= 0.0:
			start_punch()
		else:
			play_animation(idle_animation)


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

	print("Banana Man attacking!")


func punch_hit() -> void:
	if is_dead or not is_attacking:
		return

	if has_hit_this_punch:
		return

	has_hit_this_punch = true

	for body in punch_hitbox.get_overlapping_bodies():
		if body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(attack_damage)
				print("Banana Man hit Player!")
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

	if not animation_player.has_animation(anim_name):
		return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)

	print("Banana Man HP: ", health)

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

	print("Banana Man died!")
	queue_free()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if body is CharacterBody3D:
			player = body


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
