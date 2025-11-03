extends Node2D

@export var lblErrorEngineBlock: Label

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

func _ready() -> void:
	hide_components_sprites()
	hide_engine_sprites()
	hide_cam_and_valve_sprites()
	update_UI()
	torque = get_torque_at_rpm(rpm) # max torque at max RPM
	kw = (torque * rpm) / 9550.0    # max kW
	$CanvasLayer/TabContainer/EngineBlock.visible = true
	populate_engine_list($CanvasLayer/loadEnginpnl/OptionButton)
	
	var dir = DirAccess.open("res://engines/")
	if dir:
		print("Files in res://engines/:")
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			print(" - ", file)
			file = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open res://engines/")


func calc_cost():
	EngineMat = $CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/EngineMatOptbtn.selected
	cylinderMat = $CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/CylinderMatOptbtn2.selected
	baseMaterialCost = 0
	extraCost = 0
	
	#materials
	match  EngineMat:
		0: baseMaterialCost = 100
		1: baseMaterialCost = 150
		2: baseMaterialCost = 180
		3: baseMaterialCost = 250
		4: baseMaterialCost = 400
	match EngineType:
		1: complexity_Multiplier = 1.0
		2: complexity_Multiplier = 1.2
		3: complexity_Multiplier = 1.3
		4: complexity_Multiplier = 1.5
	match cylinderMat:
		0: baseMaterialCost += 100
		1: baseMaterialCost += 150
		2: baseMaterialCost += 180
		3: baseMaterialCost += 250
		4: baseMaterialCost += 400
	match camType:
		0: baseMaterialCost += 50
		1: baseMaterialCost += 250
		2: baseMaterialCost += 450
	match numValve:
		0: baseMaterialCost += 100
		1: baseMaterialCost += 150
		2: baseMaterialCost += 180
		3: baseMaterialCost += 220
		
	#forced induction should not be multplied by cylinders
	if turbo == true:
		extraCost += 1200
	if supercharged == true:
		extraCost += 2500
	if vvt == true:
		extraCost += 1500
	match tsetup:
		0: extraCost += 0
		1: extraCost += 500
		2: extraCost += 1500
	match ttune:
		0: extraCost += 150
		1: extraCost += 180
		2: extraCost += 200
		3: extraCost += 250
		
	#components
	match pistonsType:
		0: baseMaterialCost += 150
		1: baseMaterialCost += 350
		2: baseMaterialCost += 200
	match conrodsType:
		0: baseMaterialCost += 150
		1: baseMaterialCost += 350
		2: baseMaterialCost += 200
	match crankshaftType:
		0: extraCost += 1000
		1: extraCost += 2000
		2: extraCost += 3000
		
	#fuel system
	match fuelsystem:
		0: extraCost += 1000
		1: extraCost += 1500
		
	#intake
	match intakeType:
		0: extraCost += 300
		1: extraCost += 1000
		2: extraCost += 3000
	match radiatorType:
		0: extraCost += 100
		1: extraCost += 500
		2: extraCost += 1500
		
	#exhaust
	match  exhaustType:
		0: extraCost += 500
		1: extraCost += 1000
	match  exhaustManifoldType:
		0: extraCost += 300
		1: extraCost += 1000
		2: extraCost += 3000
		3: extraCost += 5000
	if cat == true:
		match catType:
			1: extraCost += 500
			2: extraCost += 1500
	engineCost = (baseMaterialCost * engineSize_L * cylinders * complexity_Multiplier ) + extraCost

func update_UI():
	var fi: String = "NA"
	get_engine_Info()
	calc_cost()
	calc_weight()
	
	#reliability
	reliability = calc_reliability()
	
	# calculate peak torque & kw once (these stay fixed)
	var curve = get_torque_curve_parameters()
	torque = curve["peak_torque"]                       # max torque
	kw = (torque * curve["peak_torque_rpm"]) / 9550.0  # max kw
	
	$CanvasLayer/TabContainer/Confirmation/curvespnl/currentRPM.max_value = rpm
	$CanvasLayer/TabContainer/Confirmation/curvespnl/currentRPM.min_value = 0
	$"CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/rpmlbl".text = str(rpm)
	
	update_dyno_graph($CanvasLayer/TabContainer/Confirmation/curvespnl/TorqueLine, $CanvasLayer/TabContainer/Confirmation/curvespnl/PowerLine, $CanvasLayer/TabContainer/Confirmation/curvespnl/GraphBackground,$CanvasLayer/TabContainer/Confirmation/curvespnl/RPM_Marker,$CanvasLayer/TabContainer/Confirmation/curvespnl/lblCurrentTorque, $CanvasLayer/TabContainer/Confirmation/curvespnl/lblCurrentPower)
	
	lblErrorEngineBlock.text = ""
	$CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonDiameterlbl.text = str($CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonDiamaterSlider.value) + " mm"
	$CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonStrokelbl.text = str($CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonStrokeSlider2.value) + " mm"
	$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/engineTypeNumlbl.text = str(EngineType) + "/4"
	$CanvasLayer/EngineCostpnl/Costlbl.text = "Cost: R %.2f" % [engineCost]
	$CanvasLayer/EngineSpecspnl/VBoxContainer/rpmlbl.text = "RPM: " + str(rpm)
	$"CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/fuelmixlbl".text = str($"CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/FuelMixSlider".value) + " %"
	$CanvasLayer/EngineSpecspnl/VBoxContainer/EnginekwperL_lbl.text = "kw per l: " + str(kw_per_l)
	
	# UI labels show MAX torque and MAX kw
	$CanvasLayer/EngineSpecspnl/VBoxContainer/kwlbl.text = "kw: " + str("%.2f" % max_kw)
	$CanvasLayer/EngineSpecspnl/VBoxContainer/torquelbl.text = "Torque: " + str("%.2f" % max_Torque_nm)
	
	$CanvasLayer/EngineSpecspnl/VBoxContainer/Currentrpmlbl.text = "Current RPM: " + str(currentRPM)
	if turbo == true:
		fi = "Turbo"
	if supercharged == true:
		fi = "Supercharged"
	$CanvasLayer/EngineSpecspnl/VBoxContainer/forcedindlbl.text = "Forced Induction: " + fi
	$CanvasLayer/EngineSpecspnl/VBoxContainer/reliabilitylbl.text = "Reliability: " + str(reliability)
	$CanvasLayer/EngineSpecspnl/VBoxContainer/reliabilityScorelbl.text = "Reliability rating: " + reliabilityScore
	$CanvasLayer/EngineSpecspnl/VBoxContainer/weightlbl.text = "Engine weight: " + str(engine_weight)
	calc_fuelEconomy()
	$CanvasLayer/EngineSpecspnl/VBoxContainer/fueleconlbl.text = "Fuel economy: " + Stringfueleconomy+ " L/100km"
	$CanvasLayer/EngineSpecspnl/VBoxContainer/fueleconlbl2.text = "Fuel economy: " + kmperl + " km per liter"
	
	#show correct sprites
	show_right_engine_sprite()
	show_correct_camshaft_sprite()
	show_components()
	show_fuelSystem_Sprite()
	show_forced_induction_sprite()
	show_intake_sprite()
	show_exhaust_sprites()
	populate_engine_list($CanvasLayer/loadEnginpnl/OptionButton)
	
