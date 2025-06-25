extends Node

# =============================================================================
# LOGGING SYSTEM USAGE EXAMPLE
# =============================================================================
# This script demonstrates how to use the new professional logging system

func _ready() -> void:
	print("\n=== MEXICAN TRAIN LOGGING SYSTEM DEMO ===")
	
	# Wait a moment for Logger to initialize
	await get_tree().process_frame
	
	# Show current configuration
	print("\n1. Current logging configuration:")
	Logger.print_config()
	
	# Demonstrate different log levels
	print("\n2. Demonstrating log levels:")
	Logger.log_emergency(Logger.LogArea.SYSTEM, "This is an emergency message")
	Logger.log_alert(Logger.LogArea.ADMIN, "This is an alert message")
	Logger.log_critical(Logger.LogArea.GAME, "This is a critical message")
	Logger.log_error(Logger.LogArea.NETWORK, "This is an error message")
	Logger.log_warning(Logger.LogArea.MULTIPLAYER, "This is a warning message")
	Logger.log_notice(Logger.LogArea.LOBBY, "This is a notice message")
	Logger.log_info(Logger.LogArea.AI, "This is an info message")
	Logger.log_debug(Logger.LogArea.UI, "This is a debug message")
	
	# Demonstrate area filtering
	print("\n3. Changing log levels at runtime:")
	Logger.set_area_log_level(Logger.LogArea.NETWORK, Logger.LogLevel.DEBUG)
	Logger.log_debug(Logger.LogArea.NETWORK, "Network debug message (should appear)")
	
	Logger.set_area_log_level(Logger.LogArea.UI, Logger.LogLevel.ERROR)
	Logger.log_debug(Logger.LogArea.UI, "UI debug message (should NOT appear)")
	Logger.log_error(Logger.LogArea.UI, "UI error message (should appear)")
	
	# Demonstrate backward compatibility
	print("\n4. Backward compatibility with Global.debug_print:")
	Global.debug_print("Old style network message", "network")
	Global.debug_print("Old style admin message", "admin")
	Global.debug_print("Old style general message", "general")
	
	# Demonstrate configuration changes
	print("\n5. Configuration changes:")
	print("Available log levels:", Logger.get_log_levels())
	print("Available log areas:", Logger.get_log_areas())
	
	# Example: Enable verbose debugging for development
	print("\n6. Enabling development mode (all debug messages):")
	Logger.set_global_log_level(Logger.LogLevel.DEBUG)
	Logger.log_debug(Logger.LogArea.GAME, "Game debug message (should now appear)")
	Logger.log_debug(Logger.LogArea.MULTIPLAYER, "Multiplayer debug message (should now appear)")
	
	print("\n=== LOGGING DEMO COMPLETE ===\n")
	
	# Clean up: reset to normal logging levels
	Logger.set_global_log_level(Logger.LogLevel.INFO)
