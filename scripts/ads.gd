extends Node3D

@export_category("back")
@export var next_scene: String = "res://scenes/Use_scenes/Menu.tscn"

@export_category("Time out")
@export var time: int = 10 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer/Control.visible = false
	
	await get_tree().create_timer(time).timeout
	$CanvasLayer/Control.visible = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)