func show_exhaust_sprites():
	var mani1 = Rect2(0,0,32,32)
	var mani2 = Rect2(32,0,32,32)
	var mani3 = Rect2(64,0,32,32)
	var mani4 = Rect2(64+32,0,32,32)
	var muffler1 = Rect2(0,32,32,32)
	var muffler2 = Rect2(32,32,32,32)
	var muffler3 = Rect2(64,32,32,32)
	var muffler4 = Rect2(64+32,32,32,32)
	var tip1 = Rect2(0,64,32,32)
	var tip2 = Rect2(32,64,32,32)
	
	match exhaustManifoldType:
		0:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/ExhaustMani.region_rect = mani1
		1:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/ExhaustMani.region_rect = mani2
		2:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/ExhaustMani.region_rect = mani3
		3:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/ExhaustMani.region_rect = mani4
	match muffler:
		0:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/muffler.region_rect = muffler1
		1:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/muffler.region_rect = muffler2
		2:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/muffler.region_rect = muffler3
		3:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/muffler.region_rect = muffler4
			
	match exhaustType:
		0:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/tip.region_rect = tip1
		1:
			$CanvasLayer/TabContainer/Exhaust/previewEngineBlockTypepnl/tip.region_rect = tip2
	
func show_intake_sprite():
	var intake1 = Rect2(0,0,32,32)
	var intake2 = Rect2(32,0,32,32)
	var intake3 = Rect2(64,0,32,32)
	var rad1 = Rect2(0,32,32,32)
	var rad2 = Rect2(32,32,32,32)
	var rad3 = Rect2(64,32,32,32)
	
	match intakeType:
		0:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/intake_sprite.region_rect = intake1
		1:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/intake_sprite.region_rect = intake2
		2:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/intake_sprite.region_rect = intake3
			
	match radiatorType:
		0:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/radiatureSprite.region_rect = rad1
		1:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/radiatureSprite.region_rect = rad2
		2:
			$CanvasLayer/TabContainer/Intake/previewEngineBlockTypepnl/radiatureSprite.region_rect = rad3
	
func show_forced_induction_sprite():
	var turbosprite = Rect2(0,0,64,64)
	var superchargersprite = Rect2(64,0,64,64)
	
	if turbo == true:
		$"CanvasLayer/TabContainer/Forced Induction/previewEngineBlockTypepnl/forcedInduction_Sprite".region_rect = turbosprite
		$"CanvasLayer/TabContainer/Forced Induction/previewEngineBlockTypepnl/forcedInduction_Sprite".visible = true
	
	elif supercharged == true:
		$"CanvasLayer/TabContainer/Forced Induction/previewEngineBlockTypepnl/forcedInduction_Sprite".region_rect = superchargersprite
		$"CanvasLayer/TabContainer/Forced Induction/previewEngineBlockTypepnl/forcedInduction_Sprite".visible = true
	
	else:
		$"CanvasLayer/TabContainer/Forced Induction/previewEngineBlockTypepnl/forcedInduction_Sprite".visible = false
	
func show_fuelSystem_Sprite():
	var carb = Rect2(0,0,32,32)
	var injection = Rect2(32,0,32,32)
	
	match fuelsystem:
		0:
			$"CanvasLayer/TabContainer/Fuel System/previewEngineBlockTypepnl/fuelSystem".region_rect = carb
		1:
			$"CanvasLayer/TabContainer/Fuel System/previewEngineBlockTypepnl/fuelSystem".region_rect = injection
	

