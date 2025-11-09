extends Node2D

@onready var errorlbl: Label = $lblError
@onready var costlbl: Label = $costpnl/Costlbl
@onready var weightlbl: Label = $weightpnl/weightlbl
@onready var carLoaderrorlbl: Label = $loadCarpnl/Label
@onready var enginescene: PackedScene = preload("res://scenes/engine_builder.tscn")
@onready var my_timer: Timer = $MyTimer


#only nessecary engine specs
var enginename: String
var engineSize: float
var power: float
var torque: float
var rpm: int
var engineWeight: float
var reliability: int
var cylinders: int
var enginetype: int
var engineCost: int = 0
var turbo: bool = false
var supercharged: bool = false
var vvt: bool = false
var camtype: int
var numvalves: int
var fuelType: int

#body
var choosenBody: int
var bodyMat: int #steel, aluminum, fiber glass and carbon fiber
var sbodyMat: String #mat in string for labels
var chasyMat: int#steel, aluminum, fiber glass and carbon fiber
var schasyMat: String #mat in string for labels
var interiorType: int#normal, sport, race and stripped interior
var sinterior: String #interior for labels

#drive terrain specs
var engine_placement: int #0 is rear and 100 is front
var splacement: String = ""
var driveterrain: String #fwd, rwd or awd
var brakestype: int #normal, sport, race 
var wheelraduis: int #13 to 22

#Gears
@onready var spin_gears: SpinBox = $TabContainer/Gearbox/gearspnl/SpinBox
@onready var gear_sliders_container: VBoxContainer = $TabContainer/Gearbox/gearratiospnl/ScrollContainer/VBoxContainer
var gear_ratios: Array = []
var numGears: int
var base_first_gear: float = 3.5
var base_top_gear: float = 0.9
var final_drive: float = 3.5

#front suspention variables
var front_susp_type: int #normal, sport, race
var front_sus_ride_height: float
var front_sus_max_ride_height: float
var front_sus_min_ride_height: float
var front_sus_ride_stifnes: float
var front_sus_max_ride_stifnes: float
var front_sus_min_ride_stifnes: float

#rear suspention variables
var rear_susp_type: int #normal, sport, race
var rear_sus_ride_height: float
var rear_sus_max_ride_height: float
var rear_sus_min_ride_height: float
var rear_sus_ride_stifnes: float
var rear_sus_max_ride_stifnes: float
var rear_sus_min_ride_stifnes: float

#cost
var basecost: int = 0
var totalCost: int = 0

#wheight
var baseweight: int = 0
var totalWeight: int = 0

#names
var carName: String = ""



func _ready() -> void:
	$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body1".button_pressed = true
	populate_engine_list($TabContainer/Engine/Enginepnl/OptionButton)
	get_settings()
	update_all()
	$TabContainer/Engine/Enginepnl.visible = false
	$"TabContainer/Car body".visible = true
	$TabContainer/Engine/Enginepnl/OptionButton.select(-1)
	$loadCarpnl/Button2.visible = false
	$loadCarpnl/OptionButton.visible = false
	spin_gears.value_changed.connect(_on_spin_gears_changed)
	_generate_gear_ratios(int(spin_gears.value))
	_refresh_sliders()
	$TabContainer/Gearbox/gearspnl/HSlider.value_changed.connect(_on_final_drive_changed)
	$TabContainer/Gearbox/gearspnl/HSlider.value = final_drive
	$TabContainer/Gearbox/gearspnl/Label3.text = "Final Drive: %.2f" % final_drive
	
#gears
func _on_spin_gears_changed(value: float) -> void:
	@warning_ignore("narrowing_conversion")
	numGears = value
	_generate_gear_ratios(int(value))
	_refresh_sliders()

func _generate_gear_ratios(gear_count: int) -> void:
	gear_ratios.clear()
	if gear_count <= 1:
		gear_ratios.append(base_first_gear)
		return

	var gap := pow(base_top_gear / base_first_gear, 1.0 / float(gear_count - 1))
	for i in range(gear_count):
		gear_ratios.append(base_first_gear * pow(gap, i))

