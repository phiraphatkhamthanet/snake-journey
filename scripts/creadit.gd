extends Node3D
@export_category("back")
@export var next_scene: String = "res://scenes/Use_scenes/Menu.tscn"
@onready var sprite_iq: Sprite2D = $Iq
@onready var sprite_p: Sprite2D = $P
@onready var sprite_pp: Sprite2D = $PangPond
@onready var sprite_thanya: Sprite2D = $Thanya

@onready var sprite_iq2: Sprite2D = $IQ_name/Iq2
@onready var sprite_p2: Sprite2D = $P_name/P2
@onready var sprite_pp2: Sprite2D = $PangPond_name/PangPond2
@onready var sprite_thanya2: Sprite2D = $Thanya_name/Thanya2

func _ready() -> void:
	make_wiggle(sprite_iq, 0.0)
	make_wiggle(sprite_p, 0.2)
	make_wiggle(sprite_pp, 0.4)
	make_wiggle(sprite_thanya, 0.6)
	make_wiggle(sprite_iq2, 0.0)
	make_wiggle(sprite_p2, 0.2)
	make_wiggle(sprite_pp2, 0.4)
	make_wiggle(sprite_thanya2, 0.6)
	$Thanya_name/Back4.disabled = true
	$PangPond_name/Back3.disabled = true
	$IQ_name/Back2.disabled = true
	$P_name/Back5.disabled = true

func make_wiggle(sprite: Sprite2D, delay: float) -> void:
	if not is_instance_valid(sprite):
		print("หา Sprite ไม่เจอ!")
		return

	var orig_scale = sprite.scale
	
	# สร้าง Tween ทันที แล้ววนลูปไม่มีที่สิ้นสุด (0 = infinite loop)
	var tween = create_tween().set_loops()
	
	# ถ้ามี delay ให้สั่งให้อยู่เฉยๆ ก่อนเริ่มลูปครั้งแรก
	if delay > 0:
		tween.tween_interval(delay)

	# --- จังหวะที่ 1: ยืดตัว + หมุนขวา ---
	tween.tween_property(sprite, "scale", orig_scale * Vector2(0.95, 1.08), 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation_degrees", 5.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	# --- จังหวะที่ 2: ย่อตัว + หมุนซ้าย ---
	tween.tween_property(sprite, "scale", orig_scale * Vector2(1.08, 0.95), 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation_degrees", -5.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	# --- จังหวะที่ 3: กลับสู่ท่าเดิม ---
	tween.tween_property(sprite, "scale", orig_scale, 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_SINE)


func _on_thanyaa_pressed() -> void:
	$Thanya_name.visible = true
	$Thanya_name/Back4.disabled = false


func _on_pond_pressed() -> void:
	$PangPond_name.visible = true
	$PangPond_name/Back3.disabled = false


func _on_pera_pressed() -> void:
	$P_name.visible = true
	$P_name/Back5.disabled = false


func _on_iq_pressed() -> void:
	$IQ_name.visible = true
	$IQ_name/Back2.disabled = false


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)



#Big pic
func _on_back_2_pressed() -> void:
	$IQ_name.visible = false
	$IQ_name/Back2.disabled = true


func _on_back_3_pressed() -> void:
	$PangPond_name.visible = false
	$PangPond_name/Back3.disabled = true


func _on_back_4_pressed() -> void:
	$Thanya_name.visible = false
	$Thanya_name/Back4.disabled = true


func _on_back_5_pressed() -> void:
	$P_name.visible = false
	$P_name/Back5.disabled = true
