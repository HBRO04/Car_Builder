extends Node

const G: float = 9.81
const IDLE_RPM: float = 600.0

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
	var wheel_radius: float = car["wheel raduis"] * 0.0254  # inches → meters
	
	var mass: float = car["car weight"] + engine["engine_weight"]
	var max_torque: float = engine["max_Torque_nm"]
	var rpm_limit: float = engine["rpm"]
	var peak_kw_rpm: float = rpm_limit * 0.90
	
	var gear: int = 0
	var rpm: float = IDLE_RPM
	var velocity: float = 0.0
	var distance: float = 0.0
	var time: float = 0.0
	
	var zero_to_100_time: float = -1.0
	var quarter_mile_time: float = -1.0
	
	var dt: float = 0.01  # simulation step

	while true:
		var torque: float
		if rpm <= peak_kw_rpm:
			torque = max_torque * (rpm / peak_kw_rpm)
		else:
			torque = max_torque * (1.0 - ((rpm - peak_kw_rpm) / (rpm_limit - peak_kw_rpm)))
			torque = max(torque, 0.0)
		
		var wheel_torque = torque * gear_ratios[gear] * final_drive
		var wheel_force = wheel_torque / wheel_radius
		
		var max_traction_force = mass * G * 1.2
		wheel_force = min(wheel_force, max_traction_force)
		
		var acceleration = wheel_force / mass
		
		velocity += acceleration * dt
		distance += velocity * dt
		time += dt
		
		rpm = velocity / wheel_radius * gear_ratios[gear] * final_drive * (60.0 / (2.0 * PI))
		rpm = max(rpm, IDLE_RPM)
		
		if rpm >= rpm_limit:
			if gear < gear_ratios.size() - 1:
				var prev = gear_ratios[gear]
				gear += 1
				rpm = rpm * (gear_ratios[gear] / prev)
			else:
				rpm = rpm_limit
		
		if zero_to_100_time < 0 and velocity >= 27.78:
			zero_to_100_time = time
		
		if distance >= 402.3:
			quarter_mile_time = time
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

	# Store so other scenes can access
	last_0_100 = result["0_100"]
	last_quarter_mile = result["quarter_mile"]
	last_trap_speed = result["trap_speed"]

	print("--- Simulation Results ---")
	print("0–100 km/h: %.2f s" % last_0_100)
	print("¼ Mile: %.2f s" % last_quarter_mile)
	print("Trap Speed: %.2f km/h" % last_trap_speed)

# ✅ Getters usable from any scene
func get_0_100() -> float:
	return last_0_100

func get_quarter_mile() -> float:
	return last_quarter_mile

func get_trap_speed() -> float:
	return last_trap_speed