func _refresh_sliders() -> void:
	# Remove old sliders
	for child in gear_sliders_container.get_children():
		child.queue_free()

	# Rebuild sliders with value labels
	for i in range(gear_ratios.size()):
		var outer = VBoxContainer.new()

		var title = Label.new()
		title.text = "Gear %d:" % (i + 1)
		outer.add_child(title)

		var slider = HSlider.new()
		slider.min_value = 0.5
		slider.max_value = 5.0
		slider.step = 0.01
		slider.value = gear_ratios[i]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		outer.add_child(slider)

		var value_label = Label.new()
		value_label.text = "Ratio: %.2f" % gear_ratios[i]
		outer.add_child(value_label)

		var index := i
		slider.value_changed.connect(func(v):
			_on_gear_slider_changed(index, v)
			value_label.text = "Ratio: %.2f" % v
		)

		gear_sliders_container.add_child(outer)


func _on_gear_slider_changed(index: int, new_value: float) -> void:
	# keep first gear locked, recalc spacing from changed gear
	if index == 0:
		base_first_gear = new_value
		_generate_gear_ratios(gear_ratios.size())
		_refresh_sliders()
		return

	var r1 := base_first_gear
	var gap := pow(new_value / r1, 1.0 / float(index))
	for i in range(gear_ratios.size()):
		gear_ratios[i] = r1 * pow(gap, i)

	_refresh_sliders()
	
func _on_final_drive_changed(value: float) -> void:
	final_drive = value
	$TabContainer/Gearbox/gearspnl/Label3.text = "Final Drive: %.2f" % value
	update_all() # optional if you want UI/cost/weight recalculated
	
	
func update_all():
	get_settings()
	populate_engine_list($TabContainer/Engine/Enginepnl/OptionButton)
	populate_car_list($loadCarpnl/OptionButton)
	display_all_confirmation_page()
	update_Ui()
	calc_cost()
	calc_weight()
	
	
func calc_cost():
	basecost = 0
	totalCost = 0
	var exstraCost: int = 0
	
	match choosenBody:
		0: basecost = 0
		1: basecost = 2000
		2: basecost = 4000
		
	match bodyMat:
		0: exstraCost += 1000
		1: exstraCost += 1500
		2: exstraCost += 2000
		3: exstraCost += 2500
		
	match chasyMat:
		0: exstraCost += 1000
		1: exstraCost += 1500
		2: exstraCost += 2000
		3: exstraCost += 2500
		
	match interiorType:
		0: basecost += 100
		1: basecost += 150
		2: basecost += 200
		3: basecost += 100
		
	match driveterrain:
		"FWD": exstraCost += 100
		"RWD": exstraCost += 160
		"AWD": exstraCost += 250
		
	match brakestype:
		0: exstraCost += 100
		1: exstraCost += 150
		2: exstraCost += 200
		
	match front_susp_type:
		0: exstraCost += 100
		1: exstraCost += 150
		2: exstraCost += 200
		
	match rear_susp_type:
		0: exstraCost += 100
		1: exstraCost += 150
		2: exstraCost += 200
		
	totalCost = basecost + engineCost + exstraCost
	costlbl.text = "Cost: " + str(totalCost)
		

func calc_weight():
	baseweight = 0
	
	match choosenBody:
		0: baseweight = 0
		1: baseweight = 100
		2: baseweight = 200
		
	match bodyMat:
		0: baseweight += 300
		1: baseweight += 200
		2: baseweight += 0
		3: baseweight += 50
		
	match chasyMat:
		0: baseweight += 300
		1: baseweight += 200
		2: baseweight += 0
		3: baseweight += 50
		
	match driveterrain:
		"FWD": baseweight += 100
		"RWD": baseweight += 160
		"AWD": baseweight += 250
		
	match interiorType:
		0: baseweight += 150
		1: baseweight += 100
		2: baseweight += 20 
		3: baseweight -= 10
		
	
	@warning_ignore("narrowing_conversion")
	totalWeight = baseweight + engineWeight
	
	weightlbl.text = "Wheight: " + str(totalWeight)