func show_right_engine_sprite():
	var i3 = Rect2(0, 0, 64, 64)
	var i4 = Rect2(64, 0, 64, 64)
	var i5 = Rect2(0, 0, 128, 128)
	var i6 = Rect2(128, 0, 128, 128)
	var v4 = Rect2(0,0,84,84)
	var v6 = Rect2(84,0,84,84)
	var v8 = Rect2(84+84,0,84,84)
	var b4 = Rect2(0, 0, 64, 64)
	var b6 = Rect2(64, 0, 64, 64)
	var b8 = Rect2(64+64, 0, 64, 64)
	#show correct engin block
	if EngineType == 1:
		match cylinders:
			3:
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".region_rect = i3
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".visible = true
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".visible = false
			4:
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".region_rect = i4
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".visible = true
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".visible = false
			5:
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".visible = false
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".region_rect = i5
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".visible = true
			6:
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".visible = false
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".region_rect = i6
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".visible = true
			8:
				$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Can't have an inline 8 cylinder"
				$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(3)
	elif EngineType == 2:
		match cylinders:
			3:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Can't have an v3 engine"
				$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(1)
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".region_rect = v4
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = true
			4:
				hide_engine_sprites()
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".region_rect = v4
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = true
			5:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Can't have an v5 engine"
				$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(1)
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".region_rect = v4
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = true
			6:
				hide_engine_sprites()
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".region_rect = v6
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = true
			8:
				hide_engine_sprites()
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".region_rect = v8
				$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = true
	elif EngineType == 3:
		match cylinders:
			3:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Can't have a 3 cylinder boxer engine"
				$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(1)
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b4
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
			4:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b4
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
			5:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Can't have a 5 cylinder boxer engine"
				$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(1)
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b4
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
			6:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b6
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
			8:
				hide_engine_sprites()
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b8
				$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
	elif EngineType == 4:
		hide_engine_sprites()
		$CanvasLayer/TabContainer/EngineBlock/lblError.text = "Rotary engine not available"
		$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/EnginTypeOptbtn.select(2)
		$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.select(1)
		$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.region_rect = b4
		$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = true
		
	else:
		hide_engine_sprites()
	

func hide_engine_sprites():
	$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i3_i4".visible = false
	$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/inline i5_i6".visible = false
	$"CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/v-engines".visible = false
	$CanvasLayer/TabContainer/EngineBlock/previewEngineBlockTypepnl/boxer_engines.visible = false
	
func hide_cam_and_valve_sprites():
	$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.visible = false
	$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.visible = false
	
	
func show_correct_camshaft_sprite():
	var valves_2 = Rect2(0,0,32,32)
	var valves_3 = Rect2(32,0,32,32)
	var valves_4 = Rect2(64,0,32,32)
	var valves_5 = Rect2(64+32,0,32,32)
	var pushrod = Rect2(0,0,64,64)
	var sohc = Rect2(64,0,64,64)
	var dohc = Rect2(64+64,0,64,64)
	match  camType:
		0:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.region_rect = pushrod
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.visible = true
		1:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.region_rect = sohc
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.visible = true
		2:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.region_rect = dohc
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/camshafts.visible = true
			
	match numValve:
		0:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.region_rect = valves_2
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.visible = true
		1:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.region_rect = valves_3
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.visible = true
		2:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.region_rect = valves_4
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.visible = true
		3:
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.region_rect = valves_5
			$CanvasLayer/TabContainer/Production/previewEngineBlockTypepnl/valves.visible = true

func show_components():
	var piston1 = Rect2(0,0,32,32)
	var piston2 = Rect2(32,0,32,32)
	var piston3 = Rect2(64,0,32,32)
	var crank1 = Rect2(0,32,32,32)
	var crank2 = Rect2(32,32,32,32)
	var crank3 = Rect2(64,32,32,32)
	var conrod1 = Rect2(0,64,32,32)
	var conrod2 = Rect2(32,64,32,32)
	var conrod3 = Rect2(64,64,32,32)
	match pistonsType:
		0:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.region_rect = piston1
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.visible = true
		1:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.region_rect = piston2
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.visible = true
		2:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.region_rect = piston3
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.visible = true
	match crankshaftType:
		0:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.region_rect = crank1
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.visible = true
		1:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.region_rect = crank2
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.visible = true
		2:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.region_rect = crank3
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.visible = true
	match conrodsType:
		0:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.region_rect = conrod1
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.visible = true
		1:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.region_rect = conrod2
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.visible = true
		2:
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.region_rect = conrod3
			$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.visible = true
			

func hide_components_sprites():
	$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/Pistons.visible = false
	$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/conrods.visible = false
	$CanvasLayer/TabContainer/Components/previewEngineBlockTypepnl/crankshaft.visible = false

@warning_ignore("unused_parameter")
func _on_piston_diamater_slider_value_changed(value: float) -> void:
	update_UI()


@warning_ignore("unused_parameter")
func _on_piston_stroke_slider_2_value_changed(value: float) -> void:
	update_UI()

