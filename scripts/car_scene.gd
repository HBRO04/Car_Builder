extends RigidBody2D
class_name car_show

var can_act: bool = false
@export var cooldown_time: float = 0.3

# Engine + drivetrain
var current_rpm: float = 600.0
var current_gear: int = 1
var wheel_radius: float = 0.3  # Default fallback
var gear_ratios: Array = []
var final_drive: float = 3.5  # Default fallback
var max_rpm: float = 6000.0
var min_rpm: float = 600.0
var throttle_input: float = 0.0
var speed: float = 0.0
var displayed_speed: float = 0.0  # Smoothed speed for display
var shifting: bool = false

# Physics properties
var drag_coefficient: float = 0.3  # Increased for realistic resistance
var rolling_resistance: float = 50.0  # Increased for realistic resistance
var max_force: float = 50000.0  # Maximum force cap

# UI references - with null safety
var throttle_lbl: Label = null
var speedlbl: Label = null
var rev_bar: TextureProgressBar = null

# CurrentCar instance
var current_car

func _ready() -> void:
	# Initialize CurrentCar
	current_car = CurrentCar
	current_car.get_data()
	
	# Set up car data
	set_data()
	find_ui_elements()
	set_can_act(false)
	show_correct_body()
	set_weight()
	set_suspension()
	setup_physics_properties()
	update_rev_bar(0)
	
	# DIAGNOSTIC: Check for any constraints
	print("=== CAR SETUP COMPLETE ===")
	print("Position: ", global_position)
	print("Can act: ", can_act)
	print("Freeze: ", freeze)
	print("Mass: ", mass)