func update_Ui():
	errorlbl.text = ""
	#update engine placement label
	if engine_placement > 80:
		splacement = "Front Engined"
	elif engine_placement > 20:
		splacement = "Mid Engined"
	else :
		splacement = "Rear Engined"
	
	$"TabContainer/Drive Terrain/engineLocationpnl/Label4".text = splacement
	
	if front_sus_ride_height == 0 :
		return
	
	$TabContainer/Suspension/front_Suspensionpnl/Label4.text = str(front_sus_ride_height)
	$TabContainer/Suspension/front_Suspensionpnl/Label6.text = str(front_sus_ride_stifnes)
	$TabContainer/Suspension/rear_Suspensionpnl/Label4.text = str(rear_sus_ride_height)
	$TabContainer/Suspension/rear_Suspensionpnl/Label6.text = str(rear_sus_ride_stifnes)
	
	
		
	
func display_all_confirmation_page():
	#car body settings
	$TabContainer/Confirmation/carbodypnl/ScrollContainer/VBoxContainer/Label.text = "Car body settings:"
	$TabContainer/Confirmation/carbodypnl/ScrollContainer/VBoxContainer/Label3.text = "Car body choosen: " + str(choosenBody)
	$TabContainer/Confirmation/carbodypnl/ScrollContainer/VBoxContainer/Label4.text = "Body Material: " + sbodyMat
	$TabContainer/Confirmation/carbodypnl/ScrollContainer/VBoxContainer/Label5.text = "Chasy Material: " + schasyMat
	$TabContainer/Confirmation/carbodypnl/ScrollContainer/VBoxContainer/Label6.text = "Interior: " + sinterior
	
	#car settings
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label.text = "Car settings:"
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label3.text = "Engine placement: " + splacement
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label4.text = "Drive Terrain: " + driveterrain
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label5.text = "Brakes: " 
	match brakestype:
		0: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label5.text = "Brakes: Normal"
		1: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label5.text = "Brakes: Sport"
		2: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label5.text = "Brakes: Race"
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label7.text = "Front suspension:"
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label8.text = "Type: "
	match front_susp_type:
		0: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label8.text = "Type: Normal"
		1: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label8.text = "Type: Sport"
		2: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label8.text = "Type: Race"
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label9.text = "Ride height: " + str(front_sus_ride_height)
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label10.text = "Ride stiffness: " + str(front_sus_ride_stifnes)
	
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label12.text = "Rear Suspension:"
	match rear_susp_type:
		0: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label13.text = "Type: Normal"
		1: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label13.text = "Type: Sport"
		2: $TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label13.text = "Type: Race"
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label14.text = "Ride height: " + str(rear_sus_ride_height)
	$TabContainer/Confirmation/carsettingspnl/ScrollContainer/VBoxContainer/Label15.text = "Ride stiffness: " + str(rear_sus_ride_stifnes)
	
	#engine settings
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label.text = "Engine settings:"
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label3.text = "Engine: " + enginename
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label4.text = "engine size: " + str(snapped(engineSize, 0.01))
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label5.text = "Cylinders: " + str(cylinders)
	match enginetype:
		1:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label6.text = "Engine type: Inline"
		2:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label6.text = "Engine type: V-type"
		3:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label6.text = "Engine type: Boxer"
		4:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label6.text = "Engine type: Rotary"
	match camtype:
		0:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label7.text = "Cam type: OHV"
		1:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label7.text = "Cam type: SOHC"
		2:
			$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label7.text = "Cam type: DOHC"
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label8.text = "Num valves: " + str(numvalves)
	if vvt:
		$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label9.text = "VVT: True"
	else:
		$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label9.text = "VVT: False"
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label10.text = "kw: " + str(snapped(power, 0.01))
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label11.text = "Torque: " + str(snapped(torque, 0.01))
	if turbo == false and supercharged == false:
		$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label12.text = "Forced induction: NA"
	elif turbo:
		$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label12.text = "Forced induction: Turbo"
	elif supercharged:
		$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label12.text = "Forced induction: Supercharged"
		
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label13.text = "RPM: " + str(rpm)
	
	var fuel: String = ""
	match fuelType:
		0: fuel = "93"
		1: fuel = "95"
		2: fuel = "Diesel"
		3: fuel = "Race"
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label14.text = "Fuel type: " + fuel
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label15.text = "Engine Weight: " + str(engineWeight)
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label16.text = "Reliability: " + str(reliability)
	$TabContainer/Confirmation/enginepnl/ScrollContainer/VBoxContainer/Label17.text = "Engine Cost: R "+ str(engineCost) 
	
	
	#car body settings
	