func get_engine_Info():
	#engine type
	EngineType = $CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/EnginTypeOptbtn.selected +1
	camType = $CanvasLayer/TabContainer/Production/CamshaftTypepnl/OptionButton.selected
	numValve = $CanvasLayer/TabContainer/Production/numValvespnl/OptionButton.selected
	
	#fuel
	fuelsystem = $"CanvasLayer/TabContainer/Fuel System/FuelSystempnl/EnginTypeOptbtn".selected
	fuelType = $"CanvasLayer/TabContainer/Fuel System/FuelTypepnl/EngineMatOptbtn".selected
	
	pistonStroke_mm = $CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonStrokeSlider2.value
	pistonDiameter_mm = $CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonDiamaterSlider.value
	rpm = $"CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/RPMSlider".value
	fuelmix = $"CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/FuelMixSlider".value
	
	#need to choose cylinders in order to calc displacement
	if $CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.selected == -1:
		lblErrorEngineBlock.text = "Choose amount of cylinders"
		return

	
	cylinders= int($CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.get_item_text(
		$CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn.selected
	).to_int())

	var volume_mm3: float = (PI / 4.0) * pow(pistonDiameter_mm, 2) * pistonStroke_mm * cylinders
	engineSize_L= volume_mm3 / 1_000_000.0
	$CanvasLayer/EngineSpecspnl/VBoxContainer/EngineCapacitylbl.text = "Engine capacity: %.2f L" % [engineSize_L]#display engine size in liter
	
	#component types
	pistonsType = $CanvasLayer/TabContainer/Components/Pistonspnl/OptionButton.selected
	conrodsType = $CanvasLayer/TabContainer/Components/Conrodspnl/OptionButton.selected
	crankshaftType = $CanvasLayer/TabContainer/Components/CrankShaftpnl/OptionButton.selected
	
	#forced induction
	#checks if turbo or supercharged
	if $"CanvasLayer/TabContainer/Forced Induction/turbopnl/OptionButton".selected == 1:
		turbo = true
		supercharged = false
	elif $"CanvasLayer/TabContainer/Forced Induction/turbopnl/OptionButton".selected == 2:
		supercharged = true
		turbo = false
	elif $"CanvasLayer/TabContainer/Forced Induction/turbopnl/OptionButton".selected == 0:
		turbo = false
		supercharged = false
		
	#can't have na setups on Forced induction
	if turbo == false and supercharged == false and $"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".selected >= 1:
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(0)
		$"CanvasLayer/TabContainer/Forced Induction/lblError".text = "Can't select type on a NA engine"
	if turbo == true:
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(1)
	if turbo == true and $"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".selected == 0:
		$"CanvasLayer/TabContainer/Forced Induction/lblError".text = "Can't select NA setup on turbo"
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(1)
	if supercharged == true:
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(1)
	if supercharged == true and $"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".selected == 2:
		$"CanvasLayer/TabContainer/Forced Induction/lblError".text = "Can't select twin setup on supercharger"
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(1)
	if supercharged == true and $"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".selected == 0:
		$"CanvasLayer/TabContainer/Forced Induction/lblError".text = "Can't select NA setup on supercharger"
		$"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".select(1)
		
	#forced induction types
	tsetup = $"CanvasLayer/TabContainer/Forced Induction/Typepnl/OptionButton".selected
	ttune = $"CanvasLayer/TabContainer/Forced Induction/Setuppnl/OptionButton".selected
	
	#intake
	intakeType = $CanvasLayer/TabContainer/Intake/intakepnl/OptionButton.selected
	radiatorType = $CanvasLayer/TabContainer/Intake/CoolingSystempnl/OptionButton.selected
	
	#exhausts
	exhaustType = $CanvasLayer/TabContainer/Exhaust/Exhaustpnl/OptionButton.selected
	exhaustManifoldType = $CanvasLayer/TabContainer/Exhaust/ExhaustManifoldpnl/OptionButton.selected
	catType = $CanvasLayer/TabContainer/Exhaust/Catpnl/OptionButton.selected
	if catType >= 1:
		cat = true
	else :
		cat = false
	muffler = $CanvasLayer/TabContainer/Exhaust/exhaustMufflerpnl/OptionButton.selected
		
		
	kw_per_l = kw_per_liter()
	kw = roundf(engineSize_L * kw_per_l)
	torque = roundf((kw * 9550) / rpm)
	#kw = roundf((torque*rpm)/9550)
	
	

func kw_per_liter() -> float:
	var base_kw_per_l: float = 0.0

	# --- Base power by cam type and valves ---
	match camType:
		0: # OHV
			match numValve:
				0: base_kw_per_l = 45 # 2-valve OHV average
				_:
					$CanvasLayer/TabContainer/Production/lblError.text = "OHV can only have 2 valves"
					$CanvasLayer/TabContainer/Production/numValvespnl/OptionButton.select(0)
					return 0
		1: # SOHC
			match numValve:
				0: base_kw_per_l = 60  # 2-valve SOHC
				1: base_kw_per_l = 70  # 3-valve
				2: base_kw_per_l = 80  # 4-valve
				3: base_kw_per_l = 95  # 5-valve
		2: # DOHC
			match numValve:
				0: base_kw_per_l = 65  # 2-valve DOHC
				1: base_kw_per_l = 75  # 3-valve
				2: base_kw_per_l = 90  # 4-valve
				3: base_kw_per_l = 110 # 5-valve

	# --- Forced Induction ---
	if turbo:
		match tsetup:
			0: base_kw_per_l *= 1.4 # single
			1: base_kw_per_l *= 1.6 # twin turbo
	if supercharged:
		base_kw_per_l *= 1.5

	# --- Variable Valve Timing ---
	if vvt:
		base_kw_per_l *= 1.15

	# --- Fuel System ---
	match fuelsystem:
		0: base_kw_per_l *= 0.95 # carburetor = less efficient
		1: base_kw_per_l *= 1.1  # fuel injection = better power

	# --- Fuel Type ---
	match fuelType:
		0: base_kw_per_l *= 1.0   # 95 octane (normal)
		1: base_kw_per_l *= 0.95  # 92 octane (lower quality)
		2: base_kw_per_l *= 0.9   # diesel (less kW per L)
		3: base_kw_per_l *= 1.25  # race fuel (high octane)

	# --- Intake Type ---
	match intakeType:
		0: base_kw_per_l *= 1.0   # normal
		1: base_kw_per_l *= 1.1   # performance
		2: base_kw_per_l *= 1.25  # race

	# --- Exhaust System ---
	match exhaustManifoldType:
		0: base_kw_per_l *= 1.0
		1: base_kw_per_l *= 1.1
		2: base_kw_per_l *= 1.2
		3: base_kw_per_l *= 1.35
	if exhaustType == 1: # twin
		base_kw_per_l *= 1.05
	if cat:
		match catType:
			1: base_kw_per_l *= 0.98 # normal cat restricts flow
			2: base_kw_per_l *= 1.02 # premium cat, less restriction
			
	match muffler:
		0: base_kw_per_l *= 0.9
		1: base_kw_per_l *= 0.88
		2: base_kw_per_l *= 1.1
		3: base_kw_per_l *= 1.35

	# --- Internal Components ---
	match pistonsType:
		0: base_kw_per_l *= 1.0
		1: base_kw_per_l *= 1.1
		2: base_kw_per_l *= 1.25
	match conrodsType:
		0: base_kw_per_l *= 1.0
		1: base_kw_per_l *= 1.05
		2: base_kw_per_l *= 1.15
	match crankshaftType:
		0: base_kw_per_l *= 1.0
		1: base_kw_per_l *= 1.1
		2: base_kw_per_l *= 1.2

	# --- Tuning Setup ---
	match ttune:
		0: base_kw_per_l *= 0.85 # eco
		1: base_kw_per_l *= 1.0  # normal
		2: base_kw_per_l *= 1.15 # sport
		3: base_kw_per_l *= 1.3  # race

	# --- Forced Induction Type ---
	match tsetup:
		0: base_kw_per_l *= 1.0
		1: base_kw_per_l *= 1.15 # single
		2: base_kw_per_l *= 1.3  # twin

	# --- Final fine-tuning factor based on fuel mix (0–100%) ---
	# Assume ideal mix = 50%, too rich or too lean reduces efficiency
	var mix_efficiency = 1.0 - abs((fuelmix - 50.0) / 100.0) * 0.2
	base_kw_per_l *= mix_efficiency

	# Round to 1 decimal for stability
	return roundf(base_kw_per_l * 10.0) / 10.0
	
