extends Control

# Simple test to verify station drag-drop fix
var domino_scene = preload("res://scenes/domino/domino.tscn")
var station_scene = preload("res://scenes/station/station.tscn")

func _ready():
	get_window().title = "Station Drag-Drop Fix Test"
	
	# Create a 6-6 domino
	var domino = domino_scene.instantiate()
	add_child(domino)
	domino.set_dots(6, 6)
	domino.set_face_up(true)
	domino.position = Vector2(100, 100)
	domino.name = "SixSixDomino"
	
	# Create a station
	var station = station_scene.instantiate()
	add_child(station)
	station.position = Vector2(300, 100)
	station.name = "TestStation"
	
	# Create a label for instructions
	var label = Label.new()
	label.text = "Drag the 6-6 domino to the pink station"
	label.position = Vector2(50, 50)
	label.size = Vector2(400, 30)
	add_child(label)
	
	print("Test scene ready:")
	print("  Created 6-6 domino at position: %s" % domino.position)
	print("  Created station at position: %s" % station.position)
	print("  Domino drag data type: %s" % str(typeof(domino)))
	
	# Test the drag data format
	var drag_data = domino._get_drag_data(Vector2.ZERO)
	print("  Domino drag data: %s (type: %s)" % [str(drag_data), str(typeof(drag_data))])
	print("  Drag data is Domino: %s" % str(drag_data is Domino))
