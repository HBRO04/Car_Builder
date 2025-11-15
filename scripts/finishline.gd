extends Area2D

# Race result tracking
var race_finished: bool = false
var winner: String = ""  # "player" or "opponent"
var player_finish_time: float = -1.0
var opponent_finish_time: float = -1.0

# Signals for other systems to listen to
signal race_completed(winner: String, player_time: float, opponent_time: float)
signal player_won(time: float)
signal opponent_won(time: float)

func _ready() -> void:
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if race_finished:
		return  
	
	# Check who won
	if body.is_in_group("car"):
		handle_player_finish(body)
	elif body.is_in_group("opponent"):
		handle_opponent_finish(body)

func handle_player_finish(player_body: Node2D) -> void:
	# Get player's race time if available
	if player_body.has_method("get_race_stats"):
		var stats = player_body.get_race_stats()
		player_finish_time = stats.get("time", 0.0)
	else:
		player_finish_time = 0.0
	
	
	# If opponent hasn't finished yet, player wins
	if opponent_finish_time < 0:
		declare_winner("player")
	else:
		# Both finished, compare times
		compare_times()

func handle_opponent_finish(opponent_body: Node2D) -> void:
	# Get opponent's race time if available
	if opponent_body.has_method("get_race_stats"):
		var stats = opponent_body.get_race_stats()
		opponent_finish_time = stats.get("time", 0.0)
	else:
		opponent_finish_time = 0.0
	
	# If player hasn't finished yet, opponent wins
	if player_finish_time < 0:
		declare_winner("opponent")
	else:
		compare_times()

func compare_times() -> void:
	# Both cars finished, determine winner by time
	if player_finish_time < opponent_finish_time:
		declare_winner("player")
	else:
		declare_winner("opponent")

func declare_winner(who: String) -> void:
	if race_finished:
		return  # Already declared
	
	race_finished = true
	winner = who
	
	if winner == "player":
		if opponent_finish_time > 0:
			@warning_ignore("unused_variable")
			var time_diff = opponent_finish_time - player_finish_time
		emit_signal("player_won", player_finish_time)
	else:
		if player_finish_time > 0:
			@warning_ignore("unused_variable")
			var time_diff = player_finish_time - opponent_finish_time
		emit_signal("opponent_won", opponent_finish_time)

	
	# Emit general race completed signal
	emit_signal("race_completed", winner, player_finish_time, opponent_finish_time)
	
	# Show result screen after a short delay
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(show_result_screen)

func show_result_screen() -> void:
	# You can change this to load your custom win/lose screens
	if winner == "player":
		show_win_screen()
	else:
		show_lose_screen()

func show_win_screen() -> void:
	create_result_overlay("YOU WIN!", Color(0.2, 1.0, 0.2))

func show_lose_screen() -> void:
	create_result_overlay("YOU LOSE!", Color(1.0, 0.2, 0.2))

func create_result_overlay(message: String, color: Color) -> void:
	# Create a simple overlay showing the result
	var overlay = CanvasLayer.new()
	overlay.layer = 100 
	
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	
	# Result text
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-200, -100)
	label.size = Vector2(400, 100)
	
	# Make text bigger and colored
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", color)
	overlay.add_child(label)
	
	# Time info
	var time_label = Label.new()
	if winner == "player":
		time_label.text = "Your time: %.2f seconds" % player_finish_time + "\nOpponent: %.2f seconds" % opponent_finish_time
		if opponent_finish_time > 0:
			time_label.text += "\nOpponent: %.2f seconds" % opponent_finish_time + "\nYour time: %.2f seconds" % player_finish_time
	else:
		time_label.text = "Opponent time: %.2f seconds" % opponent_finish_time + "\nYour time: %.2f seconds" % player_finish_time
		if player_finish_time > 0:
			time_label.text += "\nYour time: %.2f seconds" % player_finish_time + "\nOpponent: %.2f seconds" % opponent_finish_time
	
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.set_anchors_preset(Control.PRESET_CENTER)
	time_label.position = Vector2(-200, 20)
	time_label.size = Vector2(400, 100)
	time_label.add_theme_font_size_override("font_size", 32)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	overlay.add_child(time_label)

	get_tree().root.add_child(overlay)
	
	# Remove overlay after 3.5 seconds
	var timer = get_tree().create_timer(3.5)
	timer.timeout.connect(func():
		if overlay and is_instance_valid(overlay):
			overlay.queue_free()
	)

# Public methods to check race status
func is_race_finished() -> bool:
	return race_finished

func get_winner() -> String:
	return winner

func get_race_results() -> Dictionary:
	return {
		"finished": race_finished,
		"winner": winner,
		"player_time": player_finish_time,
		"opponent_time": opponent_finish_time,
		"time_difference": abs(player_finish_time - opponent_finish_time) if player_finish_time > 0 and opponent_finish_time > 0 else 0.0
	}

# Optional: Reset race if you want to race again without reloading scene
func reset_race() -> void:
	race_finished = false
	winner = ""
	player_finish_time = -1.0
	opponent_finish_time = -1.0