# Calculate torque curve parameters based on engine configuration
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



func calc_reliability() -> int:
	var base_reliability = 100
	
	#engine block #cast iron, aluminum, Compacted Graphite Iron, Magnesium or Titanium
	match  EngineMat:
		0: base_reliability -= 0
		1: base_reliability -= 2
		2: base_reliability -= 5
		3: base_reliability -= 10
		4: base_reliability += 5
	match EngineType:
		1: base_reliability -= 0
		2: base_reliability -= 2
		3: base_reliability += 5
		4: base_reliability -= 10
	match cylinderMat:
		0: base_reliability -= 0
		1: base_reliability -= 2
		2: base_reliability -= 5
		3: base_reliability -= 10
		4: base_reliability += 5
	
	match camType:
		0: base_reliability -= 0
		1: base_reliability -= 2
		2: base_reliability -= 5
		
	base_reliability -= (numValve + 2) * 2 #it is plus 2 so it is the right value because input is 0,1,2,3 not 2,3,4,5
	
	#forced induction
	if turbo == true:
		base_reliability -= 10
	if supercharged == true:
		base_reliability -= 15
	if vvt == true:
		base_reliability -= 5
	
	#fuel stuff
	match  fuelsystem:
		0: base_reliability -= 20
		1: base_reliability += 10
	match fuelType:
		0: base_reliability += 0  # 95 octane
		1: base_reliability += 3  # 93 octane burns cooler
		2: base_reliability += 10 # diesel, low RPM, strong
		3: base_reliability -= 10 # race fuel, high temp
		
	var mix_offset = abs(fuelmix - 50)
	base_reliability -= mix_offset * 0.2  # 10% off center = -2 reliability
		
	#components
	match pistonsType:
		0: base_reliability += 0
		1: base_reliability += 5
		2: base_reliability += 10

	match conrodsType:
		0: base_reliability += 0
		1: base_reliability += 3
		2: base_reliability += 7

	match crankshaftType:
		0: base_reliability += 0
		1: base_reliability += 4
		2: base_reliability += 8
	
	#turbo tunes
	match ttune:
		0: base_reliability += 10 # eco
		1: base_reliability += 0  # normal
		2: base_reliability -= 5  # sport
		3: base_reliability -= 15 # race
		
	#exhaust
	match exhaustManifoldType:
		0: base_reliability += 0
		1: base_reliability += 2
		2: base_reliability += 5
		3: base_reliability -= 2
		
	if cat == true:
		base_reliability += 2
		if catType == 2:
			base_reliability += 3
			
	match muffler:
		0: base_reliability -= 4
		1: base_reliability -= 2
		2: base_reliability += 5
		3: base_reliability += 2
			
	#intake
	match intakeType:
		0: base_reliability += 0
		1: base_reliability += 4
		2: base_reliability += 8
	
	match radiatorType:
		0: base_reliability -= 10
		1: base_reliability -= 2
		2: base_reliability += 8
		
	if oilCooler == true:
		base_reliability += 5
	
	base_reliability = clamp(base_reliability, 10, 100)
	
	if base_reliability >= 75:
		reliabilityScore = "Excellent"
	elif base_reliability >= 60:
		reliabilityScore = "Good"
	elif base_reliability >= 50:
		reliabilityScore = "Alright"
	elif base_reliability >= 40:
		reliabilityScore = "Not Good"
	elif base_reliability >= 30:
		reliabilityScore = "Bad"
	elif base_reliability <= 30:
		reliabilityScore = "Very Bad"

	return base_reliability
	
