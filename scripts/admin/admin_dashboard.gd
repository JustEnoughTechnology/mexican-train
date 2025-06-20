extends Control

## Server Administration Dashboard - Main Controller
## Manages authentication, server monitoring, and admin interface coordination

signal admin_logged_out

# UI References
@onready var login_panel: Control = $LoginPanel
@onready var dashboard_panel: Control = $DashboardPanel
@onready var server_panel: Control = $DashboardPanel/MainContainer/ServerPanel
@onready var games_panel: Control = $DashboardPanel/MainContainer/GamesPanel

# State
var current_admin_email: String = ""
var refresh_timer: Timer

func _ready() -> void:
	setup_ui()
	setup_refresh_timer()
	show_login_panel()
	Logger.log_info(Logger.LogArea.ADMIN, "Admin Dashboard initialized")

func setup_ui() -> void:
	# Set window title
	get_window().title = "Mexican Train - Server Administration"
	
	# Connect panel signals
	if login_panel:
		login_panel.connect("login_requested", _on_login_requested)
	
	if server_panel:
		server_panel.connect("server_action_requested", _on_server_action_requested)
	
	if games_panel:
		games_panel.connect("refresh_requested", _on_refresh_requested)	# Connect to EventBus for admin data reception
	EventBus.connect("admin_data_received", _on_admin_data_received)
	EventBus.connect("admin_auth_result", _on_admin_auth_result)
	EventBus.connect("server_control_result", _on_server_control_result)

func setup_refresh_timer() -> void:
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 5.0  # Refresh every 5 seconds
	refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	add_child(refresh_timer)

func show_login_panel() -> void:
	if login_panel:
		login_panel.visible = true
	if dashboard_panel:
		dashboard_panel.visible = false
	refresh_timer.stop()

func show_dashboard_panel() -> void:
	if login_panel:
		login_panel.visible = false
	if dashboard_panel:
		dashboard_panel.visible = true
	refresh_timer.start()
	update_dashboard_data()

func _on_login_requested(email: String, password: String) -> void:
	# Connect to server first if not connected
	if not NetworkManager.network_connected:
		# Show connecting status
		if login_panel:
			var status_label = login_panel.get_node_or_null("StatusLabel")
			if status_label:
				status_label.text = "Connecting to server..."
				status_label.modulate = Color.YELLOW
		
		var result = NetworkManager.connect_to_server("127.0.0.1", NetworkManager.DEFAULT_PORT)
		if not result:
			_handle_connection_failed("Failed to initiate connection to server")
			return
		
		# Wait for connection with timeout
		var timeout_timer = 0.0
		var max_timeout = 5.0  # 5 second timeout
		while not NetworkManager.network_connected and timeout_timer < max_timeout:
			await get_tree().create_timer(0.1).timeout
			timeout_timer += 0.1
		
		if not NetworkManager.network_connected:
			_handle_connection_failed("Connection to server timed out")
			return
	
	# Show authenticating status
	if login_panel:
		var status_label = login_panel.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Authenticating..."
			status_label.modulate = Color.YELLOW
	
	# Authenticate with local ServerAdmin (since this is a local admin dashboard)
	var auth_result = ServerAdmin.authenticate_admin(email, password)
	if auth_result:
		current_admin_email = email
		show_dashboard_panel()
		Logger.log_info(Logger.LogArea.ADMIN, "Admin login successful: %s" % email)
	else:
		# Show error message in login panel
		if login_panel:
			var status_label = login_panel.get_node_or_null("StatusLabel")
			if status_label:
				status_label.text = "Login failed: Invalid credentials"
				status_label.modulate = Color.RED
			
			# Re-enable login button
			var login_button = login_panel.get_node_or_null("VBox/LoginButton")
			if login_button:
				login_button.disabled = false

func _on_server_action_requested(action: String) -> void:	match action:
		"start_server":
			# Note: Cannot start server from admin dashboard as it runs in separate instance
			Logger.log_warning(Logger.LogArea.ADMIN, "Server start not supported from remote admin dashboard")
		"stop_server":
			# Request server stop via RPC
			if not current_admin_email.is_empty():
				NetworkManager.request_server_control("stop_server", current_admin_email)
			else:
				Logger.log_warning(Logger.LogArea.ADMIN, "Cannot stop server - admin not logged in")
		_:
			Logger.log_warning(Logger.LogArea.ADMIN, "Unknown server action: %s" % action)

func _on_refresh_requested() -> void:
	update_dashboard_data()

func _on_refresh_timer_timeout() -> void:
	if dashboard_panel.visible:
		update_dashboard_data()

