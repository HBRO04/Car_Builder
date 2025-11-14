extends RigidBody2D
class_name car_show

var can_act: bool = false
@export var cooldown_time: float = 0.3

# Engine + drivetrain
var current_rpm: float = 800.0
var current_gear: int = 1
var wheel_radius: float = 0.3
var gear_ratios: Array = [3.5, 2.1, 1.4, 1.0, 0.8]
var final_drive: float = 3.5
var max_rpm: float = 7000.0
var min_rpm: float = 800.0
var throttle_input: float = 0.0
var speed: float = 0.0
var displayed_speed: float = 0.0
var shifting: bool = false

# Physics properties
var drag_coefficient: float = 0.3
var rolling_resistance: float = 10.0

# UI references
var throttle_lbl: Label = null
var speedlbl: Label = null
var rev_bar: TextureProgressBar = null

# CurrentCar instance
var current_car

func _ready() -> void:
	# Initialize CurrentCar
	current_car = CurrentCar
	if current_car:
		current_car.get_data()
		set_data()
	
	# Setup
	find_ui_elements()
	set_can_act(false)
	show_correct_body()
	set_weight()
	setup_physics_properties()
	update_rev_bar(0)
	
	# Debug
	print_car_info()
	
	update_ui(displayed_speed)

func find_ui_elements():
	# Look for UI elements in common paths
	var paths_to_try = [
		"CanvasLayer/lblthrottle",
		"CanvasLayer/lblSpeed", 
		"CanvasLayer/TextureProgressBar",
		"../../CanvasLayer/lblthrottle",
		"../../CanvasLayer/lblSpeed",
		"../../CanvasLayer/TextureProgressBar"
	]
	
	for path in paths_to_try:
		var node = get_node_or_null(path)
		if node:
			if "lblthrottle" in path and node is Label:
				throttle_lbl = node
			elif "lblSpeed" in path and node is Label:
				speedlbl = node
			elif "TextureProgressBar" in path and node is TextureProgressBar:
				rev_bar = node

func setup_physics_properties():
	gravity_scale = 1.0
	linear_damp = 0.0
	angular_damp = 0.5
	can_sleep = false
	freeze = false
	lock_rotation = false

func set_data():
	if not current_car:
		return
	
	var torque_params = current_car.get_torque_curve_parameters()
	max_rpm = torque_params["redline"]
	gear_ratios = current_car.gear_ratios.duplicate() if current_car.gear_ratios else [3.5, 2.1, 1.4, 1.0, 0.8]
	final_drive = current_car.final_drive
	
	var wheel_radius_inches = current_car.wheelraduis if current_car.wheelraduis > 0 else 15.0
	wheel_radius = wheel_radius_inches * 0.0254
	
	# Ensure gear ratios are in correct order (highest to lowest)
	if gear_ratios.size() > 1:
		gear_ratios.sort()
		gear_ratios.reverse()

func show_correct_body():
	if not current_car:
		return
	$body/body1.visible = current_car.choosenBody == 1
	$body/body2.visible = current_car.choosenBody == 2

func set_weight():
	if current_car:
		mass = max(100.0, current_car.totalWeight)
	else:
		mass = 1200.0

func print_car_info():
	print("=== CAR SETUP ===")
	print("Mass: ", mass, " kg")
	print("Gear ratios: ", gear_ratios)
	print("Final drive: ", final_drive)
	print("Wheel radius: ", wheel_radius, " m")
	print("Max RPM: ", max_rpm)

func _physics_process(delta: float) -> void:
	if !can_act:
		return

	# Input handling
	handle_input(delta)
	
	# Gear shifting
	handle_gear_shifting()
	
	# RPM calculation
	update_rpm(delta)
	
	# Apply driving forces
	apply_driving_forces(delta)
	
	# Apply resistance
	apply_resistance_forces()
	
	# Update speed and UI
	update_speed_and_ui(delta)

func handle_input(delta: float):
	var is_throttle_pressed = Input.is_action_pressed("throttle")
	var target_throttle = 1.0 if is_throttle_pressed else 0.0
	throttle_input = lerp(throttle_input, target_throttle, delta * 8.0)

func handle_gear_shifting():
	if shifting:
		return
		
	if Input.is_action_just_pressed("gear_up") and current_gear < gear_ratios.size():
		current_gear += 1
		start_shift_effect()
		print("Shifted UP to gear ", current_gear)
	elif Input.is_action_just_pressed("gear_down") and current_gear > 1:
		current_gear -= 1
		start_shift_effect()
		print("Shifted DOWN to gear ", current_gear)

func update_rpm(delta: float):
	if shifting:
		current_rpm = lerp(current_rpm, min_rpm + 1500, delta * 8.0)
		return
	
	var wheel_rpm = calculate_wheel_rpm_from_speed()
	var gear_ratio = gear_ratios[current_gear - 1] if current_gear <= gear_ratios.size() else 1.0
	var calculated_rpm = wheel_rpm * gear_ratio * final_drive
	
	if throttle_input > 0.1:
		# Target higher RPM when accelerating
		var target_rpm = max(calculated_rpm, min_rpm + 2000)
		current_rpm = lerp(current_rpm, target_rpm, delta * 6.0)
	else:
		# Engine braking when not accelerating
		current_rpm = lerp(current_rpm, max(calculated_rpm, min_rpm), delta * 3.0)
	
	current_rpm = clamp(current_rpm, min_rpm, max_rpm)

