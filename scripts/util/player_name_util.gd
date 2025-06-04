class_name PlayerNameUtil

## Utility class for generating player names based on OS username or fallback
static func get_player_name() -> String:
	"""
	Generate a player name using the following rules:
	1. Try to get OS username
	2. If that fails, use "Player" + 3-digit random number (001-999)
	"""
	var os_username = get_os_username()
	
	if os_username != "":
		print("Using OS username for player: %s" % os_username)
		return os_username
	else:
		var random_number = randi_range(1, 999)
		var player_name = "Player%03d" % random_number
		print("Using fallback player name: %s" % player_name)
		return player_name

static func get_os_username() -> String:
	"""
	Attempt to retrieve the OS username using various methods
	Returns empty string if unable to determine username
	"""
	var username = ""
	
	# Method 1: Try environment variables (works on Windows, Linux, macOS)
	var env_vars = ["USERNAME", "USER", "LOGNAME"]
	for env_var in env_vars:
		username = OS.get_environment(env_var)
		if username != "":
			print("Found username via %s: %s" % [env_var, username])
			return username
	
	# Method 2: Try system info (Godot 4.x specific)
	if OS.has_method("get_user_data_dir"):
		var user_data_path = OS.get_user_data_dir()
		# Extract username from user data path
		# Example paths:
		# Windows: C:/Users/[username]/AppData/Roaming/Godot/...
		# Linux: /home/[username]/.local/share/godot/...
		# macOS: /Users/[username]/Library/Application Support/Godot/...
		
		if "Users/" in user_data_path or "home/" in user_data_path:
			var path_parts = user_data_path.split("/")
			for i in range(path_parts.size()):
				if path_parts[i] == "Users" or path_parts[i] == "home":
					if i + 1 < path_parts.size():
						username = path_parts[i + 1]
						print("Extracted username from user data path: %s" % username)
						return username
	
	print("Unable to determine OS username, will use fallback")
	return ""

static func get_hand_label(player_name: String = "") -> String:
	"""
	Generate a label for the hand display
	"""
	if player_name == "":
		player_name = get_player_name()
	return "%s's Hand" % player_name

static func get_train_label(player_name: String = "") -> String:
	"""
	Generate a label for the train display  
	"""
	if player_name == "":
		player_name = get_player_name()
	return "%s's Train" % player_name
