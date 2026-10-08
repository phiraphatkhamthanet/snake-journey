extends Control

@onready var victory_label: Label = $VictoryLabel

@export_category("back")
@export var next_scene: String = "res://scenes/Use_scenes/Menu.tscn"

var _triggered: bool = false
var _pending_target: PackedScene = null  # ซีนที่รอไป (โฆษณา/next_scene)
var _time_at_death: float = -1.0  # เวลาตอนชน (วินาที) -1 = ยังไม่มี


func _ready() -> void:
	add_to_group("result_screen")
	# ซ่อนทั้งหน้า Result ไว้ก่อนจนกว่าจะตาย
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.hide()


## เรียกจากรถ/วัวตอนชนผู้เล่น: รอ delay → โชว์ Result ทับเกม → ค้าง hold_time → ไป target (ถ้ามี)
func trigger_death(delay: float, hold_time: float, target: PackedScene) -> void:
	if _triggered:
		return
	_triggered = true

	# บันทึกเวลา ณ ตอนชน แล้วหยุดจับเวลา
	var gen := get_tree().get_first_node_in_group("world_generator")
	if gen and "elapsed_time" in gen:
		_time_at_death = gen.elapsed_time
		gen.stop_timer()

	await get_tree().create_timer(delay).timeout
	show_result()

	if target == null:
		return
	_pending_target = target
	await get_tree().create_timer(hold_time).timeout
	_go_pending()


func _go_pending() -> void:
	if _pending_target == null:
		return
	var t := _pending_target
	_pending_target = null
	get_tree().change_scene_to_packed(t)


func show_result() -> void:
	var time_played: float = _time_at_death if _time_at_death >= 0.0 else ScoreManager.current_session_time
	print("[Result] time_played = ", time_played)
	if is_instance_valid(victory_label):
		victory_label.text = ScoreManager.get_result(time_played)

	var layer := get_parent()
	if layer is CanvasLayer:
		layer.show()
	show()


func _on_menu_button_pressed() -> void:
	# ถ้ายังมีโฆษณารออยู่ ให้ข้ามการนับถอยหลังไปโฆษณาทันที (กันโฆษณาหายตอนกด Menu เร็ว)
	if _pending_target != null:
		_go_pending()
		return
	get_tree().change_scene_to_file(next_scene)
