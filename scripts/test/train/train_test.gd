extends Control
var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn") 
var d:Domino

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	get_window().title = get_name()
	
	# Create a smaller pool of dominoes that can be dragged to the train
	for i in range(8):  # Reduced from 35 to 8 for testing
		d = d_scene.instantiate()
		$dominos.add_child(d)
		d.set_dots(randi_range(0,6),randi_range(0,6))  # Standard domino range
		d.set_face_up(true)  # Make them visible
		d.mouse_filter = Control.MOUSE_FILTER_STOP  # Enable drag
		
		# Connect right-click for testing
		d.mouse_right_pressed.connect(_on_domino_right_clicked)
	
	# Add instructions
	print("=== TRAIN DRAG & DROP TEST ===")
	print("Instructions:")
	print("1. Drag dominoes from the right panel to the green train")
	print("2. Right-click dominoes to toggle face up/down")
	print("3. Train should automatically orient dominoes horizontally")

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_domino_right_clicked(domino: Domino) -> void:
	domino.toggle_dots()
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	print("Domino right-clicked! %s is now: %s" % [domino.name, face_state])
