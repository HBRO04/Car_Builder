extends Panel

@onready var lblError: Label = $"../errorlbl"

signal loaddyno

# engine specs
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
var car: Node2D



func _ready() -> void:
	populate_car_list($OptionButton)
	


# --- Populate car list from "res://Cars/" ---
func populate_car_list(option_button: OptionButton) -> void:
	option_button.clear() 
	
	var dir = DirAccess.open("res://Cars/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".json"):
				option_button.add_item(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		lblError.text = "Error: Could not open car folder."


# --- Load car when button pressed ---
func _on_button_pressed() -> void:
	var car = $OptionButton
	var selected = car.get_selected_id()
	if selected == -1:
		lblError.text = "Please select a car first!"
		return
	
	var file_name = car.get_item_text(selected)
	load_car_from_file(file_name)
	carName = file_name
	
	save_current_car()
	
	$"../main_menu/AnimationPlayer".play("start_up")
	$AnimationPlayer.play("slide_out")
	#hide_body_sprites()
	
	
	
	emit_signal("loaddyno")
	
	


func hide_body_sprites():
	$body/body1.visible = false
	$body/body2.visible = false


# --- Load car from file ---
func load_car_from_file(file_name: String) -> void:
	var path := "res://Cars/%s.json" % file_name

	if not FileAccess.file_exists(path):
		lblError.text = "Error: Car file not found at " + path
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		lblError.text = "Error: Could not open car file."
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		lblError.text = "Error parsing JSON: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		lblError.text = "Error: Loaded data is empty!"
		return

	# --- Assign variables ---
	choosenBody = data.get("body type", 0)
	bodyMat = data.get("body Material", 0)
	chasyMat = data.get("chasy Material", 0)
	brakestype = data.get("brakes Type", 0)
	totalWeight = data.get("car weight", 0)
	totalCost = data.get("cost", 0)
	driveterrain = data.get("driveterrain", "")
	enginename = data.get("engine Name", "")
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


# --- Save current car safely ---
func save_current_car() -> void:
	var dir_path = "res://current_car"

	if not ensure_folder_exists(dir_path):
		lblError.text = "Error: Could not create folder."
		return

	var file_path: String = "%s/%s.json" % [dir_path, "current_car"]

	var car_data: Dictionary = {
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

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(car_data, "\t"))
		file.close()
		lblError.text = "Car saved successfully!"
	else:
		lblError.text = "Error: Could not save current car."
		
func ensure_folder_exists(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		# Folder doesn't exist → create it using parent
		var parent_path = path.get_base_dir()
		var parent_dir := DirAccess.open(parent_path)
		if parent_dir == null:
			print("Error: Parent directory does not exist.")
			return false
		var err = parent_dir.make_dir(path.get_file())
		if err != OK:
			print("Error creating folder: ", err)
			return false
	return true


func _on_button_5_pressed() -> void:
	$"../sim_resultspnl/AnimationPlayer".play("start")
	$"../main_menu/AnimationPlayer".play("slide_out")
	DragSimulation.run_sim("res://Cars/%s.json" % carName, "res://engines/%s.json" %enginename)
	var zeroTo100: float = DragSimulation.get_0_100()
	var quarterMileTime: float = DragSimulation.get_quarter_mile()
	var speedtrap: float = DragSimulation.get_trap_speed()
	$"../sim_resultspnl/ScrollContainer/VBoxContainer/Label2".text = "0-100 time: %.2f s" % zeroTo100
	$"../sim_resultspnl/ScrollContainer/VBoxContainer/Label3".text = "Quarter mile time: %.2f s" % quarterMileTime
	$"../sim_resultspnl/ScrollContainer/VBoxContainer/Label4".text = "Trap speed: %.2f km/h" % speedtrap


func _on_backbutton_sim_pressed() -> void:
	$"../sim_resultspnl/AnimationPlayer".play("end")
	$"../main_menu/AnimationPlayer".play("start_up")
