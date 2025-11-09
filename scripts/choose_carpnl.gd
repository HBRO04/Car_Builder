extends Panel

@onready var lblError: Label = $"../errorlbl"

signal loaddyno

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
	populate_car_list($OptionButton)

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
		lblError.text = "Error: Could not open car folder."
		


func _on_button_pressed() -> void:
	#Here it will load the specs of the car
	var car = $OptionButton
	var selected = car.get_selected_id()
	if selected == -1:
		lblError.text = "Please select an car first!"
		return
		
	#don't remove for loop it works but can't work without it
	for i in range(5):
		var file_name = car.get_item_text(selected)
		load_car_from_file(file_name)
		carName = file_name
		
	save_currentcar()
	$"../main_menu/AnimationPlayer".play("start_up")
	$AnimationPlayer.play("slide_out")
	hide_body_sprites()
	if choosenBody == 1:
		$"../bg/bodyType1".visible = true
	elif choosenBody == 2:
		$"../bg/bodyType2".visible = true
		
	emit_signal("loaddyno")
		
func hide_body_sprites():
	$"../bg/bodyType1".visible = false
	$"../bg/bodyType2".visible = false
		
func load_car_from_file(file_name: String) -> void:
	
	var path := "res://Cars/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		lblError.text = "Error: Car file not found at " + path
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		lblError.text = "Error: Could not open car file."
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		lblError.text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		lblError.text = "Error: Loaded data is empty!"
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
	
	
	
	
func save_currentcar():
	var file_name: String = "current_car"
	
	if file_name == "":
		lblError.text = "Error: Please enter a file name."
		return

	var file_path: String = "res://current_car/%s.json" % file_name

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
		"wheel raduis": wheelraduis
	}
	
	
	var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	if file:
		var json_text: String = JSON.stringify(engine_data, "\t")  # pretty print
		file.store_string(json_text)
		file.close()
		lblError.text = "Car loaded successfully!"
	else:
		lblError.text = "Error: Could not open file for writing."
