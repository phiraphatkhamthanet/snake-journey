extends Node3D

@export_category("Start")
@export var next_scene: String = "res://scenes/Use_scenes/Seclect_level.tscn"

@export_category("Credit")
@export var scenes2: PackedScene

@onready var label: Label = $CanvasLayer/Control/Label

var can_click: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# อัปเดตข้อความ High Score จาก ScoreManager
	update_high_score_ui()
	
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	can_click = true

func update_high_score_ui() -> void:
	if label:
		var time_str := ScoreManager.get_formatted_story_time()
		var endless_score := ScoreManager.high_score_endless
		
		label.text = "Your High Score\nStory Time: " + time_str + "\nEndless Chunks: " + str(endless_score)


func _on_button_pressed() -> void:
		get_tree().change_scene_to_file(next_scene)


func _on_button_2_pressed() -> void:
	if scenes2:
		get_tree().change_scene_to_packed(scenes2)


func _on_button_3_pressed() -> void:
	get_tree().quit()
