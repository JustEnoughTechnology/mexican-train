extends Control

@onready var grid_container = $VBoxContainer/ScrollContainer/GridContainer

func _ready():
	create_domino_showcase()

func create_domino_showcase():
	# Load the domino piece scene
	var domino_scene = preload("res://scenes/test/dominos/domino_piece.tscn")
	
	# Test combinations to showcase
	var test_combinations = [
		[12, 0],  # Highest vs lowest
		[8, 3],   # Mixed numbers
		[6, 6],   # Double
		[11, 5],  # High contrast colors
		[9, 2],   # Purple vs orange
		[10, 4]   # Green vs brown
	]
	
	# Create header labels
	var orientations = [
		"Horizontal Left",
		"Horizontal Right", 
		"Vertical Top",
		"Vertical Bottom"
	]
	
	for orientation_name in orientations:
		var header = Label.new()
		header.text = orientation_name
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 14)
		grid_container.add_child(header)
	
	# Create dominoes for each combination in all orientations
	for combination in test_combinations:
		var largest = combination[0]
		var smallest = combination[1]
		
		for orientation_index in range(4):
			var container = VBoxContainer.new()
			
			# Create domino
			var domino = domino_scene.instantiate()
			domino.largest_value = largest
			domino.smallest_value = smallest
			domino.orientation = orientation_index as DominoPiece.Orientation
			
			# Create label
			var label = Label.new()
			label.text = "%d-%d" % [largest, smallest]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 12)
			
			# Add to container
			container.add_child(domino)
			container.add_child(label)
			container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			
			grid_container.add_child(container)
