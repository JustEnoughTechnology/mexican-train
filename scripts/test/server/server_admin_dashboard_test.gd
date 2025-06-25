extends Control

## Server Admin Dashboard for Mexican Train
## Provides comprehensive server monitoring and administration interface

# UI references - use get_node() calls with error handling instead of @onready
var login_panel: Panel
var dashboard_panel: Panel
var email_input: LineEdit
var password_input: LineEdit
var login_button: Button
var status_label: Label

# Dashboard UI references
var admin_info_label: Label
var server_status_label: Label
var version_label: Label
var uptime_label: Label
var active_games_label: Label
var active_players_label: Label

var memory_label: Label
var network_label: Label
var platform_label: Label

var games_list: VBoxContainer
var refresh_button: Button
var logout_button: Button
var server_control_button: Button

# State
var current_admin_email: String = ""
var refresh_timer: Timer
var network_manager: NetworkManager

func _ready() -> void:
	get_window().title = "Mexican Train - Server Administration"
	
	# Debug: Check if all UI nodes are properly found
	print("=== Admin Dashboard Node Check ===")
	print("login_panel: ", login_panel)
	print("dashboard_panel: ", dashboard_panel)
	print("email_input: ", email_input)
	print("password_input: ", password_input)
	print("login_button: ", login_button)
	print("status_label: ", status_label)
	print("=== End Node Check ===")
	
	# Setup network manager
	network_manager = NetworkManager
	
	# Connect signals
	login_button.pressed.connect(_on_login_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	server_control_button.pressed.connect(_on_server_control_pressed)
	
	# Connect ServerAdmin signals
	ServerAdmin.admin_authenticated.connect(_on_admin_authenticated)
	ServerAdmin.admin_access_denied.connect(_on_admin_access_denied)
	ServerAdmin.server_metrics_updated.connect(_on_server_metrics_updated)
	
	# Setup auto-refresh timer
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 10.0  # Refresh every 10 seconds
	refresh_timer.timeout.connect(_update_dashboard_data)
	add_child(refresh_timer)
		# Start with login panel visible
	_show_login_panel()
	
	# Pre-fill dev credentials for testing (only if nodes exist)
	if email_input and password_input:
		email_input.text = "admin@mexicantrain.local"
		password_input.text = "admin123"
	else:
		print("WARNING: Cannot pre-fill credentials - input nodes are null")

func _show_login_panel() -> void:
	if login_panel:
		login_panel.visible = true
	if dashboard_panel:
		dashboard_panel.visible = false
	if status_label:
		status_label.text = "Please enter credentials to access server administration"
		status_label.modulate = Color.WHITE

func _show_dashboard_panel() -> void:
	login_panel.visible = false
	dashboard_panel.visible = true
	refresh_timer.start()
	_update_dashboard_data()

func _on_login_pressed() -> void:
	# Check if input fields are properly initialized
	if not email_input:
		print("ERROR: email_input is null!")
		_show_login_error("Internal error: email input not found")
		return
	if not password_input:
		print("ERROR: password_input is null!")
		_show_login_error("Internal error: password input not found")
		return
		
	var email = email_input.text.strip_edges()
	var password = password_input.text
	
	if email.is_empty():
		_show_login_error("Please enter an email address")
		return
	
	if password.is_empty():
		_show_login_error("Please enter a password")
		return
	
	status_label.text = "Authenticating..."
	status_label.modulate = Color.YELLOW
	login_button.disabled = true
	
	# Attempt authentication
	ServerAdmin.authenticate_admin(email, password)

func _on_admin_authenticated(admin_email: String) -> void:
	current_admin_email = admin_email
	print("Admin dashboard: Authentication successful for %s" % admin_email)
	_show_dashboard_panel()

func _on_admin_access_denied(_email: String, reason: String) -> void:
	_show_login_error("Access denied: %s" % reason)
	login_button.disabled = false

func _show_login_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = Color.RED
	login_button.disabled = false

func _on_refresh_pressed() -> void:
	_update_dashboard_data()
	refresh_button.text = "Refreshed!"
	refresh_button.disabled = true
	
	# Reset button after a short delay
	await get_tree().create_timer(1.0).timeout
	refresh_button.text = "Refresh Data"
	refresh_button.disabled = false

func _on_logout_pressed() -> void:
	ServerAdmin.logout_admin(current_admin_email)
	current_admin_email = ""
	refresh_timer.stop()
	_show_login_panel()
	
	# Clear sensitive data
	password_input.text = ""

func _on_server_control_pressed() -> void:
	if network_manager.is_server:
		# Stop server
		network_manager.disconnect_from_server()
		server_control_button.text = "Start Server"
		server_control_button.modulate = Color.GREEN
	else:
		# Start server
		if network_manager.start_server():
			server_control_button.text = "Stop Server"
			server_control_button.modulate = Color.RED
		else:
			_show_temporary_message("Failed to start server!")

func _update_dashboard_data() -> void:
	if current_admin_email.is_empty():
		return
	
	var dashboard_data = ServerAdmin.get_admin_dashboard_data(current_admin_email)
	
	if dashboard_data.has("error"):
		_show_login_error(dashboard_data.error)
		_show_login_panel()
		return
	
	_populate_dashboard(dashboard_data)

func _populate_dashboard(data: Dictionary) -> void:
	var admin_info = data.get("admin_info", {})
	var server_info = data.get("server_info", {})
	var current_state = data.get("current_state", {})
	var _statistics = data.get("statistics", {})
	var system_resources = data.get("system_resources", {})
	var network_status = data.get("network_status", {})
	
	# Update admin info
	admin_info_label.text = "Logged in as: %s" % admin_info.get("logged_in_as", "Unknown")
	
	# Update server information
	var server_running = network_status.get("server_running", false)
	server_status_label.text = "Server Status: %s" % ("RUNNING" if server_running else "STOPPED")
	server_status_label.modulate = Color.GREEN if server_running else Color.RED
	
	version_label.text = "Version: %s" % server_info.get("version", "Unknown")
	uptime_label.text = "Uptime: %s" % server_info.get("uptime_formatted", "Unknown")
	
	active_games_label.text = "Active Games: %d" % current_state.get("active_games", 0)
	active_players_label.text = "Active Players: %d" % current_state.get("active_players", 0)
	
	# Update system resources
	var memory_mb = system_resources.get("memory_usage_mb", 0)
	memory_label.text = "Memory Usage: %.1f MB" % memory_mb
	
	var port = network_status.get("default_port", "Unknown")
	network_label.text = "Network: Port %s" % port
	
	platform_label.text = "Platform: %s" % system_resources.get("platform", "Unknown")
	
	# Update server control button
	if server_running:
		server_control_button.text = "Stop Server"
		server_control_button.modulate = Color.RED
	else:
		server_control_button.text = "Start Server"
		server_control_button.modulate = Color.GREEN
	
	# Update games list
	_update_games_list(current_state.get("game_details", []))

func _update_games_list(game_details: Array) -> void:
	# Clear existing game entries
	for child in games_list.get_children():
		child.queue_free()
	
	if game_details.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No active games"
		no_games_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		games_list.add_child(no_games_label)
		return
	
	# Add game entries
	for game_data in game_details:
		var game_panel = _create_game_panel(game_data)
		games_list.add_child(game_panel)

func _create_game_panel(game_data: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.3, 0.8)
	style.border_color = Color(0.4, 0.5, 0.6, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	
	# Game code and status
	var title_label = Label.new()
	var game_code = game_data.get("code", "Unknown")
	var is_started = game_data.get("started", false)
	var status_text = "STARTED" if is_started else "WAITING"
	title_label.text = "Game: %s (%s)" % [game_code, status_text]
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.modulate = Color.GREEN if is_started else Color.YELLOW
	vbox.add_child(title_label)
	
	# Host and players
	var info_label = Label.new()
	var player_count = game_data.get("players", 0)
	var host_name = game_data.get("host", "Unknown")
	info_label.text = "Host: %s | Players: %d" % [host_name, player_count]
	vbox.add_child(info_label)
	
	# Time since creation
	var created_ago = game_data.get("created_ago", 0)
	var time_label = Label.new()
	time_label.text = "Created: %s ago" % ServerAdmin._format_uptime(created_ago)
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(time_label)
	
	return panel

func _on_server_metrics_updated(_metrics: Dictionary) -> void:
	# Auto-update dashboard when metrics are updated
	if dashboard_panel.visible and not current_admin_email.is_empty():
		var dashboard_data = ServerAdmin.get_admin_dashboard_data(current_admin_email)
		if not dashboard_data.has("error"):
			_populate_dashboard(dashboard_data)

func _show_temporary_message(message: String) -> void:
	var temp_label = Label.new()
	temp_label.text = message
	temp_label.modulate = Color.ORANGE
	temp_label.position = Vector2(20, 50)
	add_child(temp_label)
	
	# Remove after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if temp_label and is_inside_tree():
		temp_label.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				if dashboard_panel.visible:
					_on_refresh_pressed()
			KEY_ESCAPE:
				if dashboard_panel.visible:
					_on_logout_pressed()