# Safe way to find UI elements
func find_ui_elements():
	# Try different possible paths
	var possible_paths = [
		"CanvasLayer/lblthrottle",
		"CanvasLayer/lblSpeed", 
		"CanvasLayer/TextureProgressBar",
		"../../CanvasLayer/lblthrottle",
		"../../CanvasLayer/lblSpeed",
		"../../CanvasLayer/TextureProgressBar",
		"../../../CanvasLayer/lblthrottle",
		"../../../CanvasLayer/lblSpeed",
		"../../../CanvasLayer/TextureProgressBar"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			if "lblthrottle" in path and node is Label:
				throttle_lbl = node
				print("Found throttle label at: ", path)
			elif "lblSpeed" in path and node is Label:
				speedlbl = node
				print("Found speed label at: ", path)
			elif "TextureProgressBar" in path and node is TextureProgressBar:
				rev_bar = node
				print("Found rev bar at: ", path)

func setup_physics_properties():
	# Set physics properties for 2D side-view drag racing
	gravity_scale = 1.0  # Need gravity for drag racing on ground
	linear_damp = 0.0  # We handle damping manually
	angular_damp = 5.0  # Prevent excessive rotation
	can_sleep = false
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY  # Better collision detection
	
	# CRITICAL: Make sure the body is not locked
	print("Physics setup - Freeze: ", freeze, " | Can sleep: ", can_sleep)
	print("Lock rotation: ", lock_rotation, " | Mass: ", mass)

# --- Setup ---
func set_data():
	var torque_params = current_car.get_torque_curve_parameters()
	max_rpm = torque_params["redline"]
	gear_ratios = current_car.gear_ratios
	final_drive = current_car.final_drive
	
	# Convert wheel radius from inches to meters
	var wheel_radius_inches = current_car.wheelraduis if current_car.wheelraduis > 0 else 12.0
	wheel_radius = wheel_radius_inches * 0.0254

	if gear_ratios.is_empty():
		gear_ratios = [3.5, 2.1, 1.4, 1.0, 0.8]
	
	if final_drive <= 0:
		final_drive = 3.5
	
	print("Car data loaded:")
	print("Engine: ", current_car.engineName)
	print("Power: ", current_car.kw, " kW")
	print("Torque: ", current_car.torque, " Nm")
	print("Gear ratios: ", gear_ratios)
	print("Final drive: ", final_drive)
	print("Wheel radius: ", wheel_radius, " meters")

func show_correct_body():
	$body/body1.visible = current_car.choosenBody == 1
	$body/body2.visible = current_car.choosenBody == 2

func set_suspension():
	# For drag racing, disable complex suspension/wheel physics
	# The wheels should be visual only, not separate physics bodies
	
	# Disable suspension joints
	if has_node("suspension/front_suspension"):
		$suspension/front_suspension.node_a = NodePath("")
		$suspension/front_suspension.node_b = NodePath("")
		print("Disabled front suspension")
	
	if has_node("suspension/back_suspension"):
		$suspension/back_suspension.node_a = NodePath("")
		$suspension/back_suspension.node_b = NodePath("")
		print("Disabled back suspension")
	
	# Disable wheel physics if they exist
	if has_node("back_wheel") and get_node("back_wheel") is RigidBody2D:
		var back_wheel = get_node("back_wheel")
		back_wheel.freeze = true
		back_wheel.collision_layer = 0
		back_wheel.collision_mask = 0
		print("Disabled back wheel physics")
	
	if has_node("front_wheel") and get_node("front_wheel") is RigidBody2D:
		var front_wheel = get_node("front_wheel")
		front_wheel.freeze = true
		front_wheel.collision_layer = 0
		front_wheel.collision_mask = 0
		print("Disabled front wheel physics")

func set_weight():
	mass = max(500.0, current_car.totalWeight)  # Minimum 500kg
	print("Car mass: ", mass, " kg")

# --- Physics loop ---
func _physics_process(delta: float) -> void:
	if !can_act:
		return

	# --- Throttle input (0-1) ---
	var is_throttle_pressed = Input.is_action_pressed("throttle")
	var target_throttle = 1.0 if is_throttle_pressed else 0.0
	throttle_input = lerp(throttle_input, target_throttle, delta * 5.0)

	# --- Gear shift ---
	if Input.is_action_just_pressed("gear_up"):
		shift_up()
	elif Input.is_action_just_pressed("gear_down"):
		shift_down()

	# --- RPM CALCULATION ---
	if !shifting:
		# Calculate wheel RPM from actual speed
		var wheel_rpm = calculate_wheel_rpm_from_speed()
		
		# Calculate engine RPM from wheel RPM
		var gear_ratio = gear_ratios[current_gear - 1] if current_gear <= gear_ratios.size() else 1.0
		var calculated_rpm = wheel_rpm * gear_ratio * final_drive
		
		if throttle_input > 0.1:
			# With throttle: RPM can be higher than wheel speed suggests
			var target_rpm = max(calculated_rpm, min_rpm + (max_rpm - min_rpm) * throttle_input * 0.5)
			current_rpm = lerp(current_rpm, target_rpm, delta * 5.0)
		else:
			# No throttle: RPM drops to idle or wheel speed
			current_rpm = lerp(current_rpm, max(calculated_rpm, min_rpm), delta * 3.0)
	else:
		# During shifting, drop RPM
		current_rpm = lerp(current_rpm, min_rpm + 1000, delta * 5.0)

	current_rpm = clamp(current_rpm, min_rpm, max_rpm)

	# --- TORQUE AND FORCE CALCULATION WITH PROPER GEAR SPEED LIMITS ---
	var engine_torque = current_car.get_torque_at_rpm(current_rpm) * throttle_input

	# Get current gear ratio
	var gear_ratio = gear_ratios[current_gear - 1] if current_gear <= gear_ratios.size() else 1.0
	
	# Calculate theoretical max speed for this gear at max RPM
	# Formula: Speed (m/s) = (RPM / Gear Ratio / Final Drive) * Wheel Circumference / 60
	var wheel_circumference = 2.0 * PI * wheel_radius  # meters per revolution
	var wheel_rpm_at_max = current_car.get_torque_curve_parameters()["redline"] / (gear_ratio * final_drive)
	var max_speed_this_gear = (wheel_rpm_at_max / 60.0) * wheel_circumference  # m/s
	
	# Current speed as percentage of max speed for this gear
	var speed_ratio = speed / max_speed_this_gear if max_speed_this_gear > 0 else 0.0
	
	# Reduce force as we approach max speed for the current gear
	var speed_limiter = 1.0
	if speed_ratio > 0.85:  # Start reducing force at 85% of max gear speed
		speed_limiter = max(0.1, 1.0 - (speed_ratio - 0.85) / 0.15)
	
	# Calculate wheel torque and force
	var wheel_torque = engine_torque * gear_ratio * final_drive
	var drive_force = wheel_torque / wheel_radius
	
	# Scale force for game physics - VERY HIGH for fast visual movement
	drive_force *= 3000.0  # Doubled again for much faster visual speed
	
	# Apply speed limiter for this gear
	drive_force *= speed_limiter
	
	# Debug: print force calculation
	if throttle_input > 0.1 and int(Engine.get_physics_frames()) % 60 == 0:  # Print every 60 frames (1 second)
		print("Gear %d | Speed: %d/%d km/h | Force: %.0f N | RPM: %d" % [
			current_gear, int(displayed_speed), int(max_speed_this_gear * 3.6), 
			drive_force, int(current_rpm)
		])

	# --- Apply force in the car's forward direction (horizontal for drag racing) ---
	# For 2D drag racing, force should be horizontal (right direction)
	var forward_direction = Vector2.RIGHT  # Always accelerate to the right
	
	# ALWAYS apply force when throttle is pressed
	if throttle_input > 0.05:
		apply_central_force(forward_direction * drive_force)
		
		print("=== APPLYING FORCE ===")
		print("Force: %.1f N | Throttle: %.2f | Mass: %.1f kg" % [drive_force, throttle_input, mass])
		print("Velocity: ", linear_velocity)
		print("Position: ", global_position)
	
	# --- Apply resistance forces ---
	apply_resistance_forces()

	# --- Calculate display speed (horizontal speed only for drag racing) ---
	speed = abs(linear_velocity.x)  # Only horizontal speed matters
	var speed_kmh = speed * 3.6

	# --- Update HUD safely ---
	update_ui(speed_kmh)

# Calculate wheel RPM based on current linear velocity
func calculate_wheel_rpm_from_speed() -> float:
	# Current horizontal speed in m/s (only care about forward movement)
	var current_speed = abs(linear_velocity.x)
	
	if current_speed < 0.1:  # Nearly stopped
		return 0.0
	
	# Wheel circumference
	var circumference = 2.0 * PI * wheel_radius
	
	# Wheel RPM = (m/s) / (m/revolution) * 60 seconds/minute
	var wheel_rpm = (current_speed / circumference) * 60.0
	
	return wheel_rpm

# Safe UI updates
func update_ui(speed_kmh: float):
	if throttle_lbl:
		throttle_lbl.text = "Throttle: %d%% | Gear: %d | RPM: %d" % [
			int(throttle_input * 100), current_gear, int(current_rpm)
		]
	
	if speedlbl:
		# Display speed in km/h with proper formatting
		speedlbl.text = "Speed: %d km/h" % int(speed_kmh)
	
	update_rev_bar(current_rpm)

# Apply resistance forces
func apply_resistance_forces():
	# Only apply horizontal drag/resistance
	var horizontal_velocity = linear_velocity.x
	var speed_magnitude = abs(horizontal_velocity)
	
	if speed_magnitude < 0.01:  # Nearly stopped
		return
	
	var direction = sign(horizontal_velocity)
	
	# Air resistance (drag) - proportional to speed squared
	var drag_force = drag_coefficient * speed_magnitude * speed_magnitude
	
	# Rolling resistance - constant at speed
	var rolling_force = rolling_resistance * speed_magnitude
	
	# Total resistance in opposite direction of movement (horizontal only)
	var total_resistance = Vector2(-direction * (drag_force + rolling_force), 0)
	
	apply_central_force(total_resistance)

# --- Shifting with better RPM management ---
func shift_up():
	if shifting or current_gear >= gear_ratios.size():
		return
	
	# Relaxed shift requirements - let the player shift when they want
	if speed < 2.0:
		print("Speed too low for upshift")
		return
	
	print("Shifting UP from gear ", current_gear, " to ", current_gear + 1)
	current_gear += 1
	start_shift_effect()

func shift_down():
	if shifting or current_gear <= 1:
		return
	
	print("Shifting DOWN from gear ", current_gear, " to ", current_gear - 1)
	current_gear -= 1
	start_shift_effect()

func start_shift_effect():
	shifting = true
	print("Shift → Gear ", current_gear, " | Ratio: ", gear_ratios[current_gear - 1] if current_gear <= gear_ratios.size() else 1.0)
	
	# Moderate RPM adjustment during shift
	current_rpm = max(min_rpm + 1200, current_rpm * 0.8)

	var timer = get_tree().create_timer(0.3)
	await timer.timeout
	shifting = false

# --- Rev bar logic ---
func update_rev_bar(rpm_val: float) -> void:
	if rev_bar == null:
		return
	var ratio = clamp(rpm_val / max_rpm, 0.0, 1.0)
	rev_bar.value = ratio * 100.0

	if ratio < 0.7:
		rev_bar.tint_progress = Color(0.2, 1.0, 0.2) # green
	elif ratio < 0.9:
		rev_bar.tint_progress = Color(1.0, 1.0, 0.2) # yellow
	else:
		rev_bar.tint_progress = Color(1.0, 0.2, 0.2) # red

# --- Activation ---
func set_can_act(new_value: bool) -> void:
	can_act = new_value
	print("Can act:", can_act)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("Go")
	can_act = true

# Test function - ENHANCED
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Apply horizontal impulse for drag racing
		var impulse_force = Vector2.RIGHT * 50000  # HUGE impulse
		apply_central_impulse(impulse_force)
		print("TEST: Applied HUGE impulse - ", impulse_force)
		print("Position after: ", global_position)
		print("Velocity after: ", linear_velocity)
	
	# Test key to check if car is frozen in inspector
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		print("=== FULL DIAGNOSTIC ===")
		print("Freeze: ", freeze)
		print("Freeze mode: ", freeze_mode)
		print("Lock rotation: ", lock_rotation)
		print("Linear velocity: ", linear_velocity)
		print("Angular velocity: ", angular_velocity)
		print("Position: ", global_position)
		print("Mass: ", mass)
		print("Gravity scale: ", gravity_scale)
		
		# Try to manually set velocity
		linear_velocity = Vector2(100, 0)
		print("Manually set velocity to (100, 0)")
		await get_tree().create_timer(0.1).timeout
		print("Velocity after manual set: ", linear_velocity)
