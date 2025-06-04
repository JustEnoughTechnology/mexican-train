extends Node

func _ready():
	print("=== SIMPLE TEST START ===")
	
	# Test domino generation logic
	var all_dominoes = generate_all_domino_combinations()
	print("Generated %d domino combinations" % all_dominoes.size())
	
	if all_dominoes.size() == 28:
		print("✓ PASS: Correct number of dominoes generated")
	else:
		print("✗ FAIL: Expected 28 dominoes, got %d" % all_dominoes.size())
	
	# Test for 6-6 presence
	var has_double_six = false
	for combo in all_dominoes:
		if combo.x == 6 and combo.y == 6:
			has_double_six = true
			break
	
	if has_double_six:
		print("✓ PASS: 6-6 domino found in set")
	else:
		print("✗ FAIL: 6-6 domino missing from set")
	
	print("All combinations: ", all_dominoes)
	print("=== SIMPLE TEST END ===")
	
	# Exit after 2 seconds
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func generate_all_domino_combinations() -> Array[Vector2i]:
	"""Generate all 28 unique domino combinations from 0-0 to 6-6"""
	var all_dominoes: Array[Vector2i] = []
	
	# Generate all unique combinations where x >= y (avoid duplicates like 1-2 and 2-1)
	for y in range(0, 7):  # 0 to 6 (standard domino set)
		for x in range(y, 7):  # x >= y to avoid duplicates
			all_dominoes.append(Vector2i(x, y))
	
	return all_dominoes
