extends Node

# =============================================================================
# GLOBAL CONFIGURATION AND UTILITIES
# =============================================================================

# Logging Configuration (used by Logger autoload)
var logging_config: Dictionary = {
	# Override default logging behavior
	"global_level": 6,  # INFO level by default (Logger.LogLevel.INFO)
	"areas": {
		# You can override specific areas here - examples:
		# Logger.LogArea.ADMIN: Logger.LogLevel.DEBUG
		# Logger.LogArea.NETWORK: Logger.LogLevel.DEBUG  # Enable network debug
		# Logger.LogArea.MULTIPLAYER: Logger.LogLevel.WARNING  # Less verbose multiplayer
	},
	"console_output": true,
	"file_output": false,  # Set to true to enable file logging
	"file_path": "user://logs/mexican_train.log"
}

# Function to get logging configuration (called by Logger)
func get_logging_config() -> Dictionary:
	return logging_config

# Function to update logging configuration at runtime
func set_logging_config(new_config: Dictionary) -> void:
	for key in new_config.keys():
		if logging_config.has(key):
			logging_config[key] = new_config[key]
	
	# Notify Logger of configuration change if it exists
	if has_node("/root/Logger"):
		get_node("/root/Logger")._load_config_from_global()

# =============================================================================
# BACKWARD COMPATIBILITY
# =============================================================================

## Legacy debug function for backward compatibility - converts to new Logger system
func debug_print(message: String, category: String = "general") -> void:
	if not has_node("/root/Logger"):
		print("[DEBUG:%s] %s" % [category.to_upper(), message])
		return
		
	var logger = get_node("/root/Logger")
	var area: int  # Logger.LogArea
	
	# Map old categories to new logging areas
	match category.to_lower():
		"admin":
			area = logger.LogArea.ADMIN
		"network", "multiplayer":
			area = logger.LogArea.NETWORK
		"lobby":
			area = logger.LogArea.LOBBY
		"game":
			area = logger.LogArea.GAME
		"ai":
			area = logger.LogArea.AI
		_:
			area = logger.LogArea.GENERAL
	
	logger.log_debug(area, message)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
		
func is_child_outside_parent(child: Control, parent: Control) -> bool:
	if EngineDebugger.is_active():
		print("child: ",child.get_global_rect()," parent: ",parent.get_global_rect())
	return not parent.get_global_rect().encloses(child.get_global_rect())
 
func resize_hbox_to_fit_children(hbox: HBoxContainer):	
	var total_width = 0.0
	var max_height = 0.0    
	for child in hbox.get_children():
		if child is Control:
			var ctrl := child as Control
			var size = ctrl.rect_size
			total_width += size.x + hbox.get_constant("separation")
			max_height = max(max_height, size.y)
	# Subtract extra separation added after last child
	total_width -= hbox.get_constant("separation")
	hbox.rect_min_size = Vector2(total_width, max_height)

# =============================================================================
# NOTIFICATION UTILITIES
# =============================================================================

