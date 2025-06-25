extends Control

@onready var is_dragging:=false
@onready var current_domino:Domino 

var debug_label: Label

func _ready() -> void:
	get_window().title = get_name()
	$BoneYard.set_size(get_window().size*0.85)
	$BoneYard.populate(GameConfig.MAX_DOTS,false)
	# Add a label to display debug_show_warnings
	debug_label = Label.new()
	debug_label.name = "DebugShowWarningsLabel"
	debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)
	debug_label.anchor_right = 1.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_bottom = 0.0
	debug_label.margin_left = 10
	debug_label.margin_top = 10
	debug_label.margin_right = 300
	debug_label.margin_bottom = 30
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_label.add_theme_color_override("font_color", Color(1,0.2,0.2))
	add_child(debug_label)
	set_process_input(true)
# Called every frame. 'delta' is the elapsed time since the previous 

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if debug_label:
		debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle on Enter/Return
		if event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER:
			GameConfig.DEBUG_SHOW_WARNINGS = not GameConfig.DEBUG_SHOW_WARNINGS
			if debug_label:
				debug_label.text = "DEBUG_SHOW_WARNINGS: %s" % str(GameConfig.DEBUG_SHOW_WARNINGS)
	

func _on_bone_yard_domino_right_pressed(p_domino: Domino) -> void:
	p_domino.toggle_dots() # Replace with function body.
