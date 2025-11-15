extends RigidBody2D

var can_act: bool = false
var race_finished: bool = false
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
var speed_ms: float = 0.0
var displayed_speed: float = 0.0
var shifting: bool = false

# Physics scale constants
const SPEED_SCALE: float = 0.098  # Converts physics velocity to km/h
const WHEEL_RPM_SCALE: float = 0.42  # Adjusted for proper gear speed progression

# AI shifting control
var shift_cooldown: float = 0.0
var shift_cooldown_time: float = 1  
var previous_speed: float = 0.0
var speed_check_timer: float = 0.0

# Physics properties for DRAG RACING
var drag_coefficient: float = 0.35
var rolling_resistance: float = 30.0
var traction_limit: float = 15000.0

# UI references
var throttle_lbl: Label = null
var speedlbl: Label = null
var rev_bar: TextureProgressBar = null

# Race tracking
var race_distance: float = 0.0
var race_time: float = 0.0
var race_active: bool = false
var race_start_time: float = 0.0

# CurrentCar instance
var current_car

@onready var track = $".."

func _ready() -> void:
	$CanvasLayer/Label.visible = false
	
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
	update_ui(displayed_speed)

func find_ui_elements():
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
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 5.0
	can_sleep = false
	freeze = false
	lock_rotation = true

func set_data():
	if not current_car:
		return
	
	var torque_params = current_car.get_torque_curve_parameters()
	max_rpm = torque_params["redline"]
	gear_ratios = current_car.gear_ratios.duplicate() if current_car.gear_ratios else [3.5, 2.1, 1.4, 1.0, 0.8]
	final_drive = current_car.final_drive
	
	var wheel_radius_inches = current_car.wheelraduis if current_car.wheelraduis > 0 else 13.0
	wheel_radius = wheel_radius_inches * 0.0254
	
	if gear_ratios.size() > 1:
		gear_ratios.sort()

func show_correct_body():
	if not current_car:
		return
	$body/body1.visible = current_car.choosenBody == 1
	$body/body2.visible = current_car.choosenBody == 2
	$body/body3.visible = current_car.choosenBody == 3

func set_weight():
	if current_car:
		mass = max(100.0, current_car.totalWeight)
	else:
		mass = 1200.0

func _physics_process(delta: float) -> void:
	if !can_act:
		return

	# Update race tracking
	if race_active and !race_finished:
		race_time = get_elapsed_race_time()

	# AI handles its own input
	handle_ai_input(delta)
	
	# AI gear shifting
	if !race_finished:
		handle_ai_gear_shifting(delta)
	
	# RPM calculation
	update_rpm(delta)
	
	# Apply driving forces
	if !race_finished:
		apply_driving_forces(delta)
	
	# Apply resistance forces
	apply_resistance_forces()
	
	# Update speed and UI
	update_speed_and_ui(delta)
	
	if race_finished:
		finish_race()

func get_elapsed_race_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - race_start_time

@warning_ignore("unused_parameter")
func handle_ai_input(delta: float):
	if race_finished:
		throttle_input = 0.0
		return
	
	# AI always floors it when racing
	if race_active:
		throttle_input = 1.0
	else:
		throttle_input = 0.0