const NOTIFICATONS = {
	"NOTIFICATION_POSTINITIALIZE": 0,
	"NOTIFICATION_PREDELETE": 1,
	"NOTIFICATION_EXTENSION_RELOADED": 2,
	"NOTIFICATION_ENTER_TREE": 10,
	"NOTIFICATION_EXIT_TREE": 11,
	"NOTIFICATION_MOVED_IN_PARENT": 12,
	"NOTIFICATION_READY": 13,
	"NOTIFICATION_PAUSED": 14,
	"NOTIFICATION_UNPAUSED": 15,
	"NOTIFICATION_PHYSICS_PROCESS": 16,
	"NOTIFICATION_PROCESS": 17,
	"NOTIFICATION_PARENTED": 18,
	"NOTIFICATION_UNPARENTED": 19,
	"NOTIFICATION_SCENE_INSTANTIATED": 20,
	"NOTIFICATION_DRAG_BEGIN": 21,
	"NOTIFICATION_DRAG_END": 22,
	"NOTIFICATION_PATH_RENAMED": 23,
	"NOTIFICATION_CHILD_ORDER_CHANGED": 24,
	"NOTIFICATION_INTERNAL_PROCESS": 25,
	"NOTIFICATION_INTERNAL_PHYSICS_PROCESS": 26,
	"NOTIFICATION_POST_ENTER_TREE": 27,
	"NOTIFICATION_DISABLED": 28,
	"NOTIFICATION_ENABLED": 29,
	"NOTIFICATION_DRAW": 30,
	"NOTIFICATION_VISIBILITY_CHANGED": 30,
	"NOTIFICATION_ENTER_CANVAS": 32,
	"NOTIFICATION_THEME_CHANGED": 32,
	"NOTIFICATION_EXIT_CANVAS": 33,
	"NOTIFICATION_WORLD_2D_CHANGED": 36,
	"NOTIFICATION_RESIZED": 40,
	"NOTIFICATION_MOUSE_ENTER": 41,
	"NOTIFICATION_ENTER_WORLD": 41,
	"NOTIFICATION_MOUSE_EXIT": 42,
	"NOTIFICATION_EXIT_WORLD": 42,
	"NOTIFICATION_FOCUS_ENTER": 43,
	"NOTIFICATION_LOCAL_TRANSFORM_CHANGED": 44,
	"NOTIFICATION_FOCUS_EXIT": 44,
	"NOTIFICATION_SCROLL_BEGIN": 47,
	"NOTIFICATION_SCROLL_END": 48,
	"NOTIFICATION_LAYOUT_DIRECTION_CHANGED": 49,
	"NOTIFICATION_PRE_SORT_CHILDREN": 50,
	"NOTIFICATION_UPDATE_SKELETON": 50,
	"NOTIFICATION_SORT_CHILDREN": 51,
	"NOTIFICATION_MOUSE_ENTER_SELF": 60,
	"NOTIFICATION_MOUSE_EXIT_SELF": 61,
	"NOTIFICATION_WM_MOUSE_ENTER": 1002,
	"NOTIFICATION_WM_MOUSE_EXIT": 1003,
	"NOTIFICATION_WM_WINDOW_FOCUS_IN": 1004,
	"NOTIFICATION_WM_WINDOW_FOCUS_OUT": 1005,
	"NOTIFICATION_WM_CLOSE_REQUEST": 1006,
	"NOTIFICATION_WM_GO_BACK_REQUEST": 1007,
	"NOTIFICATION_WM_SIZE_CHANGED": 1008,
	"NOTIFICATION_WM_DPI_CHANGE": 1009,
	"NOTIFICATION_VP_MOUSE_ENTER": 1010,
	"NOTIFICATION_VP_MOUSE_EXIT": 1011,
	"NOTIFICATION_WM_POSITION_CHANGED": 1012,
	"NOTIFICATION_TRANSFORM_CHANGED": 2000,
	"NOTIFICATION_RESET_PHYSICS_INTERPOLATION": 2001,
	"NOTIFICATION_OS_MEMORY_WARNING": 2009,
	"NOTIFICATION_TRANSLATION_CHANGED": 2010,
	"NOTIFICATION_WM_ABOUT": 2011,
	"NOTIFICATION_CRASH": 2012,
	"NOTIFICATION_OS_IME_UPDATE": 2013,
	"NOTIFICATION_APPLICATION_RESUMED": 2014,
	"NOTIFICATION_APPLICATION_PAUSED": 2015,
	"NOTIFICATION_APPLICATION_FOCUS_IN": 2016,
	"NOTIFICATION_APPLICATION_FOCUS_OUT": 2017,
	"NOTIFICATION_TEXT_SERVER_CHANGED": 2018,
	"NOTIFICATION_EDITOR_PRE_SAVE": 9001,
	"NOTIFICATION_EDITOR_POST_SAVE": 9002,
	"NOTIFICATION_EDITOR_SETTINGS_CHANGED": 10000,
}

var _name_cache: Dictionary = {}
var _reverse_notifications: Dictionary = {}

func _init():
	# Build reverse lookup map on initialization (works in editor and runtime)
	for key in NOTIFICATONS.keys():
		var code = NOTIFICATONS[key]
		_reverse_notifications[code] = key

# Fast code → name lookup (cached)
func get_notification_name(code: int) -> String:
	if code in _name_cache:
		return _name_cache[code]

	if code in _reverse_notifications:
		_name_cache[code] = _reverse_notifications[code]
		return _reverse_notifications[code]

	_name_cache[code] = "UNKNOWN_NOTIFICATION("+ str(code)+")"
	
	return "UNKNOWN_NOTIFICATION"
