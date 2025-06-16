extends VBoxContainer

## VBoxContainer for Bone Yard
## Custom VBoxContainer with bone yard specific functionality

func _ready() -> void:
	Logger.log_info(Logger.LogArea.SYSTEM, "VBoxContainer for Bone Yard initialized")
	
	# Add any bone yard specific VBox functionality here
	setup_bone_yard_layout()

func setup_bone_yard_layout() -> void:
	# Configure layout for bone yard display
	pass