func calc_weight():
	var base_weight: float = 0.0
	var weight_m: float = 0.0
	var extraweight: float = 0.0
	match  EngineMat: #cast iron, aluminum, Compacted Graphite Iron, Magnesium or Titanium
		0: base_weight = 50
		1: base_weight = 35
		2: base_weight = 40
		3: base_weight = 30
		4: base_weight = 45
	match EngineType:
		1: weight_m = 1.0
		2: weight_m = 1.1
		3: weight_m = 0.9
		4: weight_m = 0.7
	match cylinderMat:
		0: base_weight += 5
		1: base_weight += 3
		2: base_weight += 2.5
		3: base_weight += 2
		4: base_weight += 4
	match camType:
		0: base_weight += 0
		1: base_weight += 1
		2: base_weight += 2
	match numValve:
		0: base_weight += 0.2
		1: base_weight += 0.3
		2: base_weight += 0.4
		3: base_weight += 0.5
		
	#forced induction
	if turbo == true:
		extraweight += 50
	if supercharged == true:
		extraweight += 30
		
	#intake
	match radiatorType:#small, medium or race
		0: extraweight += 20
		1: extraweight += 40
		2: extraweight += 60
		
	if oilCooler == true:
		extraweight += 5
	
	engine_weight = round((base_weight * engineSize_L * cylinders * weight_m ) + extraweight)
	
func calc_fuelEconomy():
	var tune_factor: float = 1.0
	var base_km_per_liter: float = 0
	match ttune:#eco, normal, sport or race
		0: tune_factor = 0.8
		0: tune_factor = 1.0
		0: tune_factor = 1.4
		0: tune_factor = 1.8
	
	
	fueleconomy = ((engineSize_L*0.5) / (reliability/100)) * tune_factor
	Stringfueleconomy = "%.2f" % fueleconomy
	base_km_per_liter = 100 / fueleconomy
	kmperl = "%.2f" % base_km_per_liter
	
# Dyno graph updates


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
	var line_torque = $CanvasLayer/TabContainer/Confirmation/curvespnl/TorqueLine
	var line_power = $CanvasLayer/TabContainer/Confirmation/curvespnl/PowerLine
	var graph_bg = $CanvasLayer/TabContainer/Confirmation/curvespnl/GraphBackground

	update_dyno_graph(line_torque, line_power, graph_bg, $CanvasLayer/TabContainer/Confirmation/curvespnl/RPM_Marker,$CanvasLayer/TabContainer/Confirmation/curvespnl/lblCurrentTorque,$CanvasLayer/TabContainer/Confirmation/curvespnl/lblCurrentPower)


@warning_ignore("unused_parameter")
func _on_cylinder_optbtn_item_selected(index: int) -> void:
	update_UI()

@warning_ignore("unused_parameter")
func _on_engin_type_optbtn_item_selected(index: int) -> void:
	update_UI()


@warning_ignore("unused_parameter")
func _on_engine_mat_optbtn_item_selected(index: int) -> void:
	update_UI()


@warning_ignore("unused_parameter")
func _on_option_button_item_selected(index: int) -> void:
	update_UI()


@warning_ignore("unused_parameter")
func _on_rpm_slider_value_changed(value: float) -> void:
	update_UI()


@warning_ignore("unused_parameter")
func _on_fuel_mix_slider_value_changed(value: float) -> void:
	update_UI()

#vvt button
func _on_check_button_pressed() -> void:
	if vvt == false:
		vvt = true
	else:
		vvt = false
	update_UI()


func _on_oil_Cooler_check_button_pressed() -> void:
	if oilCooler == false:
		oilCooler = true
	else:
		oilCooler = false
	update_UI()


func _on_current_rpm_value_changed(value: float) -> void:
	@warning_ignore("narrowing_conversion")
	currentRPM = value
	update_dyno_for_current_rpm()
	update_UI()

func populate_engine_list(option_button: OptionButton) -> void:
	option_button.clear()  # remove any existing items
	
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
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error: Could not open engines folder."

		
# Save function
func save_engine_to_file(file_name: String) -> void:
	var folder = "res://engines/"
	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)
	
	var data: Dictionary = {
		"engineSize_L": engineSize_L,
		"cylinders": cylinders,
		"pistonStroke_mm": pistonStroke_mm,
		"pistonDiameter_mm": pistonDiameter_mm,
		"EngineMat": EngineMat,
		"cylinderMat": cylinderMat,
		"EngineType": EngineType,
		"engineCost": engineCost,
		"extraCost": extraCost,
		"baseMaterialCost": baseMaterialCost,
		"complexity_Multiplier": complexity_Multiplier,
		"camType": camType,
		"kw_per_l": kw_per_l,
		"kw": kw,
		"numValve": numValve,
		"vvt": vvt,
		"turbo": turbo,
		"supercharged": supercharged,
		"tsetup": tsetup,
		"ttune": ttune,
		"torque": torque,
		"reliability": reliability,
		"reliabilityScore": reliabilityScore,
		"engine_weight": engine_weight,
		"max_kw": max_kw,
		"max_Torque_nm": max_Torque_nm,
		"pistonsType": pistonsType,
		"conrodsType": conrodsType,
		"crankshaftType": crankshaftType,
		"fuelsystem": fuelsystem,
		"fuelType": fuelType,
		"rpm": rpm,
		"currentRPM": currentRPM,
		"fuelmix": fuelmix,
		"fueleconomy": fueleconomy,
		"Stringfueleconomy": Stringfueleconomy,
		"kmperl": kmperl,
		"intakeType": intakeType,
		"radiatorType": radiatorType,
		"oilCooler": oilCooler,
		"cat": cat,
		"catType": catType,
		"exhaustType": exhaustType,
		"exhaustManifoldType": exhaustManifoldType,
		"muffler": muffler
	}

	var json_text = JSON.stringify(data, "\t") # formatted JSON
	var path = folder + file_name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Saved successfully!"
		print("Saved engine to: ", path)
	else:
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error saving file!"
	update_UI()

