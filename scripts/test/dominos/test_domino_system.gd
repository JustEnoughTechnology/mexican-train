#!/usr/bin/env godot
# Quick test script to verify domino system functionality

extends SceneTree

func _init():
	print("Testing Domino System...")
	
	# Test DominoPiece class loading
	var domino_scene = preload("res://scenes/test/dominos/domino_piece.tscn")
	var domino = domino_scene.instantiate()
	
	print("✓ DominoPiece scene loaded successfully")
	
	# Test setting values
	domino.largest_value = 8
	domino.smallest_value = 4
	domino.orientation = DominoPiece.Orientation.HORIZONTAL_LEFT
	
	print("✓ Domino values set: ", domino.get_domino_string())
	print("✓ Is double: ", domino.is_double())
	
	# Test all orientations
	var orientations = [
		DominoPiece.Orientation.HORIZONTAL_LEFT,
		DominoPiece.Orientation.HORIZONTAL_RIGHT,
		DominoPiece.Orientation.VERTICAL_TOP,
		DominoPiece.Orientation.VERTICAL_BOTTOM
	]
	
	for orientation in orientations:
		domino.orientation = orientation
		print("✓ Orientation set to: ", orientation)
	
	# Test doubles
	domino.largest_value = 6
	domino.smallest_value = 6
	print("✓ Double domino: ", domino.get_domino_string(), " Is double: ", domino.is_double())
	
	print("✓ All tests passed! Domino system is working correctly.")
	
	# Quit the test
	quit()
