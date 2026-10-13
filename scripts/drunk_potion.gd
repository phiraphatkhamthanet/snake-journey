extends "res://scripts/potion_pickup.gd"

@export_group("Drunk Potion")
@export var drunk_duration: float = 5.0
@export var rainbow_speed: float = 0.5

@onready var glow_light: OmniLight3D = $GlowLight

var liquid_material: StandardMaterial3D = null


func _ready() -> void:
	super()
	_setup_liquid()


func _process(delta: float) -> void:
	super(delta)

	# ของเหลวเปลี่ยนสีวนเป็นรุ้ง
	var color: Color = Color.from_hsv(fposmod(elapsed_time * rainbow_speed, 1.0), 0.75, 1.0)
	if liquid_material != null:
		liquid_material.albedo_color = color
		liquid_material.emission = color
	glow_light.light_color = color


func _can_use(body: Node3D) -> bool:
	return body.has_method("apply_drunk")


func _use(body: Node3D) -> void:
	body.apply_drunk(drunk_duration)


# หา material ชื่อ "Liquid" ในโมเดล แล้วทำสำเนาไว้เปลี่ยนสีเฉพาะขวดนี้
func _setup_liquid() -> void:
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var material: Material = mesh_instance.get_active_material(0)
		if material is StandardMaterial3D and material.resource_name == "Liquid":
			liquid_material = material.duplicate() as StandardMaterial3D
			liquid_material.emission_enabled = true
			mesh_instance.set_surface_override_material(0, liquid_material)
			return
