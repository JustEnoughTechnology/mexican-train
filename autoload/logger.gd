extends Node

# =============================================================================
# MEXICAN TRAIN - LOGGING SYSTEM
# =============================================================================
# Professional logging system with syslog levels and application areas
# Checks Global autoload for configuration overrides

# =============================================================================
# LOG LEVELS (Based on RFC 5424 Syslog Standard)
# =============================================================================
enum LogLevel {
	EMERGENCY = 0,   # System is unusable
	ALERT = 1,       # Action must be taken immediately  
	CRITICAL = 2,    # Critical conditions
	ERROR = 3,       # Error conditions
	WARNING = 4,     # Warning conditions
	NOTICE = 5,      # Normal but significant condition
	INFO = 6,        # Informational messages
	DEBUG = 7        # Debug-level messages
}

# =============================================================================
# APPLICATION AREAS
# =============================================================================
enum LogArea {
	ADMIN,           # Admin dashboard and authentication
	MULTIPLAYER,     # Network multiplayer functionality
	AI,              # AI player logic and decisions
	GAME,            # Core game logic and rules
	LOBBY,           # Lobby and game room management
	NETWORK,         # Low-level networking
	SYSTEM,          # System events, startup, shutdown
	DATABASE,        # Future: database operations
	UI,              # User interface events
	GENERAL          # General application events
}

# =============================================================================
# CONFIGURATION
# =============================================================================
var config: Dictionary = {
	"enabled": true,
	"global_min_level": LogLevel.INFO,
	"area_levels": {
		LogArea.ADMIN: LogLevel.INFO,
		LogArea.MULTIPLAYER: LogLevel.INFO,
		LogArea.AI: LogLevel.INFO,
		LogArea.GAME: LogLevel.INFO,
		LogArea.LOBBY: LogLevel.INFO,
		LogArea.NETWORK: LogLevel.INFO,
		LogArea.SYSTEM: LogLevel.WARNING,
		LogArea.DATABASE: LogLevel.INFO,
		LogArea.UI: LogLevel.WARNING,
		LogArea.GENERAL: LogLevel.INFO
	},
	
	# Output formatting
	"show_timestamps": true,
	"show_level_names": true,
	"show_area_names": true,
	"console_output": true,
	"file_output": false,
	"log_file_path": "user://logs/mexican_train.log"
}

# Level name mappings for display
var level_names: Dictionary = {
	LogLevel.EMERGENCY: "EMERG",
	LogLevel.ALERT: "ALERT", 
	LogLevel.CRITICAL: "CRIT",
	LogLevel.ERROR: "ERROR",
	LogLevel.WARNING: "WARN",
	LogLevel.NOTICE: "NOTICE",
	LogLevel.INFO: "INFO",
	LogLevel.DEBUG: "DEBUG"
}

# Area name mappings for display  
var area_names: Dictionary = {
	LogArea.ADMIN: "ADMIN",
	LogArea.MULTIPLAYER: "MULTI", 
	LogArea.AI: "AI",
	LogArea.GAME: "GAME",
	LogArea.LOBBY: "LOBBY",
	LogArea.NETWORK: "NET",
	LogArea.SYSTEM: "SYS",
	LogArea.DATABASE: "DB",
	LogArea.UI: "UI",
	LogArea.GENERAL: "GEN"
}

# =============================================================================
# INITIALIZATION
# =============================================================================
func _ready() -> void:
	_load_config_from_global()
	log_info(LogArea.SYSTEM, "Logger initialized with %d areas and %d levels" % [area_names.size(), level_names.size()])

## Load configuration from Global autoload if available
func _load_config_from_global() -> void:
	if not Global:
		return
		
	if Global.has_method("get_logging_config"):
		var global_config = Global.get_logging_config()
		_merge_config(global_config)
		log_info(LogArea.SYSTEM, "Loaded logging configuration from Global")
	else:
		log_info(LogArea.SYSTEM, "Using default logging configuration")

## Merge configuration from Global with defaults
func _merge_config(global_config: Dictionary) -> void:
	if global_config.has("global_level"):
		config.global_min_level = global_config.global_level
	
	if global_config.has("areas") and global_config.areas is Dictionary:
		for area in global_config.areas:
			if area in config.area_levels:
				config.area_levels[area] = global_config.areas[area]
	
	if global_config.has("console_output"):
		config.console_output = global_config.console_output
		
	if global_config.has("file_output"):
		config.file_output = global_config.file_output
		
	if global_config.has("file_path"):
		config.log_file_path = global_config.file_path