func update_dashboard_data() -> void:
	if current_admin_email.is_empty():
		return
	
	# Check if we're connected to the server
	if not NetworkManager.network_connected:
		# Try to connect to the server
		var result = NetworkManager.connect_to_server("127.0.0.1", NetworkManager.DEFAULT_PORT)
		if not result:
			Logger.log_error(Logger.LogArea.ADMIN, "Failed to connect to server for admin dashboard")
			# Show offline data
			show_offline_server_status()
			return
		
		# Start a timer to retry after connection attempt
		await get_tree().create_timer(1.0).timeout
		
		# Check if connection was successful
		if not NetworkManager.network_connected:
			Logger.log_error(Logger.LogArea.ADMIN, "Connection to server timed out")
			show_offline_server_status()
			return
		# Request admin data from server via RPC
	NetworkManager.request_admin_data(current_admin_email)
	Logger.log_info(Logger.LogArea.ADMIN, "Requested admin data for: %s" % current_admin_email)

func _on_admin_auth_result(admin_email: String, success: bool) -> void:
	"""Handle admin authentication result from server"""
	# Clear authentication timeout
	if auth_timeout_timer:
		auth_timeout_timer.queue_free()
		auth_timeout_timer = null
	
	if success:
		current_admin_email = admin_email
		show_dashboard_panel()
		Logger.log_info(Logger.LogArea.ADMIN, "Admin login successful: %s" % admin_email)
	else:
		Logger.log_warning(Logger.LogArea.ADMIN, "Admin login failed: %s" % admin_email)
		# Show error message in login panel
		if login_panel:
			var status_label = login_panel.get_node_or_null("StatusLabel")
			if status_label:
				status_label.text = "Login failed: Invalid credentials"
				status_label.modulate = Color.RED
			
			# Re-enable login button
			var login_button = login_panel.get_node_or_null("VBox/LoginButton")
			if login_button:
				login_button.disabled = false

func _on_server_control_result(action: String, success: bool, message: String) -> void:
	Logger.log_info(Logger.LogArea.ADMIN, "Server control result - %s: %s (%s)" % [action, "SUCCESS" if success else "FAILED", message])
	
	if action == "stop_server" and success:
		# Server is shutting down, show shutdown status and wait for user confirmation
		Logger.log_info(Logger.LogArea.ADMIN, "Server stopped successfully - showing confirmation dialog")
		
		# Show shutdown notification that waits for user confirmation
		show_shutdown_notification()
	elif action == "stop_server" and not success:
		Logger.log_error(Logger.LogArea.ADMIN, "Failed to stop server: %s" % message)

func _on_admin_data_received(dashboard_data: Dictionary) -> void:
	"""Handle admin data received from server"""
	if dashboard_data.has("error"):
		Logger.log_error(Logger.LogArea.ADMIN, "Error receiving admin data: %s" % dashboard_data.error)
		show_offline_server_status()
		return
	
	# Update server panel
	if server_panel:
		server_panel.update_data(dashboard_data)
	
	# Update games panel
	if games_panel:
		games_panel.update_data(dashboard_data)

func logout_admin() -> void:
	if not current_admin_email.is_empty():
		# For network-based admin, we don't need to call ServerAdmin logout
		# since each instance has its own ServerAdmin autoload		current_admin_email = ""
		admin_logged_out.emit()
		show_login_panel()
		Logger.log_info(Logger.LogArea.ADMIN, "Admin logged out")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				if dashboard_panel.visible:
					update_dashboard_data()
			KEY_ESCAPE:
				if dashboard_panel.visible:
					logout_admin()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		logout_admin()
		get_tree().quit()

