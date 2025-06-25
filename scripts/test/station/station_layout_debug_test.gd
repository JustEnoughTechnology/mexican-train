extends Control

## Simple debug script to test station positioning and visibility

func _ready():
	get_window().title = "Station Layout Debug"
	
	# Create a simple colored background to see the full window
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.3, 1)  # Dark blue background
	bg.anchors_preset = Control.PRESET_FULL_RECT
	add_child(bg)
	
	# Add station in a simple container
	var station_scene = preload("res://scenes/station/station.tscn")
	var station = station_scene.instantiate()
	
	# Create a container to hold the station
	var container = Control.new()
	container.anchors_preset = Control.PRESET_TOP_RIGHT
	container.offset_left = -220  # 164 + 56 margin
	container.offset_top = 50
	container.offset_right = -50
	container.offset_bottom = 250  # 164 + margin
	add_child(container)
	
	# Add the station to the container
	container.add_child(station)
	station.position = Vector2(0, 0)
	
	await station.ready
	station.initialize_empty()
	
	# Add some debug labels
	var debug_label = Label.new()
	debug_label.text = "Station Debug Test\nStation should be pink circle in top-right\nContainer: (220x200) at top-right\nStation: (164x164) at container origin"
	debug_label.position = Vector2(20, 20)
	debug_label.size = Vector2(400, 100)
	add_child(debug_label)
	
	print("Station created at container position: ", container.position)
	print("Container size: ", container.size)
	print("Station position within container: ", station.position)
	print("Station size: ", station.size)
