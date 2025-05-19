extends HFlowContainer

@export var max_width: float = 1000.0
@export var max_height: float = 800.0
func _ready() -> void:
	connect("child_entered_tree", Callable(self, "_on_child_modified"))
	connect("child_exiting_tree", Callable(self, "_on_child_modified"))

	# Initial signal hookup and layout
	_hookup_child_signals()
	resize_hflowcontainer_to_fit_children()

func _on_child_modified(child: Node) -> void:
	# Reconnect signals for new/removed children
	_hookup_child_signals()
	resize_hflowcontainer_to_fit_children()

func _hookup_child_signals() -> void:
	# Ensure all current children are connected
	for child in get_children():
		if child is Control:
			if not child.is_connected("resized", Callable(self, "_on_child_resized")):
				child.connect("resized", Callable(self, "_on_child_resized"))
			if not child.is_connected("visibility_changed", Callable(self, "_on_child_resized")):
				child.connect("visibility_changed", Callable(self, "_on_child_resized"))

func resize_hflowcontainer_to_fit_children() -> void:
	var total_width := 0.0
	var h_separation :int = get("theme_override_constants/h_separation")
	var visible_children := []

	# First, gather visible children (Control nodes)
	for child in get_children():
		if child is Control and child.visible:
			visible_children.append(child)

	# Sum up total width and max height of visible children
	for i in range(visible_children.size()):
		var control_child :Domino = visible_children[i]
		control_child.reset_size()
		total_width += control_child.size.x
		if i < visible_children.size() - 1:
			total_width += h_separation
		max_height = max(max_height, control_child.size.y)

	# Clamp the width to not exceed the max
	var final_width : float = min(total_width, max_width)

	# Apply as the container's custom minimum size
	custom_minimum_size = Vector2(final_width, max_height)
