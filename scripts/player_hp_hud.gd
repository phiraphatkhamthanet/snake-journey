extends Control
## แถบ HP ของผู้เล่นมุมซ้ายล่างของหน้าจอ (สร้างด้วยโค้ด ไม่ต้องแก้ player.tscn)

@export var bar_size: Vector2 = Vector2(320.0, 34.0)
@export var margin: Vector2 = Vector2(24.0, 24.0)
@export var high_color: Color = Color(0.25, 0.85, 0.3)
@export var mid_color: Color = Color(1.0, 0.65, 0.1)
@export var low_color: Color = Color(0.9, 0.15, 0.15)

var bar: ProgressBar
var skill_label: Label
var value_label: Label
var fill_style: StyleBoxFlat
var last_health: float = -1.0
var flash_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_right = 0.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = margin.x
	bar.offset_right = margin.x + bar_size.x
	bar.offset_bottom = -margin.y
	bar.offset_top = -margin.y - bar_size.y

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_corner_radius_all(4)
	bg.set_border_width_all(2)
	bg.border_color = Color(1.0, 1.0, 1.0, 0.8)
	bar.add_theme_stylebox_override("background", bg)

	fill_style = StyleBoxFlat.new()
	fill_style.bg_color = high_color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)

	add_child(bar)

	value_label = Label.new()
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.add_theme_color_override("font_outline_color", Color.BLACK)
	value_label.add_theme_constant_override("outline_size", 4)
	value_label.add_theme_font_size_override("font_size", 16)
	bar.add_child(value_label)

	create_skill_hint()


# ข้อความบอกปุ่มสกิลมุมขวาล่าง
func create_skill_hint() -> void:
	skill_label = Label.new()
	skill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skill_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	skill_label.anchor_left = 1.0
	skill_label.anchor_right = 1.0
	skill_label.anchor_top = 1.0
	skill_label.anchor_bottom = 1.0
	skill_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skill_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	skill_label.offset_right = -margin.x
	skill_label.offset_bottom = -margin.y
	skill_label.add_theme_font_size_override("font_size", 18)
	skill_label.add_theme_color_override("font_outline_color", Color.BLACK)
	skill_label.add_theme_constant_override("outline_size", 5)
	add_child(skill_label)

	TimeSlow.slow_changed.connect(_on_skill_changed)
	_on_skill_changed(TimeSlow.is_slowing)


func _on_skill_changed(active: bool) -> void:
	if active:
		skill_label.text = 'Skill active - Press "F" to cancel'
		skill_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		skill_label.text = 'Press "F" for activate skill'
		skill_label.add_theme_color_override("font_color", Color.WHITE)


func bind(player: Node) -> void:
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health, player.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	if bar == null:
		return

	bar.max_value = maximum
	bar.value = current
	value_label.text = "HP  %d / %d" % [ceili(current), ceili(maximum)]

	var ratio: float = current / maxf(maximum, 0.001)
	if ratio > 0.5:
		fill_style.bg_color = high_color
	elif ratio > 0.25:
		fill_style.bg_color = mid_color
	else:
		fill_style.bg_color = low_color

	# กะพริบแดงตอนโดนตี
	if last_health >= 0.0 and current < last_health:
		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		bar.modulate = Color(2.0, 0.5, 0.5)
		flash_tween = create_tween()
		flash_tween.set_ignore_time_scale(true)
		flash_tween.tween_property(bar, "modulate", Color.WHITE, 0.25)

	last_health = current
