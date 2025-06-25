extends Control

## Comparison scene to show the difference between original and simplified approaches
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn")
var train_scene: PackedScene = preload("res://scenes/train/train.tscn")

# UI elements
@onready var original_pool: GridContainer = $HSplitContainer/OriginalSide/OriginalPool
@onready var original_train_container: HBoxContainer = $HSplitContainer/OriginalSide/OriginalTrain/OriginalTrainContainer
@onready var simplified_pool: GridContainer = $HSplitContainer/SimplifiedSide/SimplifiedPool
@onready var simplified_train_container: HBoxContainer = $HSplitContainer/SimplifiedSide/SimplifiedTrain/SimplifiedTrainContainer
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	get_window().title = "Comparison: Original vs Simplified"
	
	# Create both approaches side by side
	create_original_approach()
	create_simplified_approach()
	
	# Update status
	update_status()

func create_original_approach() -> void:
	"""Create the original approach: all 28 dominoes in pool, empty train"""
	print("Creating original approach...")
	
	# Create train (empty)
	var train = train_scene.instantiate()
	train.name = "OriginalTrain"
	train.label_text = "Original Train"
	original_train_container.add_child(train)
	
	# Create all 28 dominoes in pool
	var unique_dominoes = generate_unique_domino_set(28)
	
	for i in range(unique_dominoes.size()):
		var domino = d_scene.instantiate()
		original_pool.add_child(domino)
		
		await domino.ready
		
		var combination = unique_dominoes[i]
		domino.set_dots(combination.x, combination.y)
		domino.name = "Original_%d_%d" % [combination.x, combination.y]
		domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT if i % 2 == 0 else DominoData.ORIENTATION_LARGEST_RIGHT)
		
		# Make them smaller for the comparison
		domino.scale = Vector2(0.5, 0.5)
	
	print("Original approach: %d dominoes in pool, %d in train" % [original_pool.get_child_count(), train.get_domino_count()])

func create_simplified_approach() -> void:
	"""Create the simplified approach: 27 dominoes in pool, 6-6 in train"""
	print("Creating simplified approach...")
		# Create train
	var train = train_scene.instantiate()
	train.name = "SimplifiedTrain"
	train.label_text = "Simplified Train"
	simplified_train_container.add_child(train)
	
	# Create all 28 dominoes first
	var unique_dominoes = generate_unique_domino_set(28)
	
	for i in range(unique_dominoes.size()):
		var domino = d_scene.instantiate()
		
		var combination = unique_dominoes[i]
		
		# Check if this is the 6-6 domino
		if combination.x == 6 and combination.y == 6:
			# Add 6-6 to train as engine
			train.add_child(domino)
		else:
			# Add other dominoes to pool
			simplified_pool.add_child(domino)
		
		await domino.ready
		
		domino.set_dots(combination.x, combination.y)
		domino.name = "Simplified_%d_%d" % [combination.x, combination.y]
		domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT if i % 2 == 0 else DominoData.ORIENTATION_LARGEST_RIGHT)
		
		# Make them smaller for the comparison
		domino.scale = Vector2(0.5, 0.5)
		
		# If this is the engine domino, add it to the train
		if combination.x == 6 and combination.y == 6:
			train.add_domino(domino)
	
	print("Simplified approach: %d dominoes in pool, %d in train" % [simplified_pool.get_child_count(), train.get_domino_count()])

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

func update_status() -> void:
	await get_tree().process_frame  # Wait for children to be added
	
	var original_pool_count = original_pool.get_child_count()
	var original_train_count = 0
	if original_train_container.get_child_count() > 0:
		var train = original_train_container.get_child(0)
		if train.has_method("get_domino_count"):
			original_train_count = train.get_domino_count()
	
	var simplified_pool_count = simplified_pool.get_child_count()
	var simplified_train_count = 0
	if simplified_train_container.get_child_count() > 0:
		var train = simplified_train_container.get_child(0)
		if train.has_method("get_domino_count"):
			simplified_train_count = train.get_domino_count()
	
	status_label.text = "Original: Pool=%d, Train=%d | Simplified: Pool=%d, Train=%d | The difference: Simplified starts with 6-6 engine!" % [
		original_pool_count, original_train_count, simplified_pool_count, simplified_train_count
	]
