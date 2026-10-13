
extends Node3D
## กระสุนของศัตรู:
## บินตรงด้วยความเร็วคงที่ + ใช้ Raycast ตรวจชน
## เมื่อยิงผู้เล่นตาย จะแจ้งผู้ยิงให้เรียกระบบโฆษณา

@export var speed: float = 45.0
@export var damage: float = 10.0
@export var lifetime: float = 4.0
@export var hit_mask: int = 0xFFFFFFFF

var direction: Vector3 = Vector3.FORWARD
var shooter: CollisionObject3D = null
var age: float = 0.0
var hit_done: bool = false


func launch(
	dir: Vector3,
	shooter_node: CollisionObject3D,
	dmg: float,
	bullet_speed: float
) -> void:
	direction = dir.normalized()
	shooter = shooter_node
	damage = dmg
	speed = bullet_speed

	# หันหัวกระสุน (-Z) ไปตามทิศทางที่บิน
	var up: Vector3 = Vector3.UP

	if absf(direction.dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT

	look_at(global_position + direction, up)


func _physics_process(delta: float) -> void:
	if hit_done:
		return

	age += delta

	if age >= lifetime:
		queue_free()
		return

	var from: Vector3 = global_position
	var to: Vector3 = from + direction * speed * delta

	var exclude: Array[RID] = []

	if is_instance_valid(shooter):
		exclude.append(shooter.get_rid())

	var space: PhysicsDirectSpaceState3D = (
		get_world_3d().direct_space_state
	)

	# ตรวจชนได้สูงสุด 4 ครั้ง
	for i in 4:
		var query := PhysicsRayQueryParameters3D.create(
			from,
			to,
			hit_mask
		)

		query.exclude = exclude

		var hit: Dictionary = space.intersect_ray(query)

		if hit.is_empty():
			break

		var collider: Object = hit["collider"]

		# ชนผู้เล่น
		if (
			collider is Node
			and (collider as Node).is_in_group("Player")
		):
			var player_node: Node = collider as Node

			var was_dead: bool = (
				player_node.get("is_dead") == true
			)

			# สร้างความเสียหาย
			if player_node.has_method("take_damage"):
				player_node.take_damage(damage)

			# ตรวจว่าผู้เล่นเพิ่งตายจากกระสุนนัดนี้หรือไม่
			var is_dead_now: bool = (
				is_instance_valid(player_node)
				and player_node.get("is_dead") == true
			)

			if not was_dead and is_dead_now:
				_notify_shooter_player_killed()

			_impact(hit["position"])
			return

		# ศัตรู CharacterBody3D ตัวอื่นให้กระสุนทะลุผ่าน
		if collider is CharacterBody3D:
			exclude.append(
				(collider as CollisionObject3D).get_rid()
			)
			continue

		# ชนกำแพงหรือพื้น
		_impact(hit["position"])
		return

	# ไม่ชนอะไร ให้เคลื่อนที่ต่อ
	global_position = to


func _notify_shooter_player_killed() -> void:
	if not is_instance_valid(shooter):
		return

	if shooter.has_method("on_player_killed"):
		shooter.on_player_killed()
		print("แจ้งผู้ยิงแล้ว: ผู้เล่นตายจากกระสุน")


func _impact(pos: Vector3) -> void:
	hit_done = true
	global_position = pos
	queue_free()
