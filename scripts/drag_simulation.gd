extends Node

const G: float = 9.81
const IDLE_RPM: float = 600.0
const DRIVETRAIN_EFFICIENCY: float = 0.85  # 15% loss through transmission
const DRAG_COEFFICIENT: float = 0.0012  # Aerodynamic drag factor

var last_0_100: float = -1.0
var last_quarter_mile: float = -1.0
var last_trap_speed: float = -1.0

func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open JSON file: " + path)
		return {}
	var text := file.get_as_text()
	return JSON.parse_string(text)

func simulate_drag(car: Dictionary, engine: Dictionary) -> Dictionary:
	var gear_ratios: Array = car["gear_ratios"]
	var final_drive: float = car["final_drive"]
	var wheel_radius: float = car["wheel raduis"] * 0.0254  
	
	var mass: float = car["car weight"] + engine["engine_weight"]
	var max_torque: float = engine["max_Torque_nm"]
	var rpm_limit: float = engine["rpm"]
	
	# More realistic torque curve - peak torque available from 3000-6500 RPM
	var torque_start_rpm: float = 3000.0
	var torque_peak_rpm: float = rpm_limit * 0.65  # Peak torque around 65% of redline
	var power_peak_rpm: float = rpm_limit * 0.85   # Peak power at 85% of redline
	
	var gear: int = 0
	var rpm: float = IDLE_RPM
	var velocity: float = 0.0
	var distance: float = 0.0
	var time: float = 0.0
	
	var zero_to_100_time: float = -1.0
	var quarter_mile_time: float = -1.0
	
	# Dynamic traction based on speed (better at speed)
	var base_traction: float = 1.5  # Drag radials/slicks
	
	var dt: float = 0.01
	
	while true:
		# More realistic torque curve
		var torque: float
		if rpm <= torque_start_rpm:
			# Low RPM: torque builds from 60% to 100%
			torque = max_torque * (0.6 + 0.4 * (rpm / torque_start_rpm))
		elif rpm <= torque_peak_rpm:
			# Mid RPM: full torque available
			torque = max_torque
		elif rpm <= power_peak_rpm:
			# Power peak: torque stays high (95-100%)
			var t = (rpm - torque_peak_rpm) / (power_peak_rpm - torque_peak_rpm)
			torque = max_torque * (1.0 - 0.05 * t)
		else:
			# Past power peak: gentler falloff
			var t = (rpm - power_peak_rpm) / (rpm_limit - power_peak_rpm)
			torque = max_torque * 0.95 * (1.0 - 0.3 * t)  # Falls to 66.5% at redline
			torque = max(torque, 0.0)
		
		# Apply drivetrain efficiency
		var wheel_torque = torque * gear_ratios[gear] * final_drive * DRIVETRAIN_EFFICIENCY
		var wheel_force = wheel_torque / wheel_radius
		
		# Dynamic traction (improves slightly with speed due to weight transfer)
		var speed_factor = min(velocity / 10.0, 1.0)  # Maxes out at 10 m/s
		var traction_multiplier = base_traction + (0.3 * speed_factor)
		var max_traction_force = mass * G * traction_multiplier
		wheel_force = min(wheel_force, max_traction_force)
		
		# Aerodynamic drag (minimal at low speeds, significant at high speeds)
		var drag_force = DRAG_COEFFICIENT * velocity * velocity
		var net_force = wheel_force - drag_force
		
		var acceleration = net_force / mass
		
		velocity += acceleration * dt
		distance += velocity * dt
		time += dt
		
		rpm = velocity / wheel_radius * gear_ratios[gear] * final_drive * (60.0 / (2.0 * PI))
		rpm = max(rpm, IDLE_RPM)
		
		# Shift logic with small RPM drop
		if rpm >= rpm_limit * 0.98:  # Shift slightly before redline
			if gear < gear_ratios.size() - 1:
				gear += 1
				# Calculate post-shift RPM more accurately
				rpm = velocity / wheel_radius * gear_ratios[gear] * final_drive * (60.0 / (2.0 * PI))
				rpm = max(rpm, IDLE_RPM)
		
		if zero_to_100_time < 0 and velocity >= 27.78:
			zero_to_100_time = time
		
		if distance >= 402.3:
			quarter_mile_time = time
			break
		
		# Safety: prevent infinite loops
		if time > 30.0:
			print("Warning: Simulation timeout")
			break
	
	return {
		"0_100": zero_to_100_time,
		"quarter_mile": quarter_mile_time,
		"trap_speed": velocity * 3.6
	}

func run_sim(car_file: String, engine_file: String):
	var car_data = load_json(car_file)
	var engine_data = load_json(engine_file)
	if car_data.is_empty() or engine_data.is_empty():
		print("Missing data. Check JSON file paths.")
		return
	var result = simulate_drag(car_data, engine_data)
	
	last_0_100 = result["0_100"]
	last_quarter_mile = result["quarter_mile"]
	last_trap_speed = result["trap_speed"]
	

func get_0_100() -> float:
	return last_0_100

func get_quarter_mile() -> float:
	return last_quarter_mile

func get_trap_speed() -> float:
	return last_trap_speed
