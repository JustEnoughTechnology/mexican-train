extends Control

## Simple test to check if domino creation works

func _ready():
	get_window().title = "Domino Creation Test"
	
	# Create a simple container
	var container = GridContainer.new()
	container.columns = 3
	container.position = Vector2(50, 50)
	container.size = Vector2(300, 200)
	add_child(container)
	
	# Try to create a few dominoes
	var domino_scene = preload("res://scenes/domino/domino.tscn")
	
	for i in range(3):
		print("Creating test domino %d" % i)
		var domino = domino_scene.instantiate()
		container.add_child(domino)
		
		await domino.ready
		domino.set_dots(i + 1, i + 2)
		domino.set_face_up(true)
		print("Created domino %d with dots %d-%d" % [i, i+1, i+2])
	
	print("Domino creation test complete")
