extends Control

## Minimal station visibility test

func _ready():
	get_window().title = "Station Visibility Test"
	
	# Create the station directly
	var station_scene = preload("res://scenes/station/station.tscn")
	var station = station_scene.instantiate()
	
	# Position it in a visible location
	station.position = Vector2(200, 100)
	add_child(station)
	
	# Wait for it to be ready and initialize
	await station.ready
	station.initialize_empty()
	
	# Add debug info
	var label = Label.new()
	label.text = "Pink station should be visible at (200,100)\nStation size: 164x164"
	label.position = Vector2(20, 20)
	add_child(label)
	
	print("Station created at: ", station.position)
	print("Station size: ", station.size)
	print("Station background color should be pink")
