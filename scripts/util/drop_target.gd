## A script to make a container accept domino drops
extends GridContainer

# Override these methods to enable drag and drop functionality
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	# Only accept Domino instances
	return data is Domino

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data is Domino:
		# Get the parent Hand to use its add_domino method
		# This traversal may need adjustment based on your scene hierarchy
		var parent = get_parent()
		while parent != null and not parent is Hand:
			parent = parent.get_parent()
		
		if parent is Hand:
			# Add the domino to the hand
			parent.add_domino(data)			# Debug logging
			Logger.log_debug(Logger.LogArea.GAME, "Added domino to hand: " + str(data.get_dots()))
		else:
			Logger.log_error(Logger.LogArea.GAME, "Could not find Hand parent to add domino")
