extends Node

#Getting engine details/variables
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

#Car body specs
#body specs
var choosenBody: int
var bodyMat: int
var chasyMat: int
var interiorType: int

#Suspension Specs
var engine_placement: int
var splacement: String = ""
var driveterrain: String
var brakestype: int
var wheelraduis: int

var front_susp_type: int
var front_sus_ride_height: float
var front_sus_max_ride_height: float
var front_sus_min_ride_height: float
var front_sus_ride_stifnes: float
var front_sus_max_ride_stifnes: float
var front_sus_min_ride_stifnes: float

var rear_susp_type: int
var rear_sus_ride_height: float
var rear_sus_max_ride_height: float
var rear_sus_min_ride_height: float
var rear_sus_ride_stifnes: float
var rear_sus_max_ride_stifnes: float
var rear_sus_min_ride_stifnes: float

#Gears
var gear_ratios: Array = []
var numGears: int
var base_first_gear: float = 3.5
var base_top_gear: float = 0.9
var final_drive: float = 3.5

#cost & Weight
var basecost: int = 0
var totalCost: int = 0
var baseweight: int = 0
var totalWeight: int = 0

#Names
var carName: String = ""
var engineName: String = ""


#Load car from file
func load_car_from_file(file_name: String) -> void:
	var path := "res://current_car/%s.json" % file_name

	if not FileAccess.file_exists(path):
		print("Error: Car file not found at " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error: Could not open car file.")
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		print("Error parsing JSON: " + str(err))
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		print("Error: Loaded data is empty!")
		return

	#Assign variables
	choosenBody = data.get("body type", 0)
	bodyMat = data.get("body Material", 0)
	chasyMat = data.get("chasy Material", 0)
	brakestype = data.get("brakes Type", 0)
	totalWeight = data.get("car weight", 0)
	totalCost = data.get("cost", 0)
	driveterrain = data.get("driveterrain", "")
	engineName = data.get("engine Name", "")
	front_sus_ride_height = data.get("front ride height", 0)
	front_sus_ride_stifnes = data.get("front ride stiffness", 0)
	front_susp_type = data.get("front suspension Type", 0)
	interiorType = data.get("interior Type", 0)
	rear_sus_ride_height = data.get("rear ride height", 0)
	rear_sus_ride_stifnes = data.get("rear ride stiffness", 0)
	rear_susp_type = data.get("rear suspension Type", 0)
	engine_placement = data.get("engine placement int", 0)
	splacement = data.get("engine placement string", "")
	wheelraduis = data.get("wheel raduis", 0)
	numGears = data.get("num_gears", 0)
	gear_ratios = data.get("gear_ratios", [])
	final_drive = data.get("final_drive", 0)
	
func load_engine_from_file(file_name: String) -> void:
	var path := "res://engines/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		print("Error: Engine file not found at " + path)
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Error: Could not open engine file.")
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		print("Error parsing JSON file: " + str(err))
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		print("Error: Loaded data is empty!")
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
		
func get_data():
	load_car_from_file("current_car")
	load_engine_from_file(engineName)
