extends Node

# Simple test to verify domino orientation visually
var domino: Domino

func _ready() -> void:
	var DominoScene: PackedScene = preload("res://scenes/domino/domino.tscn")
	domino = DominoScene.instantiate() as Domino
	add_child(domino)
	
	# Set a clear domino with different values
	domino.set_dots(6, 3)
	domino.set_face_up(true)
	domino.toggle_orientation_label(true)
	
	# Position it in center
	domino.position = Vector2(400, 300)
	
	print("Testing orientations...")
	print("Default (no rotation): should be horizontal with 6 on left, 3 on right")
	
	# Test each orientation with debug output
	call_deferred("test_orientations")

func test_orientations():
	await get_tree().create_timer(2.0).timeout
	
	print("Setting to LARGEST_TOP - should be vertical with 6 at top")
	domino.set_orientation(DominoData.ORIENTATION_LARGEST_TOP)
	print("Rotation applied: %s degrees" % domino.rotation_degrees)
	print("Overlay should show: T")
	
	await get_tree().create_timer(3.0).timeout
	
	print("Setting to LARGEST_RIGHT - should be horizontal with 6 on right")
	domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
	print("Rotation applied: %s degrees" % domino.rotation_degrees)
	print("Overlay should show: R")
	
	await get_tree().create_timer(3.0).timeout
	
	print("Setting to LARGEST_BOTTOM - should be vertical with 6 at bottom")
	domino.set_orientation(DominoData.ORIENTATION_LARGEST_BOTTOM)
	print("Rotation applied: %s degrees" % domino.rotation_degrees)
	print("Overlay should show: B")
	
	await get_tree().create_timer(3.0).timeout
	
	print("Setting to LARGEST_LEFT - should be horizontal with 6 on left (original)")
	domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
	print("Rotation applied: %s degrees" % domino.rotation_degrees)
	print("Overlay should show: L")