func apply_driving_forces(delta: float):
	if throttle_input < 0.05:
		return
	
	var current_gear_ratio = gear_ratios[current_gear - 1] if current_gear <= gear_ratios.size() else 1.0
	
	# Get engine torque (use CurrentCar if available, otherwise estimate)
	var engine_torque = 0.0
	if current_car:
		engine_torque = current_car.get_torque_at_rpm(current_rpm) * throttle_input
	else:
		# Fallback torque calculation (typical sports car curve)
		var peak_torque_rpm = max_rpm * 0.6
		var torque_factor = 1.0
		if current_rpm < peak_torque_rpm:
			torque_factor = current_rpm / peak_torque_rpm
		else:
			torque_factor = 1.0 - (current_rpm - peak_torque_rpm) / (max_rpm - peak_torque_rpm) * 0.5
		engine_torque = 400.0 * torque_factor * throttle_input
	
	# Calculate drive force - MASSIVELY INCREASED
	var wheel_torque = engine_torque * current_gear_ratio * final_drive
	var drive_force = wheel_torque / wheel_radius
	
	# HUGE force multiplier - this is the key fix
	drive_force *= 800.0  # Increased from 25.0 to 800.0
	
	# Apply force
	var forward_direction = Vector2.RIGHT
	apply_central_force(forward_direction * drive_force)
	
	# Debug output frequently until moving
	if linear_velocity.length() < 5.0:
		print("DRIVE FORCE: %.0f N | RPM: %d | Gear: %d | Speed: %.1f m/s" % [
			drive_force, int(current_rpm), current_gear, linear_velocity.x
		])
	elif Engine.get_physics_frames() % 60 == 0:
		var current_speed_kmh = abs(linear_velocity.x) * 3.6
		print("Gear %d | Speed: %d km/h | RPM: %d | Force: %.0f N" % [
			current_gear, int(current_speed_kmh), int(current_rpm), drive_force
		])

func apply_resistance_forces():
	var horizontal_velocity = linear_velocity.x
	var speed_magnitude = abs(horizontal_velocity)
	
	if speed_magnitude < 0.01:
		return
	
	var direction = sign(horizontal_velocity)
	
	# Air resistance (increases with speed^2)
	var drag_force = drag_coefficient * speed_magnitude * speed_magnitude
	
	# Rolling resistance (increases with speed)
	var rolling_force = rolling_resistance * speed_magnitude
	
	# Engine braking when no throttle
	if throttle_input < 0.05:
		rolling_force *= 2.0
	
	var total_resistance = Vector2(-direction * (drag_force + rolling_force), 0)
	apply_central_force(total_resistance)

func update_speed_and_ui(delta: float):
	var actual_speed = abs(linear_velocity.x)
	var actual_speed_kmh = actual_speed * 3.6
	
	displayed_speed = lerp(displayed_speed, actual_speed_kmh, delta * 6.0)
	displayed_speed = clamp(displayed_speed, 0.0, 400.0)
	speed = actual_speed
	
	update_ui(displayed_speed)

func calculate_wheel_rpm_from_speed() -> float:
	var actual_speed = abs(linear_velocity.x)
	if actual_speed < 0.1:
		return 0.0
	
	var circumference = 2.0 * PI * wheel_radius
	var wheel_rpm = (actual_speed / circumference) * 60.0
	return wheel_rpm

func update_ui(speed_kmh: float):
	if throttle_lbl:
		throttle_lbl.text = "Throttle: %d%% | Gear: %d/%d | RPM: %d" % [
			int(throttle_input * 100), 
			current_gear, 
			gear_ratios.size(),
			int(current_rpm)
		]
	
	if speedlbl:
		speedlbl.text = "Speed: %d km/h" % int(speed_kmh)
	
	update_rev_bar(current_rpm)

func update_rev_bar(rpm_val: float):
	if rev_bar == null:
		return
	
	var ratio = clamp(rpm_val / max_rpm, 0.0, 1.0)
	rev_bar.value = ratio * 100.0
	
	# Color coding
	if ratio < 0.6:
		rev_bar.tint_progress = Color(0.2, 1.0, 0.2)  # Green
	elif ratio < 0.8:
		rev_bar.tint_progress = Color(1.0, 1.0, 0.2)  # Yellow
	else:
		rev_bar.tint_progress = Color(1.0, 0.2, 0.2)  # Red

func start_shift_effect():
	shifting = true
	current_rpm = max(min_rpm + 1200, current_rpm * 0.7)  # RPM drop on shift
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func(): shifting = false)

func set_can_act(new_value: bool):
	can_act = new_value

func set_can_act_false():
	can_act = false

func _on_animation_player_animation_finished(anim_name: StringName):
	can_act = true

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Debug boost - MASSIVELY INCREASED
				apply_central_impulse(Vector2.RIGHT * 50000)
				print("MASSIVE Debug boost applied!")
			KEY_R:
				# Reset car
				linear_velocity = Vector2.ZERO
				angular_velocity = 0
				current_gear = 1
				current_rpm = min_rpm
				position = Vector2(100, 100)
				print("Car reset!")
