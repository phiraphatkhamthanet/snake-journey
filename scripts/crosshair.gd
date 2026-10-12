
extends Control

@export var crosshair_color: Color = Color.GREEN
@export var crosshair_size: float = 10.0
@export var crosshair_gap: float = 6.0
@export var crosshair_thickness: float = 2.0
@export var center_dot: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center = size / 2.0
	var gap = crosshair_gap
	var length = crosshair_size
	var thickness = crosshair_thickness

	# Top
	draw_line(
		center + Vector2(0, -gap),
		center + Vector2(0, -gap - length),
		crosshair_color,
		thickness
	)

	# Bottom
	draw_line(
		center + Vector2(0, gap),
		center + Vector2(0, gap + length),
		crosshair_color,
		thickness
	)

	# Left
	draw_line(
		center + Vector2(-gap, 0),
		center + Vector2(-gap - length, 0),
		crosshair_color,
		thickness
	)

	# Right
	draw_line(
		center + Vector2(gap, 0),
		center + Vector2(gap + length, 0),
		crosshair_color,
		thickness
	)

	if center_dot:
		draw_circle(center, thickness, crosshair_color)
