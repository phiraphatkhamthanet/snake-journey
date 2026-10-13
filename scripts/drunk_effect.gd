extends CanvasLayer
## เอฟเฟกต์จอเมา: ใช้ shader บิดภาพ/สีวน แล้วค่อย ๆ จางหาย
## เรียก start(วินาที) จากผู้เล่น (นับเวลาจริง ไม่โดน time slow)

const FADE_IN: float = 0.4
const FADE_OUT: float = 0.8

var rect: ColorRect
var shader_material: ShaderMaterial
var start_ms: int = 0
var duration: float = 0.0
var active: bool = false


func _ready() -> void:
	layer = 100

	shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scripts/drunk_screen.gdshader")

	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = shader_material
	add_child(rect)

	visible = false


func start(seconds: float) -> void:
	duration = seconds
	start_ms = Time.get_ticks_msec()
	active = true
	visible = true


func stop() -> void:
	active = false
	visible = false


func _process(_delta: float) -> void:
	if not active:
		return

	var elapsed: float = float(Time.get_ticks_msec() - start_ms) / 1000.0
	if elapsed >= duration:
		stop()
		return

	var fade: float = minf(
		clampf(elapsed / FADE_IN, 0.0, 1.0),
		clampf((duration - elapsed) / FADE_OUT, 0.0, 1.0)
	)
	shader_material.set_shader_parameter("intensity", fade)
	shader_material.set_shader_parameter("t", elapsed)
