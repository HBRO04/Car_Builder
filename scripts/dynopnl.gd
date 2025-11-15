extends Panel

var engineSize_L: float
var cylinders: int #3,4,5,6 or 8
var pistonStroke_mm: float
var pistonDiameter_mm: float
var EngineMat: int #cast iron, aluminum, Compacted Graphite Iron, Magnesium or Titanium
var cylinderMat: int #cast iron, aluminum, Compacted Graphite Iron, Magnesium or Titanium
var EngineType: int = 1 #inline, v-type, boxer or rotary
var engineCost: float = 0
var extraCost: float = 0 #for turbos, superchargers, exhausts and stuff that should not be times cylinders
var baseMaterialCost: float = 100
var complexity_Multiplier: float = 1.0
var camType: int = 0 # OHV, SOHC, DOHC
var kw_per_l: float = 0
var kw: float = 0
var numValve: int = 0 #2,3,4 or 5
var vvt: bool = false
var turbo: bool = false
var supercharged: bool = false
var tsetup: int #Na, single, twin
var ttune: int #eco, normal, sport or race
var torque: float = 0
var reliability: float =0
var reliabilityScore: String = ""
var engine_weight: float = 0
var max_kw: float
var max_Torque_nm: float

#components
var pistonsType: int = 0 #normal, performance or race
var conrodsType: int = 0 #normal, performance or race
var crankshaftType: int = 0 #normal, performance or race

#fuel
var fuelsystem : int = 0 #carb or fuel injection
var fuelType: int = 0 #95, 92, diesel, race
var rpm: int = 0
var currentRPM: int = 0
var fuelmix: int = 0
var fueleconomy: float = 0.0
var Stringfueleconomy: String
var kmperl: String

#intakes
var intakeType: int = 0 #normal, performance or race
var radiatorType: int = 0#small, medium or race
var oilCooler: bool = false

#exhausts
var cat: bool = false
var catType: int = 0 #normal or premuim
var exhaustType: int = 0 # only single or twin
var exhaustManifoldType: int = 0 #normal, sports, performance or race
var muffler: int = 0 #small, big, freeflow or straight pipe

#extra stuff
var engineName: String = ""

@onready var choose_car_panel = $"../chooseCarpnl" # Adjust the node path

func _ready() -> void:
	dyno()
	choose_car_panel.connect("loaddyno",Callable(self, "dyno"))
	
	

func dyno():
	load_car_from_file("current_car")
	load_engine_from_file(engineName)
	get_torque_curve_parameters()
	$currentRPM.max_value = rpm
	update_dyno_graph($TorqueLine, $PowerLine, $GraphBackground, $RPM_Marker,$lblCurrentTorque,$lblCurrentPower)
	

func get_torque_curve_parameters() -> Dictionary:
	var peak_torque = engineSize_L * 130.0  # Nm per liter base

	# Modify torque by cam type
	match camType:
		0: peak_torque *= 0.95
		1: peak_torque *= 1.0
		2: peak_torque *= 1.05

	# Forced induction
	if turbo:
		peak_torque *= 1.35
	if supercharged:
		peak_torque *= 1.25

	# Fuel type influence
	match fuelType:
		0: peak_torque *= 1.00
		1: peak_torque *= 0.98
		2: peak_torque *= 1.10
		3: peak_torque *= 1.15

	# Tuning
	match ttune:
		0: peak_torque *= 0.90
		1: peak_torque *= 1.00
		2: peak_torque *= 1.10
		3: peak_torque *= 1.20

	# Peak torque RPM
	var peak_torque_rpm = 3500
	if camType == 2:
		peak_torque_rpm = 4500
	if turbo:
		peak_torque_rpm += 500
	if ttune >= 2:
		peak_torque_rpm += 500

	# Engine redline (use max RPM from slider)
	var redline = rpm
	if fuelType == 2: # diesel
		redline = min(redline, 5000)
	if fuelType == 3: # race fuel
		redline = max(redline, 8000)

	return {
		"peak_torque": peak_torque,
		"peak_torque_rpm": peak_torque_rpm,
		"redline": redline
	}


