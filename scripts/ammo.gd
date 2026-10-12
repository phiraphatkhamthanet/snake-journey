
extends Area3D

@export_group("Ammo Pickup")
@export var ammo_amount: int = 1

@export_group("Visual")
@export var rotate_speed: float = 90.0
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.0

@onready var mesh: MeshInstance3D = $"Root Scene/RootNode/Pickup_Bullets"

var start_height: float = 0.0
var elapsed_time: float = 0.0
var collected: bool = false


func _ready() -> void:
	start_height = mesh.position.y

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Spin pickup
	mesh.rotate_y(deg_to_rad(rotate_speed) * delta)

	# Floating animation
	elapsed_time += delta

	mesh.position.y = (
		start_height
		+ sin(elapsed_time * bob_speed) * bob_height
	)


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return

	if body.has_method("add_ammo"):
		collected = true

		body.add_ammo(ammo_amount)

		queue_free()
