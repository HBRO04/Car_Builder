extends Panel

@onready var car_builder_scene: PackedScene = preload("res://scenes/car_builder.tscn")
@onready var engine_builder_scene: PackedScene = preload("res://scenes/engine_builder.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(car_builder_scene)
	


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_packed(engine_builder_scene)


func _on_button_3_pressed() -> void:
	$"../chooseCarpnl/AnimationPlayer".play("slide_in")
	$"../chooseCarpnl/OptionButton".select(-1)
	$AnimationPlayer.play("slide_out")
	


func _on_button_4_pressed() -> void:
	$"../dynopnl/AnimationPlayer".play("open_dyno")
	$AnimationPlayer.play("slide_out")
	


func _on_close_dyno_button_pressed() -> void:
	$"../dynopnl/AnimationPlayer".play("close_dyno")
	$AnimationPlayer.play("start_up")
