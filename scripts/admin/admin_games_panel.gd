extends Control

## Admin Games Panel
## Handles game monitoring and statistics

signal refresh_requested

# UI References
@onready var games_count_label: Label = get_node_or_null("VBox/StatsContainer/GamesCountLabel")
@onready var players_count_label: Label = get_node_or_null("VBox/StatsContainer/PlayersCountLabel")
@onready var refresh_button: Button = get_node_or_null("VBox/HeaderContainer/RefreshButton")
@onready var games_list: VBoxContainer = get_node_or_null("VBox/ScrollContainer/GamesList")

func _ready() -> void:
	setup_ui()
	setup_connections()

func setup_ui() -> void:
	# Initialize labels
	if games_count_label:
		games_count_label.text = "Active Games: 0"
	if players_count_label:
		players_count_label.text = "Total Players: 0"

func setup_connections() -> void:
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_button_pressed)

func _on_refresh_button_pressed() -> void:
	refresh_requested.emit()
	
	# Visual feedback
	if refresh_button:
		refresh_button.text = "Refreshing..."
		refresh_button.disabled = true
		
		# Reset button after a short delay
		await get_tree().create_timer(1.0).timeout
		refresh_button.text = "Refresh"
		refresh_button.disabled = false

func update_data(dashboard_data: Dictionary) -> void:
	var current_state = dashboard_data.get("current_state", {})
	
	# Update statistics
	var active_games = current_state.get("active_games", 0)
	var active_players = current_state.get("active_players", 0)
	
	if games_count_label:
		games_count_label.text = "Active Games: " + str(active_games)
	
	if players_count_label:
		players_count_label.text = "Total Players: " + str(active_players)
	
	# Update games list
	update_games_list(current_state.get("game_details", []))

func update_games_list(game_details: Array) -> void:
	if not games_list:
		return
	
	# Clear existing games
	for child in games_list.get_children():
		child.queue_free()
	
	# Add games or show empty state
	if game_details.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No active games"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.modulate = Color.GRAY
		games_list.add_child(empty_label)
	else:
		for game_data in game_details:
			if game_data is Dictionary:
				var game_item = create_game_item(game_data)
				games_list.add_child(game_item)

func create_game_item(game_data: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	
	# Style the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style_box.border_color = Color(0.4, 0.4, 0.6)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	container.add_theme_stylebox_override("panel", style_box)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Game code and status
	var game_code = game_data.get("code", "Unknown")
	var is_started = game_data.get("started", false)
	var status_text = "STARTED" if is_started else "WAITING"
	
	var title_label = Label.new()
	title_label.text = "Game: %s (%s)" % [game_code, status_text]
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.modulate = Color.GREEN if is_started else Color.YELLOW
	vbox.add_child(title_label)
	
	# Host and player info
	var player_count = game_data.get("players", 0)
	var host_name = game_data.get("host", "Unknown")
	
	var info_label = Label.new()
	info_label.text = "Host: %s | Players: %d" % [host_name, player_count]
	vbox.add_child(info_label)
	
	# Creation time
	var created_ago = game_data.get("created_ago", 0.0)
	var time_label = Label.new()
	time_label.text = "Created: %s ago" % format_time_ago(created_ago)
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.modulate = Color.GRAY
	vbox.add_child(time_label)
	
	return container

func format_time_ago(seconds: float) -> String:
	var total_seconds = int(seconds)
	@warning_ignore("integer_division")
	var days = total_seconds / 86400
	@warning_ignore("integer_division")
	var hours = (total_seconds % 86400) / 3600
	@warning_ignore("integer_division")
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	
	if days > 0:
		return "%dd %dh %dm %ds" % [days, hours, minutes, secs]
	elif hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs
