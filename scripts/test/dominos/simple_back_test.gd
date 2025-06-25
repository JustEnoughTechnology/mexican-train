extends Node

## Simple test to verify domino back functionality without graphics

func _ready():
	print("=== NewDomino Back System Test ===")
	
	# Test scene loading paths
	test_domino_paths()
	
	# Test NewDomino back functionality
	test_domino_backs()
	
	print("=== Test Complete ===")

func test_domino_paths():
	print("\n--- Testing Scene Paths ---")
	
	# Create a test domino
	var domino_scene = load("res://scenes/dominos/domino.tscn")
	if domino_scene == null:
		print("ERROR: Could not load NewDomino scene!")
		return
		
	var domino = domino_scene.instantiate()
	domino.largest_value = 6
	domino.smallest_value = 3
	
	print("Face scene path: ", domino.get_base_domino_scene_path())
	print("Back horizontal path: ", domino.get_domino_back_scene_path())
	
	# Test back paths for different orientations
	domino.orientation = 2  # VERTICAL_TOP
	print("Back vertical path: ", domino.get_domino_back_scene_path())
	
	domino.queue_free()

func test_domino_backs():
	print("\n--- Testing Back Scene Loading ---")
	
	# Test horizontal back
	var horizontal_back_scene = load("res://scenes/dominos/domino_back_horizontal.tscn")
	if horizontal_back_scene == null:
		print("ERROR: Could not load horizontal back scene!")
	else:
		print("✓ Horizontal back scene loads correctly")
		
	# Test vertical back  
	var vertical_back_scene = load("res://scenes/dominos/domino_back_vertical.tscn")
	if vertical_back_scene == null:
		print("ERROR: Could not load vertical back scene!")
	else:
		print("✓ Vertical back scene loads correctly")
		
	# Test a specific BaseDomino scene
	var base_domino_scene = load("res://scenes/dominos/base_dominos/base_domino_6_3_horizontal_left.tscn")
	if base_domino_scene == null:
		print("ERROR: Could not load test BaseDomino scene!")
	else:
		print("✓ BaseDomino scene loads correctly")
