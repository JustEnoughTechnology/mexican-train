extends RefCounted

## Lobby Manager Script (Local)
## This is a placeholder - the actual LobbyManager is in autoload/lobby_manager.gd

class_name LocalLobbyManager

static func get_lobby_reference():
	# Return reference to the autoloaded LobbyManager
	# Since this is RefCounted, we can't use get_node directly
	print("Use the autoloaded LobbyManager instead of this local script")
	return null

static func get_info() -> String:
	return "This is a placeholder. Use the autoloaded LobbyManager instead."