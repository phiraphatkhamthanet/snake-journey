extends Control

# เปลี่ยนจาก %VictoryLabel เป็น $VictoryLabel
@onready var victory_label: Label = $VictoryLabel

@export_category("back")
@export var next_scene: String = "res://scenes/Use_scenes/Menu.tscn"

func _ready() -> void:
	var time_played: float = ScoreManager.current_session_time
	
	if is_instance_valid(victory_label):
		victory_label.text = ScoreManager.get_troll_victory_message_en(time_played)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)
