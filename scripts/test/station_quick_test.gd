extends Node

# Quick test to verify station initialization
func _ready():
	print("=== TESTING STATION INITIALIZATION ===")
	
	# Create station
	var station_scene = preload("res://scenes/station/station.tscn")
	var station = station_scene.instantiate()
	add_child(station)
	
	# Wait a frame for initialization
	await get_tree().process_frame
	
	print("Station has engine domino: ", station.has_engine())
	print("Station label text: ", station.station_label.text)
	
	# Test if we can drop 6-6 domino
	var domino_scene = preload("res://scenes/domino/domino.tscn")
	var test_domino = domino_scene.instantiate()
	add_child(test_domino)
	
	await test_domino.ready
	test_domino.set_dots(6, 6)
	
	print("Can drop 6-6 domino: ", station._can_drop_data(Vector2.ZERO, test_domino))
	
	# Test if we can drop other domino
	var test_domino2 = domino_scene.instantiate()
	add_child(test_domino2)
	
	await test_domino2.ready
	test_domino2.set_dots(3, 4)
	
	print("Can drop 3-4 domino: ", station._can_drop_data(Vector2.ZERO, test_domino2))
	
	print("=== TEST COMPLETE ===")
	get_tree().quit()
