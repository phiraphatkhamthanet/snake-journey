extends Node3D
## กระสุนของศัตรู: บินตรงด้วยความเร็วคงที่ + ยิง ray ตรวจชนทุกเฟรม (กันกระสุนทะลุกำแพงบาง)

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

	# หันหัวกระสุน (-Z) ไปตามทิศที่บิน
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

	# ลองได้สูงสุด 4 ครั้ง เผื่อทะลุศัตรูตัวอื่น
	for i in 4:
		var query := PhysicsRayQueryParameters3D.create(
			from, to, hit_mask
		)
		query.exclude = exclude

		var hit: Dictionary = space.intersect_ray(query)

		if hit.is_empty():
			break

		var collider: Object = hit["collider"]

		if collider is Node and (collider as Node).is_in_group("Player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			_impact(hit["position"])
			return

		# ศัตรูตัวอื่น (CharacterBody3D ที่ไม่ใช่ Player) ให้กระสุนทะลุผ่าน
		if collider is CharacterBody3D:
			exclude.append((collider as CollisionObject3D).get_rid())
			continue

		# ชนกำแพง/พื้น
		_impact(hit["position"])
		return

	global_position = to


func _impact(pos: Vector3) -> void:
	hit_done = true
	global_position = pos
	queue_free()
