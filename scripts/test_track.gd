extends Node2D

func _ready() -> void:
	$track/robot/AnimationPlayer.play("start")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	$track/robot.visible = false
	
	
