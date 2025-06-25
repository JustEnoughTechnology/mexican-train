extends Node

# Quick test to verify domino counts in different scenarios

func _ready():
	print("=== TESTING DOMINO COUNTS ===")
	
	# Test 1: How many unique dominoes should exist
	var unique_dominoes = generate_unique_domino_set(28)
	print("Generated %d unique domino combinations:" % unique_dominoes.size())
	for i in range(min(10, unique_dominoes.size())):
		var combo = unique_dominoes[i]
		print("  %d: %d-%d" % [i, combo.x, combo.y])
	
	# Test 2: Check if 6-6 is in the set
	var has_six_six = false
	for combo in unique_dominoes:
		if combo.x == 6 and combo.y == 6:
			has_six_six = true
			print("Found 6-6 domino in the set!")
			break
	
	if not has_six_six:
		print("ERROR: 6-6 domino not found in the set!")
	
	print("=== EXPECTED RESULTS ===")
	print("Total unique dominoes: 28")
	print("After moving 6-6 to train:")
	print("  - Pool should have: 27 dominoes")
	print("  - Train should have: 1 domino (6-6)")
	
	get_tree().quit()

func generate_unique_domino_set(max_count: int) -> Array[Vector2i]:
	"""Generate a list of all 28 unique domino combinations"""
	var unique_dominoes: Array[Vector2i] = []
	
	# Generate all unique combinations where larger >= smaller (avoid duplicates)
	for smaller in range(0, 7):  # 0 to 6 (standard domino set)
		for larger in range(smaller, 7):  # larger >= smaller
			unique_dominoes.append(Vector2i(larger, smaller))
			
			# Stop if we reach the requested count
			if unique_dominoes.size() >= max_count:
				break
		if unique_dominoes.size() >= max_count:
			break
	
	# Shuffle the dominoes for variety
	unique_dominoes.shuffle()
	
	return unique_dominoes