func show_shutdown_notification() -> void:
	"""Shows a high-contrast notification that waits for user confirmation"""
	# Hide all other panels
	if login_panel:
		login_panel.visible = false
	if dashboard_panel:
		dashboard_panel.visible = false
	
	# Create high-contrast shutdown notification panel
	var shutdown_panel = Panel.new()
	shutdown_panel.name = "ShutdownNotification"
	shutdown_panel.anchors_preset = Control.PRESET_FULL_RECT
	
	# High contrast dark background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.BLACK
	style_box.border_width_left = 4
	style_box.border_width_right = 4
	style_box.border_width_top = 4
	style_box.border_width_bottom = 4
	style_box.border_color = Color.RED
	shutdown_panel.add_theme_stylebox_override("panel", style_box)
	
	# Center container
	var center_container = CenterContainer.new()
	center_container.anchors_preset = Control.PRESET_FULL_RECT
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	# Warning icon - large and high contrast
	var icon_label = Label.new()
	icon_label.text = "⚠️ SERVER SHUTDOWN ⚠️"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.add_theme_color_override("font_color", Color.YELLOW)
	icon_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	icon_label.add_theme_constant_override("shadow_offset_x", 2)
	icon_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(icon_label)
	
	# Title - high contrast
	var title_label = Label.new()
	title_label.text = "Server Stopped Successfully"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title_label)
	
	# Message - high contrast
	var message_label = Label.new()
	message_label.text = "The Mexican Train server has been stopped by admin request.\n\nAdmin dashboard will close when you click OK."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.x = 500
	vbox.add_child(message_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)
	
	# High contrast OK button
	var ok_button = Button.new()
	ok_button.text = "OK"
	ok_button.custom_minimum_size = Vector2(120, 50)
	
	# High contrast button styling
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color.RED
	button_normal.border_width_left = 2
	button_normal.border_width_right = 2
	button_normal.border_width_top = 2
	button_normal.border_width_bottom = 2
	button_normal.border_color = Color.WHITE
	button_normal.corner_radius_top_left = 8
	button_normal.corner_radius_top_right = 8
	button_normal.corner_radius_bottom_left = 8
	button_normal.corner_radius_bottom_right = 8
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(1.0, 0.3, 0.3)  # Lighter red
	button_hover.border_width_left = 2
	button_hover.border_width_right = 2
	button_hover.border_width_top = 2
	button_hover.border_width_bottom = 2
	button_hover.border_color = Color.YELLOW
	button_hover.corner_radius_top_left = 8
	button_hover.corner_radius_top_right = 8
	button_hover.corner_radius_bottom_left = 8
	button_hover.corner_radius_bottom_right = 8
	
	ok_button.add_theme_stylebox_override("normal", button_normal)
	ok_button.add_theme_stylebox_override("hover", button_hover)
	ok_button.add_theme_stylebox_override("pressed", button_hover)
	ok_button.add_theme_color_override("font_color", Color.WHITE)
	ok_button.add_theme_font_size_override("font_size", 20)
	
	# Connect button to close the app
	ok_button.pressed.connect(_on_shutdown_confirmed)
	
	vbox.add_child(ok_button)
	center_container.add_child(vbox)
	shutdown_panel.add_child(center_container)
	add_child(shutdown_panel)
	
	# Focus the OK button so user can press Enter
	ok_button.grab_focus()

func _on_shutdown_confirmed() -> void:
	"""Handle user confirmation of shutdown"""
	Logger.log_info(Logger.LogArea.ADMIN, "User confirmed shutdown - closing admin dashboard")
	get_tree().quit()

func show_offline_server_status() -> void:
	"""Shows offline status when server connection fails"""
	var offline_data = {
		"server_info": {
			"status": "OFFLINE",
			"uptime": 0,
			"version": "Unknown"
		},
		"network_status": {
			"connections": 0
		},
		"system_resources": {
			"memory_usage": 0
		},
		"current_state": {
			"active_games": 0,
			"total_players": 0
		}
	}
	
	# Update panels with offline data
	if server_panel:
		server_panel.update_data(offline_data)
	if games_panel:
		games_panel.update_data(offline_data)

# Helper functions for connection and authentication handling
func _handle_connection_failed(error_message: String) -> void:
	## Handle failed connection attempts with user feedback
	Logger.log_error(Logger.LogArea.ADMIN, error_message)
	
	if login_panel:
		var status_label = login_panel.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Connection failed: Server unavailable"
			status_label.modulate = Color.RED
		
		# Re-enable login button
		var login_button = login_panel.get_node_or_null("VBox/LoginButton")
		if login_button:
			login_button.disabled = false

var auth_timeout_timer: Timer

func _setup_auth_timeout() -> void:
	## Set up authentication timeout to prevent hanging
	if auth_timeout_timer:
		auth_timeout_timer.queue_free()
	
	auth_timeout_timer = Timer.new()
	auth_timeout_timer.wait_time = 10.0  # 10 second timeout for auth
	auth_timeout_timer.one_shot = true
	auth_timeout_timer.timeout.connect(_on_auth_timeout)
	add_child(auth_timeout_timer)
	auth_timeout_timer.start()

func _on_auth_timeout() -> void:
	## Handle authentication timeout
	Logger.log_error(Logger.LogArea.ADMIN, "Authentication timed out - no response from server")
	
	if login_panel:
		var status_label = login_panel.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = "Authentication timeout: Server not responding"
			status_label.modulate = Color.RED
		
		# Re-enable login button
		var login_button = login_panel.get_node_or_null("VBox/LoginButton")
		if login_button:
			login_button.disabled = false
	
	# Clean up timer
	if auth_timeout_timer:
		auth_timeout_timer.queue_free()
		auth_timeout_timer = null
