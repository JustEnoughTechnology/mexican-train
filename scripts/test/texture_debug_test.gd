extends Node

func _ready():
	get_window().title = get_name()
	print("=== TEXTURE DEBUG TEST ===")
	
	# Test loading base texture
	var base_path = "res://assets/tiles/dominos/domino-4-1.svg"
	var base_texture = load(base_path)
	print("Base texture load result: %s" % base_texture)
	if base_texture:
		print("  Base texture size: %s" % base_texture.get_size())
	
	# Test loading oriented textures
	var orientations = ["_left", "_right", "_top", "_bottom"]
	for orientation in orientations:
		var oriented_path = "res://assets/tiles/dominos/domino-4-1%s.svg" % orientation
		var oriented_texture = load(oriented_path)
		print("Oriented texture %s load result: %s" % [orientation, oriented_texture])
		if oriented_texture:
			print("  Oriented texture %s size: %s" % [orientation, oriented_texture.get_size()])
	
	# Create a test domino
	print("\n=== DOMINO TEST ===")
	var domino_scene = load("res://scenes/domino/domino.tscn")
	var domino = domino_scene.instantiate()
	add_child(domino)
	
	# Initialize with test values
	domino.data.dots = Vector2i(4, 1)
	domino.data.is_face_up = true
	
	print("Domino created with dots: %s" % domino.data.dots)
	print("Domino orientation: %s" % domino.data.orientation)
	
	# Test orientation changes
	call_deferred("test_orientations", domino)

func test_orientations(domino):
	await get_tree().process_frame
	
	print("\n=== ORIENTATION TESTS ===")
	var orientations = [
		[1, "LARGEST_LEFT"],
		[2, "LARGEST_RIGHT"], 
		[3, "LARGEST_TOP"],
		[4, "LARGEST_BOTTOM"]
	]
	
	for orientation_data in orientations:
		var orientation_value = orientation_data[0]
		var orientation_name = orientation_data[1]
		
		print("\nTesting orientation: %s (%s)" % [orientation_name, orientation_value])
		domino.set_orientation(orientation_value)
		await get_tree().process_frame
		
		print("  Domino size after orientation: %s" % domino.size)
		print("  Container size: %s" % domino.container.size)
		if domino.front.texture:
			print("  Front texture size: %s" % domino.front.texture.get_size())
		else:
			print("  Front texture: NULL")
