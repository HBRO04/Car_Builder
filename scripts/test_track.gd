extends Node2D

signal race_over

func _ready() -> void:
	$track/robot/AnimationPlayer.play("start")
	
@warning_ignore("unused_parameter")
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	$track/robot.visible = false
	
	


func _on_finishline_body_entered(body: Node2D) -> void:
	if body.is_in_group("car"):
		emit_signal("race_over")
