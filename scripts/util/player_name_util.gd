class_name PlayerNameUtil

## Utility class for generating player names based on OS username or fallback
## Also supports unique naming for multiplayer scenarios

# Static array to track used player names to ensure uniqueness
static var used_player_names: Array[String] = []
# Static dictionary to cache player names by player number
static var player_name_cache: Dictionary = {}

static func get_player_name() -> String:
	
	## Generate a player name using the following rules:
	## 1. Try to get OS username
	## 2. If that fails, use "Player" + 3-digit random number (001-999)	
	
	var os_username = get_os_username()
	
	if os_username != "":
		Logger.log_info(Logger.LogArea.UI, "Using OS username for player: %s" % os_username)
		return os_username
	else:
		var random_number = randi_range(1, 999)
		var player_name = "Player%03d" % random_number
		Logger.log_info(Logger.LogArea.UI, "Using fallback player name: %s" % player_name)
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
			Logger.log_debug(Logger.LogArea.SYSTEM, "Found username via %s: %s" % [env_var, username])
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
						Logger.log_debug(Logger.LogArea.SYSTEM, "Extracted username from user data path: %s" % username)
						return username
	
	Logger.log_debug(Logger.LogArea.SYSTEM, "Unable to determine OS username, will use fallback")
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

static func get_unique_player_name(player_number: int = -1) -> String:
	"""
	Generate a unique player name for multiplayer scenarios
	Args:
		player_number: Optional player number (1-8 for 8-player game)
	Returns:
		A unique player name with 3-digit suffix if needed
	"""
	# If we've already generated a name for this player number, return it
	if player_number > 0 and player_number in player_name_cache:
		return player_name_cache[player_number]
	
	var base_name = ""
	
	# Try to get OS username first
	var os_username = get_os_username()
	if os_username != "":
		base_name = os_username
	else:
		base_name = "Player"
	
	var candidate_name = ""
	
	# If player_number is specified, use it as suffix
	if player_number > 0:
		candidate_name = "%s%03d" % [base_name, player_number]
		if not candidate_name in used_player_names:
			used_player_names.append(candidate_name)
			player_name_cache[player_number] = candidate_name
			Logger.log_debug(Logger.LogArea.SYSTEM, "Generated unique player name: %s" % candidate_name)
			return candidate_name
	
	# Check if base name is unique (for cases without player_number)
	if not base_name in used_player_names:
		used_player_names.append(base_name)
		if player_number > 0:
			player_name_cache[player_number] = base_name
		Logger.log_debug(Logger.LogArea.SYSTEM, "Using unique base name: %s" % base_name)
		return base_name
	
	# Base name is taken, generate unique suffix
	var suffix = 1
	candidate_name = "%s%03d" % [base_name, suffix]
	
	while candidate_name in used_player_names:
		suffix += 1
		candidate_name = "%s%03d" % [base_name, suffix]
		
		# Safety check to prevent infinite loop
		if suffix > 999:
			break
	
	used_player_names.append(candidate_name)
	if player_number > 0:
		player_name_cache[player_number] = candidate_name
	Logger.log_debug(Logger.LogArea.SYSTEM, "Generated unique player name with suffix: %s" % candidate_name)
	return candidate_name

static func get_unique_hand_label(player_number: int = -1) -> String:
	"""
	Generate a unique hand label for multiplayer scenarios
	"""
	var player_name = get_unique_player_name(player_number)
	return "%s's Hand" % player_name

static func get_unique_train_label(player_number: int = -1) -> String:
	"""
	Generate a unique train label for multiplayer scenarios
	"""
	var player_name = get_unique_player_name(player_number)
	return "%s's Train" % player_name

static func clear_used_names() -> void:
	"""
	Clear the list of used player names (useful for restarting games)
	"""
	used_player_names.clear()
	player_name_cache.clear()
	Logger.log_debug(Logger.LogArea.SYSTEM, "Cleared used player names list and cache")
