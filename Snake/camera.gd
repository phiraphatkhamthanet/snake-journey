extends Node3D

# ---------- VARIABLES ---------- #

# Control Mouse Sensitivity through inspector or from here
@export var mouse_sensitivity := 0.2

# Assign Camera Node here it might be named different in your Project
@onready var camera: Camera3D = $Camera3D

# ---------- FUNCTIONS ---------- #

func _ready():
	top_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Handling Camera Movement
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -60, -0)
		
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)
		
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
