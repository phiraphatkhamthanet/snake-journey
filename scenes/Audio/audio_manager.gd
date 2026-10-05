extends Node

# ---------- VARIABLES ---------- #

# References (ตรวจสอบชื่อโหนดใน Scene ให้ตรงกับหลังเครื่องหมาย $ ทุกตัว)
@onready var alien_sfx = get_node_or_null("Alien")
@onready var carmel_sfx = get_node_or_null("Camel")
@onready var monkey_sfx = get_node_or_null("Monkey")
@onready var honk_sfx = get_node_or_null("CarHonk")
@onready var elephant_sfx = get_node_or_null("Elephant")
@onready var tiger_sfx = get_node_or_null("Tiger")
@onready var horse_sfx = get_node_or_null("Horse")


# ฟังก์ชันสำหรับเรียกเล่นเสียงอย่างปลอดภัย
func play_sound(sound_name: String) -> void:
	if sound_name.is_empty():
		return
		
	# ดึงโหนดตามชื่อตัวแปรหรือชื่อโหนด
	var sfx_node = get(sound_name)
	if not sfx_node:
		sfx_node = get_node_or_null(sound_name)
		
	if sfx_node and sfx_node.has_method("play"):
		sfx_node.play()
	else:
		print("เตือน: ไม่พบโหนดเสียงชื่อ ", sound_name, " ใน AudioManager")
