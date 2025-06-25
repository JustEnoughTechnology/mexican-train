extends Node

## Quick test to verify double domino generation
func _ready() -> void:
	print("=== TESTING DOUBLE DOMINO GENERATION ===")
	
	var double_dominoes = generate_double_domino_set()
	print("Generated %d double dominoes:" % double_dominoes.size())
	
	for i in range(double_dominoes.size()):
		var combo = double_dominoes[i]
		print("  %d: %d-%d" % [i, combo.x, combo.y])
	
	print("=== TEST COMPLETE ===")
	
	# Quit after test
	get_tree().quit()

func generate_double_domino_set() -> Array[Vector2i]:
	"""Generate only the double dominoes 0-0 through 6-6"""
	var double_dominoes: Array[Vector2i] = []
	
	# Generate doubles: 0-0, 1-1, 2-2, 3-3, 4-4, 5-5, 6-6
	for value in range(0, 7):  # 0 to 6 (standard domino set)
		double_dominoes.append(Vector2i(value, value))
	
	return double_dominoes
