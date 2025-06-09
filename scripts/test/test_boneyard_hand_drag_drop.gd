extends Control

# This script assumes BoneYard and Hand scenes support drag-and-drop dominoes.
# It does not implement drag-and-drop logic, but provides a test harness for manual or automated testing.

@onready var boneyard = $BoneYard
@onready var hand = $Hand
@onready var status_label = $StatusLabel


var debug_label: Label

func _ready():
	get_window().title = get_name()
	status_label.text = "Drag dominoes from the boneyard to the hand."
	# Use the BoneYard's built-in populate function for a 6x6 set (max dots = 6)
	if boneyard.has_method("populate"):
		boneyard.populate(12, false)

	# Connect hand's domino_count_changed to update status
	if hand.has_signal("domino_count_changed"):
		hand.domino_count_changed.connect(_on_hand_domino_count_changed)

	# Add a label to display debug_show_warnings
	debug_label = Label.new()
	debug_label.name = "DebugShowWarningsLabel"
	debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)
	debug_label.anchor_left = 0.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_right = 0.0
	debug_label.anchor_bottom = 0.0
	debug_label.position = Vector2(10, 10)
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_label.add_theme_color_override("font_color", Color(1,0.2,0.2))
	add_child(debug_label)
	set_process_input(true)

	# TEMPORARY: Add a color key/legend for orientation colors, with real dominoes in the upper left
	var key_panel = PanelContainer.new()
	key_panel.name = "OrientationColorKeyPanel"
	key_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	key_panel.position = Vector2(10, 10)
	key_panel.custom_minimum_size = Vector2(260, 160)

	var key_vbox = VBoxContainer.new()
	key_vbox.anchor_left = 0.0
	key_vbox.anchor_top = 0.0
	key_vbox.anchor_right = 0.0
	key_vbox.anchor_bottom = 0.0
	key_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var key_label = Label.new()
	key_label.text = "Orientation Color Key (6|5):"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	key_label.add_theme_color_override("font_color", Color(0.1,0.1,0.1))
	key_vbox.add_child(key_label)

	var DominoScene = preload("res://scenes/domino/domino.tscn")
	var orientations = [
		DominoData.ORIENTATION_LARGEST_LEFT,
		DominoData.ORIENTATION_LARGEST_RIGHT,
		DominoData.ORIENTATION_LARGEST_TOP,
		DominoData.ORIENTATION_LARGEST_BOTTOM
	]
	var orientation_names = ["Largest Left (Red)", "Largest Right (Blue)", "Largest Top (Green)", "Largest Bottom (Yellow)"]
	key_panel.add_child(key_vbox)
	add_child(key_panel)


	# Defer domino creation until after panel is in the scene tree
	call_deferred("_build_orientation_key", key_vbox, DominoScene, orientations, orientation_names)

	# Toggle on the orientation indicator for all dominoes in boneyard and hand
	var boneyard_dominoes = boneyard.get_node("boneyard_layout/domino_container").get_children()
	for d in boneyard_dominoes:
		if d.has_method("toggle_orientation_label"):
			d.toggle_orientation_label(true)


func _build_orientation_key(key_vbox, DominoScene, orientations, orientation_names):
	for i in range(orientations.size()):
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_vbox.add_child(hbox)
		var dom = DominoScene.instantiate()
		hbox.add_child(dom)
		dom.data.set_dots(6, 5)
		dom.set_face_up(true)
		dom.set_orientation(orientations[i])
		dom.custom_minimum_size = Vector2(82, 40)
		dom.size_flags_horizontal = Control.SIZE_FILL
		dom.size_flags_vertical = Control.SIZE_FILL
		var label = Label.new()
		label.text = orientation_names[i]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.1,0.1,0.1))
		hbox.add_child(label)

	# Optional: highlight hand on drag-over for better feedback
	if hand:
		hand.connect("mouse_entered", _on_hand_mouse_entered)
		hand.connect("mouse_exited", _on_hand_mouse_exited)

func _on_hand_domino_count_changed():
	var count = hand.get_domino_count() if hand.has_method("get_domino_count") else 0
	status_label.text = "Hand now has %d dominoes. Drag more from the boneyard!" % count

	# Enable overlay for all dominoes in the hand
	var hand_dominoes = hand.get_node("hand_layout/domino_container").get_children()
	for d in hand_dominoes:
		if d.has_method("toggle_orientation_label"):
			d.toggle_orientation_label(true)

func _on_hand_mouse_entered():
	hand.modulate = Color(0.8, 1.0, 0.8, 1.0) # light green highlight

func _on_hand_mouse_exited():
	hand.modulate = Color(1, 1, 1, 1) # reset to normal

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if debug_label:
		debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.keycode
		if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			GameConfig.DEBUG_SHOW_WARNINGS = not GameConfig.DEBUG_SHOW_WARNINGS
			if debug_label:
				debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)
		elif keycode == KEY_O:
			# Toggle orientation overlays for all dominoes
			_toggle_all_orientation_overlays()

func _toggle_all_orientation_overlays():
	# Toggle all dominoes in boneyard
	var boneyard_dominoes = boneyard.get_node("boneyard_layout/domino_container").get_children()
	for d in boneyard_dominoes:
		if d.has_method("toggle_orientation_label"):
			d.toggle_orientation_label()
	
	# Toggle all dominoes in hand
	var hand_dominoes = hand.get_node("hand_layout/domino_container").get_children()
	for d in hand_dominoes:
		if d.has_method("toggle_orientation_label"):
			d.toggle_orientation_label()