func get_settings():
	#car body specs
	bodyMat = $"TabContainer/Car body/bodyMatpnl/OptionButton".selected
	match bodyMat:
		0: sbodyMat = "Steel"
		1: sbodyMat = "Aluminum"
		2: sbodyMat = "Fiber Glass"
		3: sbodyMat = "Carbon fiber"
	chasyMat = $"TabContainer/Car body/chasyMatpnl/OptionButton".selected
	match chasyMat:
		0: schasyMat = "Steel"
		1: schasyMat = "Aluminum"
		2: schasyMat = "Fiber Glass"
		3: schasyMat = "Carbon fiber"
	interiorType = $"TabContainer/Car body/interiorTypepnl/OptionButton".selected
	match interiorType:
		0: sinterior = "Normal"
		1: sinterior = "Sport"
		2: sinterior = "Race"
		3: sinterior = "Stripped interior"
	
	
	#drive terrain specs
	engine_placement = $"TabContainer/Drive Terrain/engineLocationpnl/HSlider".value
	match  $"TabContainer/Drive Terrain/Driveterrainpnl/OptionButton".selected:
		0: driveterrain = "FWD"
		1: driveterrain = "RWD"
		2: driveterrain = "AWD"
	brakestype = $"TabContainer/Drive Terrain/Brakespnl/OptionButton".selected
	
	match $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".selected:
		0: wheelraduis = 13
		1: wheelraduis = 14
		2: wheelraduis = 15
		3: wheelraduis = 16
		4: wheelraduis = 17
		5: wheelraduis = 18
		6: wheelraduis = 19
		7: wheelraduis = 20
		8: wheelraduis = 21
		9: wheelraduis = 22
	
	#front suspension
	front_susp_type = $TabContainer/Suspension/front_Suspensionpnl/OptionButton.selected
	match front_susp_type:
		0:
			front_sus_max_ride_height = 120 #mm
			front_sus_min_ride_height = 80 #mm
			front_sus_max_ride_stifnes = 25 #nm
			front_sus_min_ride_stifnes = 15 #nm
		1:
			front_sus_max_ride_height = 100 #mm
			front_sus_min_ride_height = 60 #mm
			front_sus_max_ride_stifnes = 40 #nm
			front_sus_min_ride_stifnes = 25 #nm
		2:
			front_sus_max_ride_height = 80 #mm
			front_sus_min_ride_height = 40 #mm
			front_sus_max_ride_stifnes = 65 #nm
			front_sus_min_ride_stifnes = 45 #nm
			
	#rear suspension
	rear_susp_type = $TabContainer/Suspension/rear_Suspensionpnl/OptionButton.selected
	match rear_susp_type:
		0:
			rear_sus_max_ride_height = 120 #mm
			rear_sus_min_ride_height = 80 #mm
			rear_sus_max_ride_stifnes = 25 #nm
			rear_sus_min_ride_stifnes = 15 #nm
		1:
			rear_sus_max_ride_height = 100 #mm
			rear_sus_min_ride_height = 60 #mm
			rear_sus_max_ride_stifnes = 40 #nm
			rear_sus_min_ride_stifnes = 25 #nm
		2:
			rear_sus_max_ride_height = 80 #mm
			rear_sus_min_ride_height = 40 #mm
			rear_sus_max_ride_stifnes = 65 #nm
			rear_sus_min_ride_stifnes = 45 #nm
			
	$TabContainer/Suspension/front_Suspensionpnl/Label4.text = str(front_sus_ride_height)
	$TabContainer/Suspension/front_Suspensionpnl/Label6.text = str(front_sus_ride_stifnes)
	$TabContainer/Suspension/front_Suspensionpnl/HSlider.max_value = front_sus_max_ride_height
	$TabContainer/Suspension/front_Suspensionpnl/HSlider.min_value = front_sus_min_ride_height
	$TabContainer/Suspension/front_Suspensionpnl/HSlider2.max_value = front_sus_max_ride_stifnes
	$TabContainer/Suspension/front_Suspensionpnl/HSlider2.min_value = front_sus_min_ride_stifnes
	
	$TabContainer/Suspension/rear_Suspensionpnl/Label4.text = str(rear_sus_ride_height)
	$TabContainer/Suspension/rear_Suspensionpnl/Label6.text = str(rear_sus_ride_stifnes)
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider.max_value = rear_sus_max_ride_height
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider.min_value = rear_sus_min_ride_height
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider2.max_value = rear_sus_max_ride_stifnes
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider2.min_value = rear_sus_min_ride_stifnes
	
	

