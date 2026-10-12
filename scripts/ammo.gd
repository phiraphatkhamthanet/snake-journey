
extends Area3D

@export_group("Ammo Pickup")
@export var ammo_amount: int = 15

@export_group("Visual")
@export var rotate_speed: float = 90.0
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.0

@onready var mesh: MeshInstance3D = $"Root Scene/RootNode/Pickup_Bullets"
@onready var pickup_sound: AudioStreamPlayer = $pickup

var start_height: float = 0.0
var elapsed_time: float = 0.0
var collected: bool = false


func _ready() -> void:
	start_height = mesh.position.y

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return

	mesh.rotate_y(deg_to_rad(rotate_speed) * delta)

	elapsed_time += delta

	mesh.position.y = (
		start_height
		+ sin(elapsed_time * bob_speed) * bob_height
	)


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return

	if not body.has_method("add_ammo"):
		return

	# ไม่เก็บเมื่อกระสุนเต็ม
	if body.get("ammo") >= body.get("max_ammo"):
		return

	collected = true

	# เพิ่มกระสุนให้ Player
	body.add_ammo(ammo_amount)

	# ซ่อนของและปิด Collision
	visible = false
	monitoring = false
	set_deferred("monitorable", false)

	# เล่นเสียงก่อนลบ Pickup
	if pickup_sound.stream != null:
		pickup_sound.play()
		await pickup_sound.finished

	queue_free()
