extends Control

var dominoes = []

func _ready():
	print("Testing domino orientation fix...")
	
	# Load the domino scene
	var DominoScene = preload("res://scenes/domino/domino.tscn")
	
	# Test each orientation
	var orientations = [
		DominoData.ORIENTATION_LARGEST_LEFT,
		DominoData.ORIENTATION_LARGEST_RIGHT, 
		DominoData.ORIENTATION_LARGEST_TOP,
		DominoData.ORIENTATION_LARGEST_BOTTOM
	]
	
	var orientation_names = ["LEFT", "RIGHT", "TOP", "BOTTOM"]
	
	for i in range(orientations.size()):
		var domino = DominoScene.instantiate()
		add_child(domino)
		domino.data.set_dots(6, 3)  # 6 is larger than 3
		domino.set_face_up(true)
		domino.set_orientation(orientations[i])
		
		print("Orientation %s: rotation=%s degrees, overlay should show '%s'" % [
			orientation_names[i], 
			domino.rotation_degrees,
			get_expected_overlay_text(orientations[i])
		])
		
		# Position dominoes side by side for visual comparison
		domino.position = Vector2(i * 100, 100)
		domino.toggle_orientation_label(true)
	
	print("Test complete. Check visual orientation vs overlay labels.")
	print("Expected behavior:")
	print("- LEFT: domino horizontal, 6 on left, overlay 'L'")
	print("- RIGHT: domino horizontal, 6 on right, overlay 'R'") 
	print("- TOP: domino vertical, 6 on top, overlay 'T'")
	print("- BOTTOM: domino vertical, 6 on bottom, overlay 'B'")

func get_expected_overlay_text(orientation: int) -> String:
	match orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			return "L"
		DominoData.ORIENTATION_LARGEST_RIGHT:
			return "R"
		DominoData.ORIENTATION_LARGEST_TOP:
			return "T"
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			return "B"
		_:
			return "?"
