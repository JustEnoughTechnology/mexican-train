extends Control

## Ultra-simple pink circle test

func _ready():
	get_window().title = "Pink Circle Test"
	
	# Create a manual pink panel
	var pink_panel = Panel.new()
	pink_panel.position = Vector2(100, 100)
	pink_panel.size = Vector2(164, 164)
	
	# Create pink style manually
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.4, 0.7, 0.9)  # Pink
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(1, 0.6, 0.8, 1)  # Light pink border
	style.corner_radius_top_left = 82
	style.corner_radius_top_right = 82
	style.corner_radius_bottom_right = 82
	style.corner_radius_bottom_left = 82
	
	pink_panel.add_theme_stylebox_override("panel", style)
	add_child(pink_panel)
	
	# Add label inside
	var label = Label.new()
	label.text = "PINK CIRCLE\nTEST"
	label.position = Vector2(50, 70)
	label.add_theme_color_override("font_color", Color.WHITE)
	pink_panel.add_child(label)
	
	# Add debug info
	var debug_label = Label.new()
	debug_label.text = "If you see a pink circle at (100,100), styling works!\nIf not, there's a rendering issue."
	debug_label.position = Vector2(20, 20)
	add_child(debug_label)
	
	print("Manual pink panel created at: ", pink_panel.position)
	print("Panel size: ", pink_panel.size)
