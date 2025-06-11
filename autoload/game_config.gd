extends Node

## Global game configuration constants and settings for Mexican Train
## This autoload contains server-wide settings and constants used across the entire application

# Network configuration
const DEFAULT_PORT = 9957
const MAX_PLAYERS = 8

# Game rules configuration  
const MAX_DOTS = 12  # 12x12 domino set (0-0 to 12-12, 91 total dominoes)

# Sorting options
enum Sort {SORT_ASCENDING, SORT_DESCENDING}

# Global debug toggle for print output
var DEBUG_SHOW_WARNINGS := false

# Minimum required Godot version
const MIN_GODOT_VERSION = "4.4"

# Global player name storage (for lobby system)
var player_names : Array[String]

func _ready() -> void:
	# Check Godot version at startup
	_check_godot_version()

func _check_godot_version() -> void:
	var version = Engine.get_version_info()
	var version_str = "%d.%d" % [version["major"], version["minor"]]
	if version_str < MIN_GODOT_VERSION:
		push_error("This project requires Godot version %s or higher. Current version: %s. Exiting." % [MIN_GODOT_VERSION, version_str])
		get_tree().quit()

func get_total_domino_count() -> int:
	# Calculate total number of dominoes in a set from 0-0 to MAX_DOTS-MAX_DOTS
	return (MAX_DOTS + 1) * (MAX_DOTS + 2) / 2
