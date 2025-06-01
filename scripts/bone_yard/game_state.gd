
extends Node

const DEFAULT_PORT = 9957
const MAX_PLAYERS = 8
const MAX_DOTS = 12
var current_player: Player
enum Sort {SORT_ASCENDING, SORT_DESCENDING}

# Global debug toggle for print output
var DEBUG_SHOW_WARNINGS := false

var player_names : Array[String]

# Minimum required Godot version
const MIN_GODOT_VERSION = "4.4"

func _init() -> void:
	# Check Godot version at startup
	var version = Engine.get_version_info()
	var version_str = "%d.%d" % [version["major"], version["minor"]]
	if version_str < MIN_GODOT_VERSION:
		push_error("This project requires Godot version %s or higher. Current version: %s. Exiting." % [MIN_GODOT_VERSION, version_str])
		get_tree().quit()
