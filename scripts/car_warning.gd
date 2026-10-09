extends CanvasLayer
## ระบบเตือน "รถกำลังมา": ลูกศรที่ขอบจอชี้ไปทางที่รถจะมา พร้อมข้อความเตือน
## v2: คิดจากความเร็วสัมพัทธ์ระหว่างรถกับงู (งูเคลื่อนที่/กระโดดก็ยังเตือนได้) และกันกะพริบหาย
## วิธีใช้: CanvasLayer ในซีน World, แนบสคริปต์นี้, ลากตัวผู้เล่นใส่ช่อง Player

@export var player: Node3D
@export_category("Warning Settings")
@export var warn_ttc: float = 3.0          # เตือนเมื่อรถจะเข้าใกล้งูที่สุดในไม่เกินกี่วินาที
@export var danger_ttc: float = 1.5        # ต่ำกว่านี้ = ระดับอันตราย
@export var hit_radius: float = 5.0        # รถจะเฉียดงูใกล้กว่ากี่เมตรถึงนับว่าอาจชน (ปรับให้ใกล้เคียง Area3D ของรถ)
@export var grace_time: float = 0.35       # คงลูกศรไว้อีกกี่วินาทีหลังเงื่อนไขหลุด (กันกะพริบ)
@export_category("Look")
@export var edge_margin: float = 90.0
@export var warning_text: String = "⚠ ระวังรถ!"
@export var danger_text: String = "⚠ รถมาแล้ว!!"
@export var warn_color: Color = Color(1.0, 0.8, 0.1)
@export var danger_color: Color = Color(1.0, 0.15, 0.1)
@export var font_size: int = 28
@export_category("Debug")
@export var debug_print: bool = false      # เปิดเพื่อดูใน Output ว่าทำไมรถแต่ละคันถึงเตือน/ไม่เตือน

var _indicators: Dictionary = {}   # car -> Indicator
var _last_seen: Dictionary = {}    # car -> เวลาที่เงื่อนไขเตือนเป็นจริงล่าสุด
var _last_ttc: Dictionary = {}
var _bone: Node3D
var _time: float = 0.0
var _last_pos: Vector3
var _has_last: bool = false
var _player_vel: Vector3 = Vector3.ZERO
var _reason: String = ""
var _dbg_timer: float = 0.0


class Indicator extends Control:
	var color: Color = Color.YELLOW
	var angle: float = 0.0
	var label: Label

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		label = Label.new()
		label.size = Vector2(260, 40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 8)
		add_child(label)

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, angle)
		var pts := PackedVector2Array([
			Vector2(34, 0), Vector2(-6, -30), Vector2(-6, -12),
			Vector2(-30, -12), Vector2(-30, 12), Vector2(-6, 12), Vector2(-6, 30)
		])
		draw_colored_polygon(pts, color)
		draw_polyline(PackedVector2Array(pts + PackedVector2Array([pts[0]])), Color.BLACK, 3.0)


## วัดความเร็วจริงของงู (ตำแหน่งที่เปลี่ยนต่อวินาที) ไม่ว่าจะเคลื่อนด้วยวิธีไหน
func _physics_process(delta: float) -> void:
	var t := _get_player_node()
	if t == null:
		return
	var pos := t.global_position
	if _has_last and delta > 0.0:
		_player_vel = _player_vel.lerp((pos - _last_pos) / delta, 0.25)
	_last_pos = pos
	_has_last = true


func _process(delta: float) -> void:
	_time += delta
	_dbg_timer += delta
	var target := _get_player_node()
	var cam := get_viewport().get_camera_3d()
	if target == null or cam == null:
		if debug_print and _dbg_timer > 1.0:
			_dbg_timer = 0.0
			print("[car_warning] ไม่มี player หรือ camera (player=", player, ", cam=", cam, ")")
		_clear_all()
		return

	var do_dbg := debug_print and _dbg_timer > 0.5
	if do_dbg:
		_dbg_timer = 0.0
		print("[car_warning] cars=", get_tree().get_nodes_in_group("cars").size(),
			" player_vel=", _player_vel.snapped(Vector3.ONE * 0.1))

	for car in get_tree().get_nodes_in_group("cars"):
		if not is_instance_valid(car) or not car is Node3D:
			continue
		var ttc := _predict(car, target.global_position)
		if do_dbg:
			print("  ", car.name, " ttc=", snappedf(ttc, 0.01), " ", _reason)
		if ttc >= 0.0:
			_last_seen[car] = _time
			_last_ttc[car] = ttc
			_update_indicator(car, ttc, cam)
		elif _indicators.has(car) and _time - float(_last_seen.get(car, -99.0)) < grace_time:
			_update_indicator(car, float(_last_ttc.get(car, warn_ttc)), cam)

	# เก็บกวาด: รถที่หายไป หรือเลยช่วง grace แล้ว
	for car in _indicators.keys():
		if not is_instance_valid(car) or _time - float(_last_seen.get(car, -99.0)) >= grace_time:
			_remove_indicator(car)


