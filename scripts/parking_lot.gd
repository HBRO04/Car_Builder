extends Node2D


@onready var my_car_prefab = preload("res://scenes/car_scene_without_camera.tscn")
var current_car
var current_time: String = "Day"
var timer

@onready var choose_car_panel = $chooseCarpnl


func _ready() -> void:
	current_car = my_car_prefab.instantiate()
	current_car.position = Vector2(700, 560)
	add_child(current_car)
	choose_car_panel.connect("loaddyno",Callable(self, "reload_car"))
	timer = get_tree().create_timer(10)
	timer.timeout.connect(day_night_cycle)
	randomize()
	
	

func reload_car():
	remove_child(current_car)
	current_car = my_car_prefab.instantiate()
	current_car.position = Vector2(700, 560)
	add_child(current_car)
	
func choose_moon():
	var m1 = Rect2(0,0,128,128)
	var m2 = Rect2(128,0,128,128)
	var m3 = Rect2(0,128,128,128)
	var m4 = Rect2(128,128,128,128)
	var randmoon = randi_range(1,4)
	var moonName: String = "moon" + str(randmoon)
	match randmoon:
		1:$sky/moon.region_rect = m1
		2:$sky/moon.region_rect = m2
		3:$sky/moon.region_rect = m3
		4:$sky/moon.region_rect = m4
	$sky/moon/moon_move_and_shape.play(moonName)

#will later add rain and other weathers too
func day_night_cycle():
	match current_time:
		"Day": 
			current_time = "Night"
			$sky/Sprite2D.visible = false
			$sky/nightsky.visible = true
			choose_moon()
		"Night":
			current_time = "Day"
			$sky/Sprite2D.visible = true
			$sky/nightsky.visible = false
			
	timer = get_tree().create_timer(10)
	timer.timeout.connect(day_night_cycle)
	
