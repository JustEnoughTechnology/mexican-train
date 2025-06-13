extends Control

## Client Lobby Test
## Test version of the client lobby for development

func _ready() -> void:
	print("Client Lobby Test loaded")
	get_window().title = "Mexican Train - Client Lobby Test"
	
	# Create basic test UI
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_CENTER
	add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "Client Lobby Test"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	var status_label = Label.new()
	status_label.text = "This is a test version of the client lobby"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)