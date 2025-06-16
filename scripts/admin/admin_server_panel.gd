extends Control

## Admin Server Panel
## Handles server status monitoring and control

signal server_action_requested(action: String)

# UI References
@onready var status_label: Label = $VBox/StatusContainer/StatusLabel
@onready var uptime_label: Label = $VBox/InfoContainer/UptimeLabel
@onready var version_label: Label = $VBox/InfoContainer/VersionLabel
@onready var connections_label: Label = $VBox/InfoContainer/ConnectionsLabel
@onready var memory_label: Label = $VBox/InfoContainer/MemoryLabel
@onready var start_button: Button = $VBox/ButtonContainer/StartButton
@onready var stop_button: Button = $VBox/ButtonContainer/StopButton

func _ready() -> void:
	setup_ui()
	setup_connections()

func setup_ui() -> void:
	# Initialize labels
	if status_label:
		status_label.text = "Server Status: Unknown"
	if uptime_label:
		uptime_label.text = "Uptime: 0s"
	if version_label:
		version_label.text = "Version: 0.6.0"
	if connections_label:
		connections_label.text = "Connections: 0"
	if memory_label:
		memory_label.text = "Memory: 0 MB"

func setup_connections() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_button_pressed)

func _on_start_button_pressed() -> void:
	server_action_requested.emit("start_server")

func _on_stop_button_pressed() -> void:
	server_action_requested.emit("stop_server")

func update_data(dashboard_data: Dictionary) -> void:
	var server_info = dashboard_data.get("server_info", {})
	var network_status = dashboard_data.get("network_status", {})
	var system_resources = dashboard_data.get("system_resources", {})
	var _current_state = dashboard_data.get("current_state", {})
	
	# Update server status
	var server_status = server_info.get("status", "UNKNOWN")
	var server_running = (server_status == "RUNNING")
	
	if status_label:
		status_label.text = "Server Status: " + server_status
		match server_status:
			"RUNNING":
				status_label.modulate = Color.GREEN
			"STOPPED":
				status_label.modulate = Color.RED
			"OFFLINE":
				status_label.modulate = Color.ORANGE
			_:
				status_label.modulate = Color.GRAY
	
	# Update control buttons
	if start_button and stop_button:
		var is_offline = (server_status == "OFFLINE")
		start_button.disabled = server_running or is_offline
		stop_button.disabled = not server_running or is_offline
		
		if server_running:
			start_button.modulate = Color.GRAY
			stop_button.modulate = Color.RED
		elif is_offline:
			start_button.modulate = Color.ORANGE
			stop_button.modulate = Color.ORANGE
		else:
			start_button.modulate = Color.GREEN
			stop_button.modulate = Color.GRAY
	
	# Update uptime
	if uptime_label:
		var uptime = server_info.get("uptime", 0)
		var uptime_formatted = format_uptime(uptime)
		uptime_label.text = "Uptime: " + uptime_formatted
	
	# Update version
	if version_label:
		var version = server_info.get("version", "Unknown")
		version_label.text = "Version: " + version
	
	# Update connections
	if connections_label:
		var connections = network_status.get("connections", 0)
		connections_label.text = "Connections: " + str(connections)
	
	# Update memory usage
	if memory_label:
		var memory_mb = system_resources.get("memory_usage", 0.0)
		memory_label.text = "Memory: %.1f MB" % memory_mb

func format_uptime(seconds: int) -> String:
	if seconds < 60:
		return str(seconds) + "s"
	elif seconds < 3600:
		@warning_ignore("integer_division")
		return str(seconds / 60) + "m " + str(seconds % 60) + "s"
	else:
		@warning_ignore("integer_division")
		var hours = seconds / 3600
		@warning_ignore("integer_division")
		var minutes = (seconds % 3600) / 60
		return str(hours) + "h " + str(minutes) + "m"
