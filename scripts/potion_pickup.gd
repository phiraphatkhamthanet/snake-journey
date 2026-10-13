extends Area3D
## สคริปต์พื้นฐานของไอเทมน้ำยา: หมุน + ลอย + เก็บเมื่อผู้เล่นชน
## ฉากลูกเขียนทับ _can_use() และ _use() เพื่อกำหนดผลของน้ำยา

@export_group("Visual")
@export var rotate_speed: float = 90.0
@export var bob_height: float = 0.25
@export var bob_speed: float = 2.0

@onready var visual: Node3D = $Visual
@onready var pickup_sound: AudioStreamPlayer = $pickup

var start_height: float = 0.0
var elapsed_time: float = 0.0
var collected: bool = false


func _ready() -> void:
	start_height = visual.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if collected:
		return

	visual.rotate_y(deg_to_rad(rotate_speed) * delta)

	elapsed_time += delta
	visual.position.y = start_height + sin(elapsed_time * bob_speed) * bob_height


# ลูกเขียนทับ: คืน true ถ้า body นี้เก็บน้ำยาได้
func _can_use(_body: Node3D) -> bool:
	return true


# ลูกเขียนทับ: ผลของน้ำยาเมื่อถูกเก็บ
func _use(_body: Node3D) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return

	if not _can_use(body):
		return

	collected = true

	_use(body)

	# ซ่อนของและปิด Collision
	visible = false
	monitoring = false
	set_deferred("monitorable", false)

	# เล่นเสียงก่อนลบ Pickup
	if pickup_sound.stream != null:
		pickup_sound.play()
		await pickup_sound.finished

	queue_free()