func populate_engine_list(option_button: OptionButton) -> void:
	option_button.clear() 
	
	var dir = DirAccess.open("res://engines/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				# remove the extension for display
				var display_name = file_name.get_basename()
				option_button.add_item(display_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		errorlbl.text = "Error: Could not open engines folder."

func load_engine_from_file(file_name: String) -> void:
	
	enginename = file_name#get the engine name 
	
	var path := "res://engines/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		$loadEnginpnl/lblerrorloading.text = "Error: Engine file not found at " + path
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		$loadEnginpnl/lblerrorloading.text = "Error: Could not open engine file."
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		$loadEnginpnl/lblerrorloading.text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		$loadEnginpnl/lblerrorloading.text = "Error: Loaded data is empty!"
		return

	#getting variables for engine specs
	engineSize = data.get("engineSize_L", 0.0)
	cylinders = data.get("cylinders", 0)
	enginetype = data.get("EngineType", 0)
	engineCost = data.get("engineCost", 0.0)
	vvt = data.get("vvt", false)
	turbo = data.get("turbo", false)
	supercharged = data.get("supercharged", false)
	reliability = data.get("reliability", 0.0)
	engineWeight = data.get("engine_weight", 0.0)
	power = data.get("max_kw", 0.0)
	torque = data.get("max_Torque_nm", 0.0)
	fuelType = data.get("fuelType", 0)
	rpm = data.get("rpm", 0)
	camtype = data.get("camType", 0)
	numvalves = data.get("numValve", 0)
	
	display_enginespecs()

	
func display_enginespecs():
	print(enginename)
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/engineSize.text = "engine size: " + str(snapped(engineSize, 0.01))
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/cylinderslbl.text = "Cylinders: " + str(cylinders)
	match enginetype:
		1:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/enginteTypelbl.text = "Engine type: Inline"
		2:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/enginteTypelbl.text = "Engine type: V-type"
		3:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/enginteTypelbl.text = "Engine type: Boxer"
		4:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/enginteTypelbl.text = "Engine type: Rotary"
	match camtype:
		0:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/camlbl.text = "Cam type: OHV"
		1:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/camlbl.text = "Cam type: SOHC"
		2:
			$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/camlbl.text = "Cam type: DOHC"
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/valvelbl.text = "Num valves: " + str(numvalves)
	if vvt:
		$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/vvtlbl.text = "VVT: True"
	else:
		$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/vvtlbl.text = "VVT: False"
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/powerlbl.text = "kw: " + str(snapped(power, 0.01))
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/torquelbl.text = "Torque: " + str(snapped(torque, 0.01))
	if turbo == false and supercharged == false:
		$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/forcedinductionlbl.text = "Forced induction: NA"
	elif turbo:
		$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/forcedinductionlbl.text = "Forced induction: Turbo"
	elif supercharged:
		$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/forcedinductionlbl.text = "Forced induction: Supercharged"
		
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/rpmlbl.text = "RPM: " + str(rpm)
	
	var fuel: String = ""
	match fuelType:
		0: fuel = "93"
		1: fuel = "95"
		2: fuel = "Diesel"
		3: fuel = "Race"
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/fueltypelbl.text = "Fuel type: " + fuel
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/engineweightlbl.text = "Engine Weight: " + str(engineWeight)
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/reliabilitylbl.text = "Reliability: " + str(reliability)
	$TabContainer/Engine/enginespecspnl/ScrollContainer/VBoxContainer/engineCostlbl.text = "Engine Cost: R "+ str(engineCost) 
	
			
	
	
@warning_ignore("unused_parameter")
func _on_option_button_item_selected(index: int) -> void:
	#Here it will load the specs of the engine
	var engine = $TabContainer/Engine/Enginepnl/OptionButton
	var selected = engine.get_selected_id()
	if selected == -1:
		errorlbl.text = "Please select an engine first!"
		return
		
	var file_name = engine.get_item_text(selected)
	load_engine_from_file(file_name)
	update_all()
	$TabContainer/Engine/Enginepnl.visible = false
	$TabContainer/Engine/selectEnginebtn.visible = true
	


func _on_h_slider_value_changed(value: float) -> void:
	front_sus_ride_height = value
	update_all()
	


func _on_h_slider_2_value_changed(value: float) -> void:
	front_sus_ride_stifnes = value
	update_all()


func _on_rear_h_slider_value_changed(value: float) -> void:
	rear_sus_ride_height = value
	update_all()


func _on_rear_h_slider_2_value_changed(value: float) -> void:
	rear_sus_ride_stifnes = value
	update_all()


@warning_ignore("unused_parameter")
func _on_specs_option_button_item_selected(index: int) -> void:
	update_all()

func un_toggle_body_types():
	$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body1".button_pressed = false
	$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body2".button_pressed = false

@warning_ignore("unused_parameter")
func _on_body_1_toggled(toggled_on: bool) -> void:
	choosenBody = 1
	$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body2".button_pressed = false
	update_all()
	


@warning_ignore("unused_parameter")
func _on_body_2_toggled(toggled_on: bool) -> void:
	choosenBody = 2
	$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body1".button_pressed = false
	update_all()


func _on_build_enginebtn_pressed() -> void:
	preload("res://scenes/engine_builder.tscn")
	get_tree().change_scene_to_packed(enginescene)


func _on_select_enginebtn_pressed() -> void:
	$TabContainer/Engine/Enginepnl.visible = true
	$TabContainer/Engine/selectEnginebtn.visible = false
	$TabContainer/Engine/Enginepnl/OptionButton.select(-1)


func _on_build_car_button_pressed() -> void:
	var file_name: String = $TabContainer/Confirmation/LineEdit.text.strip_edges()
	
	if file_name == "":
		errorlbl.text = "Error: Please enter a file name."
		return

	var file_path: String = "res://Cars/%s.json" % file_name

	var engine_data: Dictionary = {
		"body type": choosenBody,
		"body Material": bodyMat,
		"chasy Material": chasyMat,
		"interior Type": interiorType,
		"engine Name": enginename,
		"driveterrain": driveterrain,
		"brakes Type": brakestype,
		"front suspension Type": front_susp_type,
		"front ride height": front_sus_ride_height,
		"front ride stiffness": front_sus_ride_stifnes,
		"rear suspension Type": rear_susp_type,
		"rear ride height": rear_sus_ride_height,
		"rear ride stiffness": rear_sus_ride_stifnes,
		"cost": totalCost,
		"car weight": totalWeight,
		"engine placement int": engine_placement,
		"engine placement string": splacement,
		"wheel raduis": wheelraduis,
		"num_gears": numGears,
		"gear_ratios": gear_ratios,
		"final_drive": final_drive
	}
	
	$TabContainer/Confirmation/LineEdit.text = ""
	update_all()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	if file:
		var json_text: String = JSON.stringify(engine_data, "\t")  # pretty print
		file.store_string(json_text)
		file.close()
		errorlbl.text = "Car saved successfully!"
	else:
		errorlbl.text = "Error: Could not open file for writing."
	
	my_timer.start(1.5)
	await my_timer.timeout
	preload("res://scenes/parking_lot.tscn")
	get_tree().change_scene_to_file("res://scenes/parking_lot.tscn")
		
	


func _on_load_car_button_pressed() -> void:
	$loadCarpnl.size.y = 220
	$loadCarpnl/Button.visible = false
	update_all()
	$loadCarpnl/OptionButton.select(-1)
	$loadCarpnl/Button2.visible = true
	$loadCarpnl/OptionButton.visible = true

func populate_car_list(option_button: OptionButton) -> void:
	option_button.clear() 
	
	var dir = DirAccess.open("res://Cars/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				# remove the extension for display
				var display_name = file_name.get_basename()
				option_button.add_item(display_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		carLoaderrorlbl.text = "Error: Could not open engines folder."
		
func _on_final_load_car_button_pressed() -> void:
	#Here it will load the specs of the car
	var car = $loadCarpnl/OptionButton
	var selected = car.get_selected_id()
	if selected == -1:
		errorlbl.text = "Please select an car first!"
		return
		
	#don't remove for loop it works but can't work without it
	for i in range(5):
		var file_name = car.get_item_text(selected)
		load_car_from_file(file_name)
		carName = file_name#get the car name 
		$TabContainer/Confirmation/LineEdit.text = carName
		
	update_all()
	$loadCarpnl.size.y = 73.0
	$loadCarpnl/Button.visible = true
	$loadCarpnl/Button2.visible = false
	$loadCarpnl/OptionButton.visible = false
	
func load_car_from_file(file_name: String) -> void:
	
	var path := "res://Cars/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		errorlbl.text = "Error: Car file not found at " + path
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errorlbl.text = "Error: Could not open car file."
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		errorlbl.text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		errorlbl.text = "Error: Loaded data is empty!"
		return

	#getting variables for car specs
	choosenBody = data.get("body type", 0.0)
	bodyMat = data.get("body Material", 0)
	chasyMat = data.get("chasy Material", 0)
	brakestype = data.get("brakes Type", 0.0)
	totalWeight = data.get("car weight", 0.0)
	totalCost = data.get("cost", 0.0)
	driveterrain = data.get("driveterrain", 0.0)
	enginename = data.get("engine Name", 0.0)
	front_sus_ride_height = data.get("front ride height", 0.0)
	front_sus_ride_stifnes = data.get("front ride stiffness", 0)
	front_susp_type = data.get("front suspension Type", 0)
	interiorType = data.get("interior Type", 0)
	rear_sus_ride_height = data.get("rear ride height", 0)
	rear_sus_ride_stifnes = data.get("rear ride stiffness", 0)
	rear_susp_type = data.get("rear suspension Type", 0)
	engine_placement = data.get("engine placement int", 0)
	splacement = data.get("engine placement string", 0)
	wheelraduis = data.get("wheel raduis", 0)
	numGears = data.get("num_gears", 0)
	gear_ratios = data.get("gear_ratios", [])
	final_drive = data.get("final_drive", 0)

	_refresh_sliders() # rebuild UI after loading
	
	display_car_specs()
	
func display_car_specs():
	if choosenBody == 1 :
		$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body1".button_pressed = true
		$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body2".button_pressed = false
	elif choosenBody == 2 :
		$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body1".button_pressed = false
		$"TabContainer/Car body/carBodypnl/ScrollContainer/HBoxContainer/body2".button_pressed = true
		
	$"TabContainer/Car body/bodyMatpnl/OptionButton".select(bodyMat)
	$"TabContainer/Car body/chasyMatpnl/OptionButton".select(chasyMat)
	$"TabContainer/Car body/interiorTypepnl/OptionButton".select(interiorType)

	#driveterrain
	$"TabContainer/Drive Terrain/engineLocationpnl/HSlider".value = engine_placement
	match driveterrain:
		"FWD": $"TabContainer/Drive Terrain/Driveterrainpnl/OptionButton".select(0)
		"RWD": $"TabContainer/Drive Terrain/Driveterrainpnl/OptionButton".select(1)
		"AWD": $"TabContainer/Drive Terrain/Driveterrainpnl/OptionButton".select(2)
	match wheelraduis:
		13: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(0)
		14: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(1)
		15: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(2)
		16: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(3)
		17: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(4)
		18: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(5)
		19: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(6)
		20: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(7)
		21: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(8)
		22: $"TabContainer/Drive Terrain/wheelRaduispnl/OptionButton".select(9)
	
		
	$"TabContainer/Drive Terrain/Brakespnl/OptionButton".select(brakestype)
	
	#gears
	$TabContainer/Gearbox/gearspnl/SpinBox.value = numGears
	$TabContainer/Gearbox/gearspnl/HSlider.value = final_drive
	
	#front suspension
	$TabContainer/Suspension/front_Suspensionpnl/OptionButton.select(front_susp_type)
	$TabContainer/Suspension/front_Suspensionpnl/HSlider.value = front_sus_ride_height
	$TabContainer/Suspension/front_Suspensionpnl/HSlider2.value = front_sus_ride_stifnes
	
	#rear suspension
	$TabContainer/Suspension/rear_Suspensionpnl/OptionButton.select(rear_susp_type)
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider.value = rear_sus_ride_height
	$TabContainer/Suspension/rear_Suspensionpnl/HSlider2.value = rear_sus_ride_stifnes
	
	#engine
	var opt = $TabContainer/Engine/Enginepnl/OptionButton
	for i in range(opt.item_count):
		if opt.get_item_text(i) == enginename:
			opt.select(i)
			_on_option_button_item_selected(i)
			
			
