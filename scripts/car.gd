extends Node3D

@export var despawn_time:float = 2
var destroy_time = 0

var moving:Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	despawn_time += delta
	if despawn_time > destroy_time:
		queue_free()
		return
	position += moving
	pass
