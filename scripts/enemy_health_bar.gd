extends Node3D
## แถบ HP ลอยเหนือหัวศัตรู หันหาจอเสมอ (billboard) สร้างด้วยโค้ดล้วน

@export var bar_width: float = 3.0
@export var bar_height: float = 0.35
@export var border: float = 0.08
@export var high_color: Color = Color(0.25, 0.9, 0.3)
@export var mid_color: Color = Color(1.0, 0.7, 0.1)
@export var low_color: Color = Color(0.95, 0.15, 0.15)

var fill_mesh: QuadMesh
var fill_material: StandardMaterial3D


func _ready() -> void:
	# พื้นหลัง/ขอบ
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width + border * 2.0, bar_height + border * 2.0)
	add_child(_make_quad(bg_mesh, Color(0.05, 0.05, 0.05, 1.0), 0))

	# แถบเลือด
	fill_mesh = QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	fill_material = _make_material(high_color, 1)
	var fill := MeshInstance3D.new()
	fill.mesh = fill_mesh
	fill.material_override = fill_material
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fill)


func _make_material(color: Color, priority: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = color
	mat.render_priority = priority
	# ลอยเห็นแม้มีของบังเล็กน้อย
	mat.no_depth_test = true
	return mat


func _make_quad(mesh: QuadMesh, color: Color, priority: int) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = _make_material(color, priority)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


func update_health(current: float, maximum: float) -> void:
	if fill_mesh == null:
		return

	var ratio: float = clampf(current / maxf(maximum, 0.001), 0.0, 1.0)

	# ย่อแถบเข้าทางซ้าย (center_offset อยู่ในพิกัดของ mesh จึงหมุนตาม billboard)
	var w: float = maxf(bar_width * ratio, 0.001)
	fill_mesh.size = Vector2(w, bar_height)
	fill_mesh.center_offset = Vector3(-(bar_width - w) * 0.5, 0.0, 0.0)

	if ratio > 0.5:
		fill_material.albedo_color = high_color
	elif ratio > 0.25:
		fill_material.albedo_color = mid_color
	else:
		fill_material.albedo_color = low_color
