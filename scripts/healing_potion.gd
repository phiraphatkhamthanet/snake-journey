extends "res://scripts/potion_pickup.gd"

@export_group("Healing Potion")
@export var heal_amount: float = 30.0


func _can_use(body: Node3D) -> bool:
	if not body.has_method("add_health"):
		return false

	# ไม่เก็บเมื่อเลือดเต็ม (ขวดจะรอไว้ให้เก็บทีหลัง)
	return body.get("health") < body.get("max_health")


func _use(body: Node3D) -> void:
	body.add_health(heal_amount)
