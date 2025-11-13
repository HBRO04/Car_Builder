extends Node2D


@onready var my_car_prefab = preload("res://scenes/car_scene_without_camera.tscn")
var current_car

@onready var choose_car_panel = $chooseCarpnl


func _ready() -> void:
	current_car = my_car_prefab.instantiate()
	current_car.position = Vector2(700, 00)
	add_child(current_car)
	choose_car_panel.connect("loaddyno",Callable(self, "reload_car"))

func reload_car():
	remove_child(current_car)
	current_car = my_car_prefab.instantiate()
	current_car.position = Vector2(700, 00)
	add_child(current_car)
	
