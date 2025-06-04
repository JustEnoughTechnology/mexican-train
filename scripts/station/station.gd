class_name Station
extends Panel

## Circular station implementation for Mexican Train dominoes
## Holds the starting double domino that determines train connections

# Signals
signal engine_domino_placed

@onready var domino_container: CenterContainer = $DominoContainer
@onready var station_label: Label = $StationLabel
@onready var drop_highlight: Panel = $DropHighlight

var engine_domino: Domino = null

func _ready() -> void:
	# Initialize empty - user will drag 6-6 domino to start
	print("Station _ready called")
	print("domino_container: %s" % str(domino_container))
	print("station_label: %s" % str(station_label))
	print("drop_highlight: %s" % str(drop_highlight))
	initialize_empty()

func initialize_with_double(dots: int) -> void:
	"""Initialize the station with a double domino (e.g., 6-6)"""
	# Clear any existing domino
	if engine_domino:
		engine_domino.queue_free()
	
	# Create the engine domino
	engine_domino = preload("res://scenes/domino/domino.tscn").instantiate()
	
	# Add to container first, then wait for ready
	domino_container.add_child(engine_domino)
	
	# Wait for the domino to be ready before setting data
	await engine_domino.ready
	
	# Set the domino data properly
	engine_domino.set_dots(dots, dots)  # Double domino
	engine_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
	
	# Update label
	station_label.text = "Station\n%d-%d" % [dots, dots]
	
	print("Station initialized with %d-%d engine domino" % [dots, dots])

func get_engine_value() -> int:
	"""Get the dot value that trains must connect to"""
	if engine_domino:
		return engine_domino.get_dots().x  # Both sides are the same for doubles
	return -1  # Invalid value if no engine

func has_engine() -> bool:
	"""Check if the station has an engine domino"""
	return engine_domino != null

func _can_drop_data(_position: Vector2, data) -> bool:
	"""Check if we can accept the dropped domino"""
	print("=== STATION _can_drop_data called ===")
	print("Position: %s" % str(_position))
	print("Data type: %s" % str(typeof(data)))
	print("Data content: %s" % str(data))
	
	# Check source type from metadata
	var source_type = ""
	if get_tree().has_meta("current_drag_source"):
		source_type = get_tree().get_meta("current_drag_source")
	
	# Only allow drops from hand
	if source_type != "hand":
		if GameState.DEBUG_SHOW_WARNINGS:
			print("Station _can_drop_data: Rejected - source is '%s', only 'hand' allowed" % source_type)
		if drop_highlight:
			drop_highlight.visible = false
		return false
	
	# Show drop highlight
	if drop_highlight:
		drop_highlight.visible = true
	
	# Handle different drag data formats
	var domino: Domino = null
	
	# Check if data is directly a domino (new format)
	if data is Domino:
		domino = data
	# Check if data is a dictionary with a domino key (old format)
	elif typeof(data) == TYPE_DICTIONARY and data.has("domino"):
		domino = data["domino"]
	else:
		print("Station: Invalid drag data format - received: %s" % str(typeof(data)))
		return false
	
	if not domino is Domino:
		print("Station: Dragged object is not a domino - type: %s" % str(type_string(typeof(domino))))
		return false
	
	if GameState.DEBUG_SHOW_WARNINGS:
		print("Station _can_drop_data: source_type = %s (allowed)" % source_type)
	
	# Only accept if we don't already have an engine
	if has_engine():
		print("Station already has an engine domino")
		return false
	
	# Only accept double dominoes (e.g., 0-0, 1-1, 2-2, etc.)
	var dots = domino.get_dots()
	if dots.x == dots.y:
		print("Station can accept %d-%d domino as engine (double domino)" % [dots.x, dots.y])
		print("=== STATION _can_drop_data returning TRUE ===")
		return true
	else:
		print("Station only accepts double dominoes as engine (got %d-%d)" % [dots.x, dots.y])
		print("=== STATION _can_drop_data returning FALSE ===")
		return false

func _drop_data(_position: Vector2, data) -> void:
	"""Handle dropped domino"""
	print("=== STATION _drop_data called ===")
	print("Position: %s" % str(_position))
	print("Data: %s" % str(data))
	
	# Hide drop highlight
	if drop_highlight:
		drop_highlight.visible = false
	
	if not _can_drop_data(_position, data):
		print("_drop_data: _can_drop_data returned false, exiting")
		return
	
	# Handle different drag data formats
	var domino: Domino = null
	
	# Check if data is directly a domino (new format)
	if data is Domino:
		domino = data
	# Check if data is a dictionary with a domino key (old format)
	elif typeof(data) == TYPE_DICTIONARY and data.has("domino"):
		domino = data["domino"]
	else:
		print("Station: Invalid drag data format in drop - received: %s" % str(typeof(data)))
		return
	
	var source_container = domino.get_parent()
	print("Source container: %s" % str(source_container))
	
	# Remove from source container
	if source_container:
		print("Removing domino from source container...")
		source_container.remove_child(domino)
		print("Domino removed from source")
	else:
		print("No source container found")
	
	# Add to our container
	print("Adding domino to station container...")
	print("Station domino_container: %s" % str(domino_container))
	domino_container.add_child(domino)
	print("Domino added to station container")
	print("Domino container child count: %d" % domino_container.get_child_count())
	print("Domino position: %s" % str(domino.position))
	print("Domino size: %s" % str(domino.size))
	print("Domino visible: %s" % str(domino.visible))
		# Set as our engine domino
	engine_domino = domino
	print("Engine domino set: %s" % str(engine_domino))
	
	# Update label
	var dots = domino.get_dots()
	station_label.text = "ENGINE\n%d-%d" % [dots.x, dots.y]
	
	# Emit signal that engine domino was placed
	engine_domino_placed.emit()
		# Clean up drag metadata
	if get_tree().has_meta("current_drag_domino"):
		get_tree().remove_meta("current_drag_domino")
	if get_tree().has_meta("current_drag_source"):
		get_tree().remove_meta("current_drag_source")
	
	print("Station accepted %d-%d domino as engine - train can now be extended!" % [dots.x, dots.y])

func _notification(what: int) -> void:
	"""Handle drag exit to hide highlight"""
	if what == NOTIFICATION_DRAG_END:
		if drop_highlight:
			drop_highlight.visible = false

func initialize_empty() -> void:
	"""Initialize the station without an engine domino (user will drag one)"""
	# Clear any existing domino
	if engine_domino:
		engine_domino.queue_free()
		engine_domino = null
	
	# Update label to show instruction for user
	station_label.text = "STATION\n(Drop double here)"
	print("Station initialized empty - waiting for engine domino")
