extends Control

## Server Launcher Test
## Test version of the server launcher for development

func _ready() -> void:
	print("Server Launcher Test loaded")
	get_window().title = "Mexican Train - Server Launcher Test"
	
	# Create basic test UI
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "Server Launcher Test"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	var start_button = Button.new()
	start_button.text = "Start Test Server"
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

func _on_start_pressed() -> void:
	print("Test server start button pressed")