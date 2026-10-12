
extends Node

signal energy_changed(current: float, maximum: float)
signal slow_changed(active: bool)

# =========================
# Time Slow Settings
# =========================
@export_group("Time Slow")

@export_range(0.05, 1.0, 0.05)
var slow_scale: float = 0.25

@export var max_energy: float = 100.0

# ใช้พลังงาน 25 หน่วยต่อวินาที
@export var drain_rate: float = 25.0

# ฟื้นฟู 10 หน่วยต่อวินาที
@export var recharge_rate: float = 10.0

# =========================
# Variables
# =========================
var energy: float = 100.0
var is_slowing: bool = false


# =========================
# Ready
# =========================
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	energy = max_energy
	Engine.time_scale = 1.0

	energy_changed.emit(energy, max_energy)


# =========================
# Input
# =========================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("time_slow") and not event.is_echo():
		if is_slowing:
			stop_slow()
		elif energy > 0.0:
			start_slow()

		get_viewport().set_input_as_handled()


# =========================
# Update Energy
# =========================
func _process(delta: float) -> void:
	# เวลาจริง ไม่ได้รับผลจาก Time Slow
	var real_delta: float = delta / maxf(
		Engine.time_scale, 0.001
	)

	if is_slowing:
		energy = maxf(
			energy - drain_rate * real_delta,
			0.0
		)

		if energy <= 0.0:
			stop_slow()
	else:
		energy = minf(
			energy + recharge_rate * real_delta,
			max_energy
		)

	# อัปเดตหลอดพลังงาน
	energy_changed.emit(energy, max_energy)


# =========================
# Start Slow Motion
# =========================
func start_slow() -> void:
	if energy <= 0.0 or is_slowing:
		return

	is_slowing = true
	Engine.time_scale = slow_scale

	slow_changed.emit(true)


# =========================
# Stop Slow Motion
# =========================
func stop_slow() -> void:
	if not is_slowing:
		return

	is_slowing = false
	Engine.time_scale = 1.0

	slow_changed.emit(false)


# =========================
# Cleanup
# =========================
func _exit_tree() -> void:
	Engine.time_scale = 1.0
