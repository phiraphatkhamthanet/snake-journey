
extends ProgressBar

# =========================
# Bar Settings
# =========================
@export_group("Appearance")

@export var bar_width: float = 450.0
@export var bar_height: float = 20.0

@export var normal_color: Color = Color.CYAN
@export var low_color: Color = Color.RED
@export var low_energy_threshold: float = 25.0

# =========================
# Variables
# =========================
var fill_style: StyleBoxFlat


# =========================
# Ready
# =========================
func _ready() -> void:
	show_percentage = false

	custom_minimum_size = Vector2(
		bar_width,
		bar_height
	)

	min_value = 0.0
	max_value = TimeSlow.max_energy
	value = TimeSlow.energy

	# Create fill style
	fill_style = StyleBoxFlat.new()
	fill_style.bg_color = normal_color

	add_theme_stylebox_override("fill", fill_style)

	# Connect signal
	TimeSlow.energy_changed.connect(update_energy)

	update_energy(TimeSlow.energy, TimeSlow.max_energy)


# =========================
# Update Energy
# =========================
func update_energy(current: float, maximum: float) -> void:
	max_value = maximum
	value = current

	# Change color when energy is low
	if maximum > 0.0 and current / maximum <= low_energy_threshold / 100.0:
		fill_style.bg_color = low_color
	else:
		fill_style.bg_color = normal_color