# Get torque at a specific RPM
func get_torque_at_rpm(rpm_val: float) -> float:
	var curve = get_torque_curve_parameters()
	var peak_torque = curve["peak_torque"]
	var peak_rpm = curve["peak_torque_rpm"]
	var redline = curve["redline"]

	# Use a smooth curve using piecewise quadratic approximation
	if rpm_val <= peak_rpm:
		# Rise portion (0 -> peak_rpm)
		# Slow rise at low rpm, faster in mid rpm
		var rise_factor = rpm_val / peak_rpm
		return clamp(peak_torque * (0.4 + 0.6 * rise_factor), 0, peak_torque)
	elif rpm_val <= redline:
		# Fall portion (peak_rpm -> redline)
		# Gradual torque drop off
		var fall_factor = (rpm_val - peak_rpm) / float(redline - peak_rpm)
		return clamp(peak_torque * (1.0 - 0.5 * fall_factor), 0, peak_torque)
	else:
		return 0
		
func update_dyno_graph(line_torque: Line2D, line_power: Line2D, background: ColorRect, rpm_marker: Line2D = null, lbl_current_torque: Label = null, lbl_current_power: Label = null) -> void:
	if line_torque == null or line_power == null or background == null:
		return

	line_torque.clear_points()
	line_power.clear_points()
	if rpm_marker != null:
		rpm_marker.clear_points()

	var graph_margin: float = 24.0
	var point_step_rpm: int = 250
	var width: float = background.size.x - 2.0 * graph_margin
	var height: float = background.size.y - 2.0 * graph_margin
	var x0: float = graph_margin
	var y0: float = background.size.y - graph_margin

	var curve = get_torque_curve_parameters()
	var redline: float = curve.get("redline", rpm)

	# --- generate RPM points ---
	var rpm_points: Array = []
	for rpm_val in range(0, int(redline) + point_step_rpm, point_step_rpm):
		rpm_points.append(rpm_val)

	# --- compute torque & power values ---
	var torque_points: Array = []
	var power_points: Array = []

	for rpm_val in rpm_points:
		var torque_val = get_torque_at_rpm(rpm_val)
		var power_val = (torque_val * rpm_val) / 9550.0
		torque_points.append(torque_val)
		power_points.append(power_val)

	# --- scaling ---
	var max_torque: float = max(1.0, torque_points.max())
	var max_power: float = max(1.0, power_points.max())
	
	#updating max 
	max_kw = max_power
	max_Torque_nm = max_torque

	# --- add torque/power points ---
	for i in range(rpm_points.size()):
		var rpm_val: float = rpm_points[i]
		var torque_val: float = torque_points[i]
		var power_val: float = power_points[i]

		var x = x0 + (rpm_val / redline) * width
		var y_torque = y0 - (torque_val / max_torque) * height
		var y_power = y0 - (power_val / max_power) * height

		line_torque.add_point(Vector2(x, y_torque))
		line_power.add_point(Vector2(x, y_power))

	# --- draw current RPM marker ---
	if currentRPM > 0:
		var marker_x = x0 + (float(currentRPM) / redline) * width

		if rpm_marker != null:
			rpm_marker.add_point(Vector2(marker_x, graph_margin))
			rpm_marker.add_point(Vector2(marker_x, background.size.y - graph_margin))

		# --- calculate actual torque & power at current RPM ---
		var current_torque: float = get_torque_at_rpm(currentRPM)
		var current_kw: float = (current_torque * currentRPM) / 9550.0

		# --- compute label positions ---
		var y_torque = y0 - (current_torque / max_torque) * height
		var y_power = y0 - (current_kw / max_power) * height

		# --- update label text and position ---
		if lbl_current_torque != null:
			lbl_current_torque.text = "Torque: %.1f Nm" % current_torque
			lbl_current_torque.position = Vector2(marker_x + 8, y_torque - 10)

		if lbl_current_power != null:
			lbl_current_power.text = "Power: %.1f kW" % current_kw
			lbl_current_power.position = Vector2(marker_x + 8, y_power - 10)
			
