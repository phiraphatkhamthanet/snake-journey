extends CharacterBody3D

@export var attack_speed := 8.0
@export var attack_delay := 0.7

@onready var attack_area: Area3D = $AttackArea
@onready var attack_indicator: MeshInstance3D = $AttackIndicator

var player: Node3D
var is_attacking := false


func _ready() -> void:
	attack_area.body_entered.connect(_on_attack_area_body_entered)


func _physics_process(delta: float) -> void:

	# ผู้เล่นหาย/ตายแล้ว -> หยุดพุ่ง
	if is_attacking and (not is_instance_valid(player) or _player_is_dead()):
		is_attacking = false
		player = null

	if is_attacking and player:
		var direction := global_position.direction_to(player.global_position)

		# ไม่ให้วัวลอย/จม
		direction.y = 0

		velocity = direction.normalized() * attack_speed

		move_and_slide()

	else:
		velocity = Vector3.ZERO


func _on_attack_area_body_entered(body: Node3D) -> void:

	if is_attacking:
		return

	# ตรวจจับผู้เล่น: PhysicalBone3D (งูเดิม) หรือ player.tscn (CharacterBody3D กลุ่ม "Player")
	var is_fps_player: bool = body is CharacterBody3D and body.is_in_group("Player")
	if is_fps_player and body.get("is_dead"):
		return
	if body is PhysicalBone3D or is_fps_player:
		player = body

		#AudioManager.cowattack_sfx.play()

		# รอก่อนพุ่ง
		await get_tree().create_timer(attack_delay).timeout

		# เริ่มโจมตี
		attack_indicator.hide()
		is_attacking = true


func _player_is_dead() -> bool:
	return player != null and player.get("is_dead") == true
