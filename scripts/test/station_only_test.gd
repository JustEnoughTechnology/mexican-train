extends Control

## Simple test to check station size and appearance
var station_scene: PackedScene = preload("res://scenes/station/station.tscn")
var test_station: Station

func _ready() -> void:
	get_window().title = "Station Size Test"
	
	# Create station in center of screen
	test_station = station_scene.instantiate()
	test_station.name = "TestStation"
	
	# Center the station in the viewport
	test_station.position = Vector2(300, 200)
	
	add_child(test_station)
	
	# Wait for station to be ready, then initialize as empty
	await test_station.ready
	test_station.initialize_empty()
	
	print("Created station at position: " + str(test_station.position))
	print("Station size: " + str(test_station.size))
	print("Station custom_minimum_size: " + str(test_station.custom_minimum_size))
	
	# Add some debug info on screen
	var info_label = Label.new()
	info_label.text = "Station Test\nStation size: %s\nExpected: 164x164 (2x domino length)\nDomino length: 82px" % test_station.size
	info_label.position = Vector2(50, 50)
	info_label.size = Vector2(300, 100)
	add_child(info_label)
	
	print("=== STATION SIZE DEBUG ===")
	print("Expected station diameter: 164px (2 × 82px domino length)")
	print("Actual station size: %s" % test_station.size)
	print("Station scene info:")
	print("  Panel offset_right: %s" % test_station.get("offset_right"))
	print("  Panel offset_bottom: %s" % test_station.get("offset_bottom"))