## เวลา (วินาที) ที่รถจะเข้าใกล้งูที่สุด ถ้าจะเฉียดในรัศมี hit_radius; ไม่เข้าเงื่อนไขคืน -1
## คิดบนระนาบ XZ (ไม่สนความสูง เพราะงูกระโดดได้) และใช้ความเร็วสัมพัทธ์ของรถกับงู
func _predict(car: Node3D, target_pos: Vector3) -> float:
	if car.get("is_hit"):
		return _no("ชนไปแล้ว")
	if not car.has_method("get_world_velocity"):
		return _no("car.gd ยังไม่มี get_world_velocity()")
	var rel_pos: Vector3 = car.global_position - target_pos
	rel_pos.y = 0.0
	var rel_vel: Vector3 = car.get_world_velocity() - _player_vel
	rel_vel.y = 0.0
	var v2 := rel_vel.length_squared()
	if v2 < 0.01:
		return _no("ความเร็วสัมพัทธ์ ~0")
	var t := -rel_pos.dot(rel_vel) / v2
	if t <= 0.0:
		return _no("รถผ่านจุดใกล้สุดไปแล้ว/วิ่งออกห่าง")
	if t > warn_ttc:
		return _no("ยังไกลเกินเวลาเตือน (t=%.2f)" % t)
	if car.has_method("get_remaining_time") and t > car.get_remaining_time():
		return _no("รถจะ respawn ก่อนถึงงู")
	var miss := (rel_pos + rel_vel * t).length()
	if miss > hit_radius:
		return _no("จะเฉียดห่าง %.1f m (> hit_radius)" % miss)
	_reason = "เตือน miss=%.1f m" % miss
	return t


func _no(reason: String) -> float:
	_reason = reason
	return -1.0


func _update_indicator(car: Node3D, ttc: float, cam: Camera3D) -> void:
	var ind: Indicator = _indicators.get(car)
	if ind == null:
		ind = Indicator.new()
		add_child(ind)
		_indicators[car] = ind

	var danger := ttc < danger_ttc
	var vp_size := get_viewport().get_visible_rect().size
	var center := vp_size * 0.5

	var sp := cam.unproject_position(car.global_position)
	if cam.is_position_behind(car.global_position):
		sp = vp_size - sp
	var d := sp - center
	if d.length() < 1.0:
		d = Vector2.LEFT
	var dir2 := d.normalized()

	var half := center - Vector2(edge_margin, edge_margin)
	var sx := half.x / absf(dir2.x) if absf(dir2.x) > 0.001 else INF
	var sy := half.y / absf(dir2.y) if absf(dir2.y) > 0.001 else INF
	var dist := minf(minf(sx, sy), d.length())
	ind.position = center + dir2 * dist

	var blink := 0.55 + 0.45 * sin(_time * (14.0 if danger else 7.0))
	var col := danger_color if danger else warn_color
	col.a = blink
	ind.color = col
	ind.angle = dir2.angle()

	ind.label.text = danger_text if danger else warning_text
	ind.label.add_theme_font_size_override("font_size", font_size)
	ind.label.add_theme_color_override("font_color", col)
	ind.label.position = -ind.label.size * 0.5 - dir2 * 75.0
	ind.queue_redraw()


func _remove_indicator(car) -> void:
	var ind: Indicator = _indicators.get(car)
	if ind and is_instance_valid(ind):
		ind.queue_free()
	_indicators.erase(car)
	_last_seen.erase(car)
	_last_ttc.erase(car)


func _clear_all() -> void:
	for car in _indicators.keys():
		_remove_indicator(car)


func _get_player_node() -> Node3D:
	if player == null:
		return null
	if _bone == null or not is_instance_valid(_bone):
		_bone = player.find_child("Physical Bone Body", true, false) as Node3D
	return _bone if _bone != null else player