# Load function
func load_engine_from_file(file_name: String) -> void:
	var path := "res://engines/" + file_name + ".json"

	# --- Check if file exists ---
	if not FileAccess.file_exists(path):
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error: Engine file not found at " + path
		return

	# --- Open file ---
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error: Could not open engine file."
		return

	var text := file.get_as_text()
	file.close()

	# --- Parse JSON ---
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error parsing JSON file: " + str(err)
		return

	var data: Dictionary = json.data as Dictionary
	if data.is_empty():
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Error: Loaded data is empty!"
		return

	# --- Assign all variables from file ---
	engineSize_L = data.get("engineSize_L", 0.0)
	cylinders = data.get("cylinders", 0)
	pistonStroke_mm = data.get("pistonStroke_mm", 0.0)
	pistonDiameter_mm = data.get("pistonDiameter_mm", 0.0)
	EngineMat = data.get("EngineMat", 0)
	cylinderMat = data.get("cylinderMat", 0)
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

	$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Engine loaded successfully: " + file_name
	print("✅ Loaded engine from:", path)
	update_UI()


func _on_Load_button_pressed() -> void:
	var selected = $CanvasLayer/loadEnginpnl/OptionButton.get_selected_id()
	if selected == -1:
		$CanvasLayer/loadEnginpnl/lblerrorloading.text = "Please select an engine first!"
		return
	
	var file_name = $CanvasLayer/loadEnginpnl/OptionButton.get_item_text(selected)
	load_engine_from_file(file_name)
	update_engine_ui()
	#update_UI()
	
# --- Helper functions (top-level, outside of update_engine_ui) ---
func select_by_text(option_button: OptionButton, text_value: String) -> void:
	if option_button == null:
		return
	for i in range(option_button.item_count):
		if str(option_button.get_item_text(i)).to_lower() == str(text_value).to_lower():
			option_button.select(i)
			return
	print("⚠️ No match for", text_value, "in", option_button.name)

func select_by_number(option_button: OptionButton, num_value: float) -> void:
	if option_button == null:
		return
	for i in range(option_button.item_count):
		var item_text = option_button.get_item_text(i)
		if item_text.is_valid_int() and int(item_text) == int(num_value):
			option_button.select(i)
			return
		elif item_text.is_valid_float() and float(item_text) == float(num_value):
			option_button.select(i)
			return
	print("⚠️ No numeric match for", num_value, "in", option_button.name)


# --- MAIN FUNCTION ---
func update_engine_ui() -> void:
	print("🔄 Updating UI with loaded engine data...")

	# --- Lookup dictionaries ---
	var ENGINE_MATERIALS = {0:"Cast Iron",1:"Aluminum",2:"Compacted Graphite Iron",3:"Magnesium",4:"Titanium"}
	var CYLINDER_MATERIALS = ENGINE_MATERIALS
	var ENGINE_TYPES = {0:"Inline",1:"V-Type",2:"Boxer",3:"Rotary"}
	var CYLINDERS = {0:"3",1:"4",2:"5",3:"6",4:"8"}
	var CAM_TYPES = {0:"Pushrod",1:"Single Overhead Cam",2:"Dual Overhead Cam"}
	var TURBO_TYPES = {0:"NA",1:"Turbo",2:"Supercharger"}
	var FUEL_SYSTEMS = {0:"Carburetor",1:"Fuel injection"}
	var FUEL_TYPES = {0:"95",1:"92",2:"Diesel",3:"Race"}
	var INTAKES = {0:"Normal",1:"Performance",2:"Race"}
	var RADIATORS = {0:"Small",1:"Medium",2:"Race"}
	var EXHAUSTS = {0:"Single",1:"Twin"}
	var MANIFOLDS = {0:"Normal",1:"Sports",2:"Performance",3:"Race"}
	var MUFFLERS = {0:"Small",1:"Big",2:"Freeflow",3:"Straight Pipe"}
	var CAT_TYPES = {0:"None",1:"Normal",2:"Premium"}
	var CYLINDERS_TEXT = {0:"3", 1:"4", 2:"5", 3:"6", 4:"8"}

	# --- ENGINE BLOCK ---
	if has_node("CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/EngineMatOptbtn"):
		select_by_text(get_node("CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/EngineMatOptbtn"), ENGINE_MATERIALS.get(EngineMat, "Cast Iron"))
	if has_node("CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/CylinderMatOptbtn2"):
		select_by_text(get_node("CanvasLayer/TabContainer/EngineBlock/EngineMaterialspnl/CylinderMatOptbtn2"), CYLINDER_MATERIALS.get(cylinderMat, "Cast Iron"))
	
	if has_node("CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/EnginTypeOptbtn"):
		select_by_text(get_node("CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/EnginTypeOptbtn"), ENGINE_TYPES.get(EngineType, "Inline"))
	var cylinder_text = CYLINDERS_TEXT.get(cylinders, str(cylinders))
	select_by_text(get_node("CanvasLayer/TabContainer/EngineBlock/EngineTypepnl/CylinderOptbtn"), cylinder_text)
	if has_node("CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonStrokeSlider2"):
		get_node("CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonStrokeSlider2").value = pistonStroke_mm
	if has_node("CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonDiamaterSlider"):
		get_node("CanvasLayer/TabContainer/EngineBlock/EngineSizepnl/PistonDiamaterSlider").value = pistonDiameter_mm
	

	# --- PRODUCTION ---
	if has_node("CanvasLayer/TabContainer/Production/CamshaftTypepnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Production/CamshaftTypepnl/OptionButton"), CAM_TYPES.get(camType, "Pushrod"))
	if has_node("CanvasLayer/TabContainer/Production/numValvespnl/OptionButton"):
		select_by_number(get_node("CanvasLayer/TabContainer/Production/numValvespnl/OptionButton"), numValve)
	if has_node("CanvasLayer/TabContainer/Production/vvtpnl/CheckButton"):
		get_node("CanvasLayer/TabContainer/Production/vvtpnl/CheckButton").button_pressed  = vvt

	# --- FORCED INDUCTION ---
	if has_node("CanvasLayer/TabContainer/Forced Induction/turbopnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Forced Induction/turbopnl/OptionButton"), TURBO_TYPES.get(tsetup, "NA"))

	# --- FUEL ---
	if has_node("CanvasLayer/TabContainer/Fuel System/FuelTypepnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Fuel System/FuelTypepnl/OptionButton"), FUEL_TYPES.get(fuelType, "95"))
	if has_node("CanvasLayer/TabContainer/Fuel System/FuelSystempnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Fuel System/FuelSystempnl/OptionButton"), FUEL_SYSTEMS.get(fuelsystem, "Carburetor"))
	if has_node("CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/RPMSlider"):
		get_node("CanvasLayer/TabContainer/Fuel System/Fuelsliderspnl/RPMSlider").value = rpm

	# --- INTAKE ---
	if has_node("CanvasLayer/TabContainer/Intake/intakepnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Intake/intakepnl/OptionButton"), INTAKES.get(intakeType, "Normal"))
	if has_node("CanvasLayer/TabContainer/Intake/CoolingSystempnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Intake/CoolingSystempnl/OptionButton"), RADIATORS.get(radiatorType, "Small"))
	if has_node("CanvasLayer/TabContainer/Intake/CoolingSystempnl/CheckButton"):
		get_node("CanvasLayer/TabContainer/Intake/CoolingSystempnl/CheckButton").button_pressed  = oilCooler

	# --- EXHAUST ---
	if has_node("CanvasLayer/TabContainer/Exhaust/Exhaustpnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Exhaust/Exhaustpnl/OptionButton"), EXHAUSTS.get(exhaustType, "Single"))
	if has_node("CanvasLayer/TabContainer/Exhaust/ExhaustManifoldpnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Exhaust/ExhaustManifoldpnl/OptionButton"), MANIFOLDS.get(exhaustManifoldType, "Normal"))
	if has_node("CanvasLayer/TabContainer/Exhaust/exhaustMufflerpnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Exhaust/exhaustMufflerpnl/OptionButton"), MUFFLERS.get(muffler, "Small"))
	if has_node("CanvasLayer/TabContainer/Exhaust/Catpnl/OptionButton"):
		select_by_text(get_node("CanvasLayer/TabContainer/Exhaust/Catpnl/OptionButton"), CAT_TYPES.get(catType, "None"))

	# --- DISPLAY LABELS ---
	if has_node("CanvasLayer/EngineSpecspnl/VBoxContainer/reliabilitylbl"):
		get_node("CanvasLayer/EngineSpecspnl/VBoxContainer/reliabilitylbl").text = str(reliabilityScore)
	if has_node("CanvasLayer/EngineSpecspnl/VBoxContainer/weightlbl"):
		get_node("CanvasLayer/EngineSpecspnl/VBoxContainer/weightlbl").text = str(engine_weight) + " kg"
	if has_node("CanvasLayer/EngineSpecspnl/VBoxContainer/kwlbl"):
		get_node("CanvasLayer/EngineSpecspnl/VBoxContainer/kwlbl").text = str(max_kw) + " kW"
	if has_node("CanvasLayer/EngineSpecspnl/VBoxContainer/torquelbl"):
		get_node("CanvasLayer/EngineSpecspnl/VBoxContainer/torquelbl").text = str(max_Torque_nm) + " Nm"

	print("✅ UI updated successfully with mapped labels.")