func handle_ai_gear_shifting(delta: float):
	if shifting || race_finished:
		return
	
	# Update shift cooldown
	if shift_cooldown > 0:
		shift_cooldown -= delta
		return
	
	# Track speed changes for acceleration-based shifting
	speed_check_timer += delta
	
	# Check if we should shift based on multiple conditions
	var should_shift_up = false
	var should_shift_down = false
	
	# Method 1: Shift at high RPM (traditional method)
	if current_rpm > max_rpm * 0.88:
		should_shift_up = true
	
	# Method 2: Shift if acceleration is poor (speed plateauing)
	# Check every 0.5 seconds if speed gain is too low
	if speed_check_timer >= 0.5:
		var speed_gain = speed_ms - previous_speed
		var acceleration = speed_gain / 0.5  # m/s²
		
		# If acceleration is very low and we're not in top gear, shift up
		# This catches cases where RPM doesn't climb enough
		if acceleration < 2.0 && current_gear < gear_ratios.size() && speed_ms > 5.0:
			should_shift_up = true
			print("AI shifting up due to low acceleration: %.2f m/s²" % acceleration)
		
		previous_speed = speed_ms
		speed_check_timer = 0.0
	
	# Method 3: Force shift based on speed thresholds (backup method)
	# Ensures AI always progresses through gears
	var speed_kmh = speed_ms * SPEED_SCALE
	match current_gear:
		1:
			if speed_kmh > 40.0:  # Force 2nd gear at 40 km/h
				should_shift_up = true
		2:
			if speed_kmh > 70.0:  # Force 3rd gear at 70 km/h
				should_shift_up = true
		3:
			if speed_kmh > 100.0:  # Force 4th gear at 100 km/h
				should_shift_up = true
		4:
			if speed_kmh > 130.0:  # Force 5th gear at 130 km/h
				should_shift_up = true
	
	# Downshift if RPM too low
	if current_rpm < max_rpm * 0.30 && current_gear > 1:
		should_shift_down = true
	
	# Execute shifts
	if should_shift_up && current_gear < gear_ratios.size():
		current_gear += 1
		start_shift_effect()
		shift_cooldown = shift_cooldown_time
		print("AI shifted to gear %d (Speed: %.1f km/h, RPM: %d)" % [current_gear, speed_kmh, int(current_rpm)])
	
	elif should_shift_down:
		current_gear -= 1
		start_shift_effect()
		shift_cooldown = shift_cooldown_time

func update_rpm(delta: float):
	if shifting:
		current_rpm = lerp(current_rpm, min_rpm + 1500, delta * 5.0)
		return
	
	if race_finished:
		current_rpm = lerp(current_rpm, min_rpm, delta * 8.0)
		return
	
	# Calculate RPM based on wheel speed and gear ratio
	var wheel_rpm = calculate_wheel_rpm_from_speed()
	var gear_ratio = gear_ratios[current_gear - 1]
	var calculated_rpm = wheel_rpm * gear_ratio * final_drive
	
	# Apply smooth RPM changes
	if throttle_input > 0.1:
		var target_rpm = max(calculated_rpm, min_rpm + 1500)
		current_rpm = lerp(current_rpm, target_rpm, delta * 5.0)
	else:
		current_rpm = lerp(current_rpm, max(calculated_rpm, min_rpm), delta * 3.0)
	
	current_rpm = clamp(current_rpm, min_rpm, max_rpm)

@warning_ignore("unused_parameter")
func apply_driving_forces(delta: float):
	if throttle_input < 0.05 || race_finished:
		return
	
	var gear_ratio = gear_ratios[current_gear - 1]
	
	# Get engine torque
	var engine_torque = 0.0
	if current_car:
		engine_torque = current_car.get_torque_at_rpm(current_rpm) * throttle_input
	else:
		# Fallback torque curve
		var peak_torque_rpm = max_rpm * 0.55
		var torque_factor = 1.0
		
		if current_rpm < peak_torque_rpm:
			torque_factor = clamp((current_rpm - min_rpm) / (peak_torque_rpm - min_rpm), 0.3, 1.0)
		else:
			var falloff = (current_rpm - peak_torque_rpm) / (max_rpm - peak_torque_rpm)
			torque_factor = 1.0 - (falloff * 0.4)
		
		engine_torque = current_car.torque * torque_factor * throttle_input
	
	# Calculate wheel force
	var wheel_torque = engine_torque * gear_ratio * final_drive
	var theoretical_force = wheel_torque / wheel_radius
	
	# Apply traction limit
	var max_force = mass * 9.81 * 1.1
	var actual_force = min(theoretical_force, max_force) * 200.0
	
	apply_central_force(Vector2.RIGHT * actual_force)

