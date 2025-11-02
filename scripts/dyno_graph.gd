# dyno_graph.gd
extends Control

@export var engine_script: Node2D  # Drag your EngineBuilder node here
@export var graph_margin: int = 24
@export var x_tick_count: int = 6
@export var y_tick_count: int = 6
@export var point_step_rpm: int = 250

@onready var torque_line: Line2D = $TorqueLine
@onready var power_line: Line2D = $PowerLine
@onready var background: ColorRect = $GraphBackground

func _ready():
	draw_graph()

func update_graph():
	draw_graph()

#func draw_graph():
	if engine_script == null:
		return

	torque_line.clear_points()
	power_line.clear_points()

	# Graph dimensions
	var width = background.size.x - 2 * graph_margin
	var height = background.size.y - 2 * graph_margin
	var x0 = graph_margin
	var y0 = background.size.y - graph_margin

	# RPM range
	var curve = engine_script.get_torque_curve_parameters()
	var redline = curve.get("redline", 6500)
	var rpm_points = []
	for rpm_val in range(0, redline + point_step_rpm, point_step_rpm):
		rpm_points.append(rpm_val)

	# Find max torque and power for scaling
	var max_torque = 0.0
	var max_power = 0.0
	for rpm_val in rpm_points:
		var t = engine_script.get_torque_at_rpm(rpm_val)
		var p = (t * rpm_val) / 9550.0
		max_torque = max(max_torque, t)
		max_power = max(max_power, p)

	max_torque = max(max_torque, 1)
	max_power = max(max_power, 1)

	# Add points to Line2D
	for rpm_val in rpm_points:
		var t = engine_script.get_torque_at_rpm(rpm_val)
		var p = (t * rpm_val) / 9550.0

		var x = x0 + (rpm_val / redline) * width
		var y_torque = y0 - (t / max_torque) * height
		var y_power = y0 - (p / max_power) * height

		torque_line.add_point(Vector2(x, y_torque))
		power_line.add_point(Vector2(x, y_power))

	# Draw axes ticks and labels
	draw_axes_ticks(width, height, x0, y0, redline, max_torque, max_power)

func draw_graph():
	if engine_script == null:
		return

	# Check that rpm and torque functions exist
	if not engine_script.has_method("get_torque_at_rpm") or not engine_script.has_method("get_torque_curve_parameters"):
		return

	torque_line.clear_points()
	power_line.clear_points()

	var width = background.size.x - 2 * graph_margin
	var height = background.size.y - 2 * graph_margin
	var x0 = graph_margin
	var y0 = background.size.y - graph_margin

	var curve = engine_script.get_torque_curve_parameters()
	var redline = curve.get("redline", 6500)
	var rpm_points = []
	for rpm_val in range(0, redline + point_step_rpm, point_step_rpm):
		rpm_points.append(rpm_val)

	var max_torque = 0.0
	var max_power = 0.0
	for rpm_val in rpm_points:
		var t = engine_script.get_torque_at_rpm(rpm_val)
		var p = (t * rpm_val) / 9550.0
		max_torque = max(max_torque, t)
		max_power = max(max_power, p)

	max_torque = max(max_torque, 1)
	max_power = max(max_power, 1)

	for rpm_val in rpm_points:
		var t = engine_script.get_torque_at_rpm(rpm_val)
		var p = (t * rpm_val) / 9550.0

		var x = x0 + (rpm_val / redline) * width
		var y_torque = y0 - (t / max_torque) * height
		var y_power = y0 - (p / max_power) * height

		torque_line.add_point(Vector2(x, y_torque))
		power_line.add_point(Vector2(x, y_power))

func draw_axes_ticks(width: float, height: float, x0: float, y0: float, max_rpm: float, max_torque: float, max_power: float) -> void:
	# Remove previous ticks/labels but keep lines
	for child in background.get_children():
		if child is not Line2D:
			child.queue_free()

	# X-axis ticks (RPM)
	for i in range(x_tick_count + 1):
		var x = x0 + (i / x_tick_count) * width
		var tick = ColorRect.new()
		tick.color = Color.WHITE
		tick.size = Vector2(1, 4)
		tick.position = Vector2(x, y0)
		background.add_child(tick)

		var label = Label.new()
		label.text = str(int(i / x_tick_count * max_rpm))
		label.position = Vector2(x - 15, y0 + 4)
		label.modulate = Color.WHITE
		background.add_child(label)

	# Y-axis ticks (Torque)
	for i in range(y_tick_count + 1):
		var y = y0 - (i / y_tick_count) * height
		var tick = ColorRect.new()
		tick.color = Color.WHITE
		tick.size = Vector2(4, 1)
		tick.position = Vector2(x0 - 4, y)
		background.add_child(tick)

		var label = Label.new()
		label.text = str(int(i / y_tick_count * max_torque))
		label.position = Vector2(0, y - 8)
		label.modulate = Color.WHITE
		background.add_child(label)
