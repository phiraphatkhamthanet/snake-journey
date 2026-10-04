extends Node3D

@export_category("story")
@export var scenes1: PackedScene

@export_category("endless")
@export var scenes2: PackedScene

@export_category("back")
@export var next_scene: String = "res://scenes/Use_scenes/Menu.tscn"

func _ready() -> void:
	# คืนค่าให้เมาส์แสดงผลและขยับ/คลิกได้ตามปกติ
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_button_pressed() -> void:
	if scenes1:
		get_tree().change_scene_to_packed(scenes1)


func _on_button_2_pressed() -> void:
	if scenes2:
		get_tree().change_scene_to_packed(scenes2)


func _on_button_3_pressed() -> void:
		get_tree().change_scene_to_file(next_scene)
