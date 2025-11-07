extends Node2D

@onready var errorlbl: Label = $lblError

#only nessecary engine specs
var engineSize: float
var power: float
var torque: float
var rpm: int
var engineWeight: float
var reliability: int
var cylinders: int
var enginetype: int
var engineCost: int
var turbo: bool = false
var supercharged: bool = false
var vvt: bool = false
var camtype: int
var numvalves: int
var fuelType: int

#drive terrain specs
var engine_placement: int #0 is rear and 100 is front
var driveterrain: String #fwd, rwd or awd
var brakestype: int #normal, sport, race 

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


func _ready() -> void:
	populate_engine_list($TabContainer/Engine/Enginepnl/OptionButton)
	update_all()
	
func update_all():
	update_Ui()
	get_settings()
	populate_engine_list($TabContainer/Engine/Enginepnl/OptionButton)
	display_all_confirmation_page()
	
func update_Ui():
	errorlbl.text = ""
	
	if front_sus_ride_height == 0 :
		return
	
	$TabContainer/Suspension/front_Suspensionpnl/Label4.text = str(front_sus_ride_height)
	$TabContainer/Suspension/front_Suspensionpnl/Label6.text = str(front_sus_ride_stifnes)
	$TabContainer/Suspension/rear_Suspensionpnl/Label4.text = str(rear_sus_ride_height)
	$TabContainer/Suspension/rear_Suspensionpnl/Label6.text = str(rear_sus_ride_stifnes)
	
func display_all_confirmation_page():
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label.text = "Engine placement: " + str(engine_placement)
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label2.text = "Drive Terrain: " + driveterrain
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label3.text = "Brakes: " 
	match brakestype:
		0: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label3.text = "Brakes: Normal"
		1: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label3.text = "Brakes: Sport"
		2: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label3.text = "Brakes: Race"
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label5.text = "Front suspension:"
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label6.text = "Type: "
	match front_susp_type:
		0: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label6.text = "Type: Normal"
		1: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label6.text = "Type: Sport"
		2: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label6.text = "Type: Race"
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label7.text = "Ride height: " + str(front_sus_ride_height)
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label8.text = "Ride stiffness: " + str(front_sus_ride_stifnes)
	
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label10.text = "Rear Suspension:"
	match rear_susp_type:
		0: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label11.text = "Type: Normal"
		1: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label11.text = "Type: Sport"
		2: $TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label11.text = "Type: Race"
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label12.text = "Ride height: " + str(rear_sus_ride_height)
	$TabContainer/Confirmation/Panel/ScrollContainer/VBoxContainer/Label13.text = "Ride stiffness: " + str(rear_sus_ride_stifnes)
	
	


func get_settings():
	#drive terrain specs
	engine_placement = $"TabContainer/Drive Terrain/engineLocationpnl/HSlider".value
	match  $"TabContainer/Drive Terrain/Driveterrainpnl/OptionButton".selected:
		0: driveterrain = "FWD"
		1: driveterrain = "RWD"
		2: driveterrain = "AWD"
	brakestype = $"TabContainer/Drive Terrain/Brakespnl/OptionButton".selected
	
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
	rear_susp_type = $TabContainer/Suspension/front_Suspensionpnl/OptionButton.selected
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
	
			
	
	
func _on_option_button_item_selected(index: int) -> void:
	#Here it will load the specs of the engine
	var engine = $TabContainer/Engine/Enginepnl/OptionButton
	var selected = engine.get_selected_id()
	if selected == -1:
		errorlbl.text = "Please select an engine first!"
		return
		
	var file_name = engine.get_item_text(selected)
	load_engine_from_file(file_name)


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


func _on_specs_option_button_item_selected(index: int) -> void:
	update_all()
