extends Node2D

@export_category("story")
@export var scenes1: PackedScene

@export var times: float
@export var play: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"AnimationPlayer".play(play)
	await get_tree().create_timer(times).timeout
	_skip()
	pass # Replace with function body.

func _skip():
	if scenes1:
		$"fade".reverse_circle()
		$"fade".visible = true
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_packed(scenes1)
		


func _on_button_pressed() -> void:
	_skip()
	pass # Replace with function body.