func apply_resistance_forces():
	var velocity_x = linear_velocity.x
	var speed_abs = abs(velocity_x)
	
	if speed_abs < 0.1:
		return
	
	var direction = sign(velocity_x)
	
	# Air resistance
	var drag_force = drag_coefficient * speed_abs * speed_abs
	
	# Rolling resistance
	var rolling_force = rolling_resistance * speed_abs
	
	# Strong braking when race is finished
	if race_finished:
		var braking_force = mass * 15.0
		drag_force += braking_force
		rolling_force *= 10.0
	
	# Engine braking when off throttle
	if throttle_input < 0.05:
		rolling_force *= 4.0
	
	var total_resistance = -direction * (drag_force + rolling_force)
	apply_central_force(Vector2(total_resistance, 0))

func update_speed_and_ui(delta: float):
	speed_ms = abs(linear_velocity.x)
	
	# Single consistent speed conversion - no more gear-based divisors!
	# This prevents speed spikes when AI shifts gears
	var actual_speed_kmh = speed_ms * SPEED_SCALE
	
	# Smooth the displayed speed
	displayed_speed = lerp(displayed_speed, actual_speed_kmh, delta * 5.0)
	displayed_speed = clamp(displayed_speed, 0.0, 500.0)
	
	update_ui(displayed_speed)

func calculate_wheel_rpm_from_speed() -> float:
	if speed_ms < 0.1:
		return 0.0
	return speed_ms * WHEEL_RPM_SCALE

func update_ui(speed_kmh: float):
	if throttle_lbl:
		if race_finished:
			throttle_lbl.text = "AI - RACE FINISHED! | Final Speed: %d km/h | Time: %.2fs" % [int(speed_kmh), race_time]
		else:
			throttle_lbl.text = "AI - Throttle: %d%% | Gear: %d/%d | RPM: %d | Time: %.2fs" % [
				int(throttle_input * 100), 
				current_gear, 
				gear_ratios.size(),
				int(current_rpm),
				race_time
			]
	
	if speedlbl:
		speedlbl.text = "AI Speed: %d km/h" % int(speed_kmh)
	
	update_rev_bar(current_rpm)

func update_rev_bar(rpm_val: float):
	if rev_bar == null:
		return
	
	var ratio = clamp(rpm_val / max_rpm, 0.0, 1.0)
	rev_bar.value = ratio * 100.0
	
	if ratio < 0.6:
		rev_bar.tint_progress = Color(0.2, 1.0, 0.2)
	elif ratio < 0.85:
		rev_bar.tint_progress = Color(1.0, 1.0, 0.2)
	else:
		rev_bar.tint_progress = Color(1.0, 0.2, 0.2)

func start_shift_effect():
	shifting = true
	current_rpm = max(min_rpm + 1000, current_rpm * 0.65)
	
	var timer = get_tree().create_timer(0.15)
	timer.timeout.connect(func(): 
		shifting = false
	)

func set_can_act(new_value: bool):
	can_act = new_value
	if new_value:
		race_active = true
		race_distance = 0.0
		race_time = 0.0

func set_can_act_false():
	can_act = false
	race_active = false

func finish_race():
	if race_finished:
		return
	
	race_finished = true
	race_active = false
	throttle_input = 0.0
	
	race_time = get_elapsed_race_time()
	
	$CanvasLayer/Label.visible = true
	$CanvasLayer/Label.text = "AI finished in: %.2fs" % race_time
	
	# Apply immediate strong braking force
	var current_speed = linear_velocity.x
	if abs(current_speed) > 1.0:
		var stop_direction = -sign(current_speed)
		var braking_force = mass * 25.0
		apply_central_force(Vector2(stop_direction * braking_force, 0))
	
	update_ui(displayed_speed)
	
func get_race_stats() -> Dictionary:
	return {
		"time": race_time,
		"distance": race_distance,
		"speed_kmh": displayed_speed,
		"speed_mph": displayed_speed * 0.621371,
		"finished": race_finished
	}

@warning_ignore("unused_parameter")
func _on_animation_player_animation_finished(anim_name: StringName):
	can_act = true
	race_start_time = Time.get_ticks_msec() / 1000.0
	race_active = true

func _on_finishline_body_entered(body: Node2D) -> void:
	print("AI crossed finish line: ", body)
	finish_race()
