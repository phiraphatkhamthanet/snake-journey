extends Node3D

# ---------- VARIABLES ---------- #

# ควบคุมความไวของเมาส์
@export var mouse_sensitivity := 0.2

# อ้างอิง Node กล้อง (ตรวจสอบให้แน่ใจว่าในหน้า Scene ชื่อ Camera3D ตรงกัน)
@onready var camera: Camera3D = $Camera3D

# ---------- FUNCTIONS ---------- #

func _ready():
	# เอา top_level = true ออก เพื่อให้กล้องเคลื่อนที่ตามตำแหน่งของตัวละครหลัก
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ระบบควบคุมการหมุนกล้อง
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# หมุนกล้องขึ้น-ลง (แกน X)
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		# จำกัดมุมก้มเงย (ก้มได้สูงสุด -60 องศา, เงยได้สูงสุด 60 องศา)
		rotation_degrees.x = clamp(rotation_degrees.x, -60, 60)
		
		# หมุนกล้องซ้าย-ขวา (แกน Y)
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)
		
	# กด Esc เพื่อคืนสิทธิ์เมาส์
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# คลิกซ้ายที่หน้าจอเกมเพื่อจับเมาส์กลับมาควบคุมกล้องใหม่
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
