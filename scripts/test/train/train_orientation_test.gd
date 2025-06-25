extends Node

# Test script to verify train orientation behavior

func _ready():
	print("=== TESTING TRAIN ORIENTATION BEHAVIOR ===")
	
	# Create a test station with engine
	var station = preload("res://scenes/station/station.tscn").instantiate()
	add_child(station)
	
	# Create engine domino (let's say 12-12 for engine value 12)
	var engine_domino = preload("res://scenes/domino/domino.tscn").instantiate()
	engine_domino.set_dots(12, 12)
	station.set_engine_domino(engine_domino)
	
	print("Station setup with engine domino 12-12 (engine value: %d)" % station.get_engine_value())
	
	# Create a train
	var train = preload("res://scenes/train/train.tscn").instantiate()
	add_child(train)
	
	print("\n=== TEST 1: First domino with engine match on left side ===")
	# Test domino 12-8 (engine 12 on left side)
	var domino1 = preload("res://scenes/domino/domino.tscn").instantiate()
	domino1.set_dots(12, 8)
	print("Testing domino 12-8 (engine match on left)")
	train._orient_domino_for_connection(domino1)
	print("Result: dots=%d-%d, orientation=%d" % [domino1.get_dots().x, domino1.get_dots().y, domino1.data.orientation])
	print("Expected: engine-matching 12 should be on left side")
	
	print("\n=== TEST 2: First domino with engine match on right side ===")
	# Test domino 8-12 (engine 12 on right side, should be swapped)
	var domino2 = preload("res://scenes/domino/domino.tscn").instantiate()
	domino2.set_dots(8, 12)
	print("Testing domino 8-12 (engine match on right)")
	train._orient_domino_for_connection(domino2)
	print("Result: dots=%d-%d, orientation=%d" % [domino2.get_dots().x, domino2.get_dots().y, domino2.data.orientation])
	print("Expected: engine-matching 12 should be swapped to left side")
	
	print("\n=== TEST 3: Double domino (same value both sides) ===")
	# Test double domino 12-12 
	var domino3 = preload("res://scenes/domino/domino.tscn").instantiate()
	domino3.set_dots(12, 12)
	print("Testing domino 12-12 (double, both sides match engine)")
	train._orient_domino_for_connection(domino3)
	print("Result: dots=%d-%d, orientation=%d" % [domino3.get_dots().x, domino3.get_dots().y, domino3.data.orientation])
	print("Expected: should work with either orientation")
	
	print("\n=== TESTING COMPLETE ===")
	
	# Exit after testing
	get_tree().quit()
