extends Marker3D

@export var car: PackedScene
@export var rand:float = 3.0
@export var destroy_time:float = 5.0
@export var direction:Vector3 = Vector3.ZERO

var seed = randf()*rand
var despawn_time = 0.0
var time = randf()*2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time > 2.0 + seed:
		var new_car = car.instantiate()
		new_car.destroy_time = destroy_time
		new_car.moving = direction
		add_child(new_car)
		time = 0
		seed = randf()*rand
	else:
		time += delta
	pass
