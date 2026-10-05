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

	# ตรวจจับ PhysicalBone3D
	if body is PhysicalBone3D:
		player = body

		#AudioManager.cowattack_sfx.play()

		# รอก่อนพุ่ง
		await get_tree().create_timer(attack_delay).timeout

		# เริ่มโจมตี
		attack_indicator.hide()
		is_attacking = true