# =============================================================================
# MAIN LOGGING FUNCTION
# =============================================================================
## Core logging function - all logging goes through here
func write_log(level: LogLevel, area: LogArea, message: String) -> void:
	if not config.enabled:
		return
	
	# Check if this message should be logged
	if not _should_log(level, area):
		return
	
	# Build and output the log message
	var log_message = _build_log_message(level, area, message)
	
	if config.console_output:
		print(log_message)
	
	if config.file_output:
		_write_to_file(log_message)

# =============================================================================
# CONVENIENCE FUNCTIONS FOR EACH LOG LEVEL
# =============================================================================
func log_emergency(area: LogArea, message: String) -> void:
	write_log(LogLevel.EMERGENCY, area, message)

func log_alert(area: LogArea, message: String) -> void:
	write_log(LogLevel.ALERT, area, message)

func log_critical(area: LogArea, message: String) -> void:
	write_log(LogLevel.CRITICAL, area, message)

func log_error(area: LogArea, message: String) -> void:
	write_log(LogLevel.ERROR, area, message)

func log_warning(area: LogArea, message: String) -> void:
	write_log(LogLevel.WARNING, area, message)

func log_notice(area: LogArea, message: String) -> void:
	write_log(LogLevel.NOTICE, area, message)

func log_info(area: LogArea, message: String) -> void:
	write_log(LogLevel.INFO, area, message)

func log_debug(area: LogArea, message: String) -> void:
	write_log(LogLevel.DEBUG, area, message)

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================
## Set global minimum log level
func set_global_log_level(level: LogLevel) -> void:
	config.global_min_level = level
	log_info(LogArea.SYSTEM, "Global log level set to %s" % level_names[level])

## Set log level for specific area
func set_area_log_level(area: LogArea, level: LogLevel) -> void:
	config.area_levels[area] = level
	log_info(LogArea.SYSTEM, "Log level for %s set to %s" % [area_names[area], level_names[level]])

## Enable/disable logging entirely
func set_logging_enabled(enabled: bool) -> void:
	config.enabled = enabled
	if enabled:
		print("[SYSTEM] Logging enabled")
	else:
		print("[SYSTEM] Logging disabled")

## Toggle console output
func set_console_output(enabled: bool) -> void:
	config.console_output = enabled
	log_info(LogArea.SYSTEM, "Console output %s" % ("enabled" if enabled else "disabled"))

## Toggle file output  
func set_file_output(enabled: bool) -> void:
	config.file_output = enabled
	log_info(LogArea.SYSTEM, "File output %s" % ("enabled" if enabled else "disabled"))

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
## Check if a message should be logged based on level filtering
func _should_log(level: LogLevel, area: LogArea) -> bool:
	# Check global minimum level
	if level > config.global_min_level:
		return false
	
	# Check area-specific level
	if config.area_levels.has(area):
		return level <= config.area_levels[area]
	
	# Fallback to global level
	return level <= config.global_min_level

## Build formatted log message string
func _build_log_message(level: LogLevel, area: LogArea, message: String) -> String:
	var parts: Array = []
	
	# Add timestamp
	if config.show_timestamps:
		var time = Time.get_datetime_dict_from_system()
		var timestamp = "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
		parts.append("[%s]" % timestamp)
	
	# Add level name
	if config.show_level_names:
		parts.append("[%s]" % level_names.get(level, "UNK"))
	
	# Add area name
	if config.show_area_names:
		parts.append("[%s]" % area_names.get(area, "UNK"))
	
	# Add the message
	parts.append(message)
	
	return " ".join(parts)

## Write log message to file (future enhancement)
func _write_to_file(_message: String) -> void:
	# Future: implement file logging
	# For now, just ensure the directory exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
	
	# TODO: Implement actual file writing with rotation
	pass

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
## Get current configuration as dictionary (for debugging)
func get_config() -> Dictionary:
	return config.duplicate()

## Get list of available log levels
func get_log_levels() -> Array:
	return level_names.keys()

## Get list of available log areas
func get_log_areas() -> Array:
	return area_names.keys()

## Print current logging configuration
func print_config() -> void:
	print("\n=== LOGGING CONFIGURATION ===")
	print("Enabled: %s" % config.enabled)
	print("Global Level: %s" % level_names.get(config.global_min_level, "UNK"))
	print("Console Output: %s" % config.console_output)
	print("File Output: %s" % config.file_output)
	if config.file_output:
		print("Log File: %s" % config.log_file_path)
	
	print("\nArea-Specific Levels:")
	for area in config.area_levels:
		var area_name = area_names.get(area, "UNK")
		var level_name = level_names.get(config.area_levels[area], "UNK")
		print("  %s: %s" % [area_name, level_name])
	print("=============================\n")