extends Control

## Server Launcher
## Simple server launcher interface for development/testing

@onready var start_button = $VBox/StartButton
@onready var stop_button = $VBox/StopButton
@onready var status_label = $VBox/StatusLabel

var server_running: bool = false

func _ready() -> void:
	print("Server Launcher initialized")
	get_window().title = "Mexican Train - Server Launcher"
	
	# Setup UI if nodes exist
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	
	update_ui()

func _on_start_pressed() -> void:
	print("Starting server...")
	if NetworkManager and NetworkManager.has_method("start_server"):
		if NetworkManager.start_server():
			server_running = true
			print("Server started successfully")
		else:
			print("Failed to start server")
	update_ui()

func _on_stop_pressed() -> void:
	print("Stopping server...")
	if NetworkManager and NetworkManager.has_method("disconnect_from_server"):
		NetworkManager.disconnect_from_server()
		server_running = false
		print("Server stopped")
	update_ui()

func update_ui() -> void:
	if start_button:
		start_button.disabled = server_running
	if stop_button:
		stop_button.disabled = not server_running
	if status_label:
		status_label.text = "Server Status: " + ("RUNNING" if server_running else "STOPPED")
