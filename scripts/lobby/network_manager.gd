extends RefCounted

## Network Manager Script (Local)
## This is a placeholder - the actual NetworkManager is in autoload/network_manager.gd

class_name LocalNetworkManager

static func get_network_reference():
	# Return reference to the autoloaded NetworkManager
	# Since this is RefCounted, we can't use get_node directly
	print("Use the autoloaded NetworkManager instead of this local script")
	return null

static func get_info() -> String:
	return "This is a placeholder. Use the autoloaded NetworkManager instead."