func _on_savebtn_pressed() -> void:
	var file_name: String = $CanvasLayer/TabContainer/Confirmation/LineEdit.text.strip_edges()
	
	if file_name == "":
		lblErrorEngineBlock.text = "Error: Please enter a file name."
		return

	var file_path: String = "res://engines/%s.json" % file_name

	var engine_data: Dictionary = {
		"engineSize_L": engineSize_L,
		"cylinders": cylinders,
		"pistonStroke_mm": pistonStroke_mm,
		"pistonDiameter_mm": pistonDiameter_mm,
		"EngineMat": EngineMat,
		"cylinderMat": cylinderMat,
		"EngineType": EngineType,
		"engineCost": engineCost,
		"extraCost": extraCost,
		"baseMaterialCost": baseMaterialCost,
		"complexity_Multiplier": complexity_Multiplier,
		"camType": camType,
		"kw_per_l": kw_per_l,
		"kw": kw,
		"numValve": numValve,
		"vvt": vvt,
		"turbo": turbo,
		"supercharged": supercharged,
		"tsetup": tsetup,
		"ttune": ttune,
		"torque": torque,
		"reliability": reliability,
		"reliabilityScore": reliabilityScore,
		"engine_weight": engine_weight,
		"max_kw": max_kw,
		"max_Torque_nm": max_Torque_nm,
		"pistonsType": pistonsType,
		"conrodsType": conrodsType,
		"crankshaftType": crankshaftType,
		"fuelsystem": fuelsystem,
		"fuelType": fuelType,
		"rpm": rpm,
		"currentRPM": currentRPM,
		"fuelmix": fuelmix,
		"fueleconomy": fueleconomy,
		"Stringfueleconomy": Stringfueleconomy,
		"kmperl": kmperl,
		"intakeType": intakeType,
		"radiatorType": radiatorType,
		"oilCooler": oilCooler,
		"cat": cat,
		"catType": catType,
		"exhaustType": exhaustType,
		"exhaustManifoldType": exhaustManifoldType,
		"muffler": muffler
	}

	var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	if file:
		var json_text: String = JSON.stringify(engine_data, "\t")  # pretty print
		file.store_string(json_text)
		file.close()
		lblErrorEngineBlock.text = "Engine saved successfully!"
	else:
		lblErrorEngineBlock.text = "Error: Could not open file for writing."
		
	update_UI()
