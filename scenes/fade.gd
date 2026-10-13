extends CanvasLayer
@onready var rect = $Panel
@export var startup:bool = true

func _ready() -> void:
	
	if startup:
		await get_tree().create_timer(1.0).timeout
		animate_circle()
		await get_tree().create_timer(1.0).timeout
		visible = false
	else:
		rect.material.set_shader_parameter("circle_size", 1.05)

func animate_circle() -> void:
	var mat := rect.material as ShaderMaterial

	var tween = create_tween()
	tween.tween_method(
		func(value: float):
			mat.set_shader_parameter("circle_size", value),0.0,1.05,1.0)

func reverse_circle() -> void:
	var mat := rect.material as ShaderMaterial

	var tween = create_tween()
	tween.tween_method(
		func(value: float):mat.set_shader_parameter("circle_size", value),1.05,0.0,1.0)