func update_dyno_for_current_rpm() -> void:
	var line_torque = $TorqueLine
	var line_power = $PowerLine
	var graph_bg = $GraphBackground

	update_dyno_graph(line_torque, line_power, graph_bg, $RPM_Marker,$lblCurrentTorque,$lblCurrentPower)


func _on_current_rpm_value_changed(value: float) -> void:
	@warning_ignore("narrowing_conversion")
	currentRPM = value
	update_dyno_for_current_rpm()
	$Label.text = "Current RPM: " + str(currentRPM)
	#update_UI()
	
func load_engine_from_file(file_name: String) -> void:
	var path := "res://engines/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		$"../errorlbl".text = "Error: Engine file not found at " + path
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		$"../errorlbl".text = "Error: Could not open engine file."
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		$"../errorlbl".text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		$"../errorlbl".text = "Error: Loaded data is empty!"
		return

	# --- Assign all variables from file ---
	engineSize_L = data.get("engineSize_L", 0.0)
	EngineMat = data.get("EngineMat", 0)
	cylinderMat = data.get("cylinderMat", 0)
	cylinders = data.get("cylinders", 0)
	pistonStroke_mm = data.get("pistonStroke_mm", 0.0)
	pistonDiameter_mm = data.get("pistonDiameter_mm", 0.0)
	EngineType = data.get("EngineType", 0)
	engineCost = data.get("engineCost", 0.0)
	extraCost = data.get("extraCost", 0.0)
	baseMaterialCost = data.get("baseMaterialCost", 100.0)
	complexity_Multiplier = data.get("complexity_Multiplier", 1.0)
	camType = data.get("camType", 0)
	kw_per_l = data.get("kw_per_l", 0.0)
	kw = data.get("kw", 0.0)
	numValve = data.get("numValve", 0)
	vvt = data.get("vvt", false)
	turbo = data.get("turbo", false)
	supercharged = data.get("supercharged", false)
	tsetup = data.get("tsetup", 0)
	ttune = data.get("ttune", 0)
	torque = data.get("torque", 0.0)
	reliability = data.get("reliability", 0.0)
	reliabilityScore = data.get("reliabilityScore", "")
	engine_weight = data.get("engine_weight", 0.0)
	max_kw = data.get("max_kw", 0.0)
	max_Torque_nm = data.get("max_Torque_nm", 0.0)
	pistonsType = data.get("pistonsType", 0)
	conrodsType = data.get("conrodsType", 0)
	crankshaftType = data.get("crankshaftType", 0)
	fuelsystem = data.get("fuelsystem", 0)
	fuelType = data.get("fuelType", 0)
	rpm = data.get("rpm", 0)
	currentRPM = data.get("currentRPM", 0)
	fuelmix = data.get("fuelmix", 0)
	fueleconomy = data.get("fueleconomy", 0.0)
	Stringfueleconomy = data.get("Stringfueleconomy", "")
	kmperl = data.get("kmperl", "")
	intakeType = data.get("intakeType", 0)
	radiatorType = data.get("radiatorType", 0)
	oilCooler = data.get("oilCooler", false)
	cat = data.get("cat", false)
	catType = data.get("catType", 0)
	exhaustType = data.get("exhaustType", 0)
	exhaustManifoldType = data.get("exhaustManifoldType", 0)
	muffler = data.get("muffler", 0)

	
func load_car_from_file(file_name: String) -> void:
	var path := "res://current_car/" + file_name + ".json"

	# Check if file exists
	if not FileAccess.file_exists(path):
		$"../errorlbl".text = "Error: Car file not found at " + path
		return

	# Open for reading (this does NOT modify the file)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		$"../errorlbl".text = "Error: Could not open car file."
		return

	var text := file.get_as_text()
	file.close()

	# Parse JSON
	var json := JSON.new()
	var err := json.parse(text)

	if err != OK:
		$"../errorlbl".text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data
	if data.is_empty():
		$"../errorlbl".text = "Error: Loaded data is empty!"
		return

	# Getting variables for car specs
	engineName = data.get("engine Name", "")
