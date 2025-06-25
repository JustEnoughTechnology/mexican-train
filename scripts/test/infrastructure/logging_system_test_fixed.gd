extends Node

# =============================================================================
# LOGGING SYSTEM TEST SCRIPT
# =============================================================================
# Run this script to test the new professional logging system

func _ready() -> void:
	# Allow time for autoloads to initialize
	await get_tree().process_frame
	
	run_logging_tests()

func run_logging_tests() -> void:
	var separator = "============================================================"
	print("\n" + separator)
	print("MEXICAN TRAIN - LOGGING SYSTEM TEST")
	print(separator)
	
	# Test 1: Basic logging functionality
	print("\n1. Testing basic logging at different levels:")
	Logger.log_emergency(Logger.LogArea.SYSTEM, "Emergency: System failure detected!")
	Logger.log_alert(Logger.LogArea.ADMIN, "Alert: Unauthorized access attempt")
	Logger.log_critical(Logger.LogArea.GAME, "Critical: Game state corruption")
	Logger.log_error(Logger.LogArea.NETWORK, "Error: Connection timeout")
	Logger.log_warning(Logger.LogArea.MULTIPLAYER, "Warning: High latency detected")
	Logger.log_notice(Logger.LogArea.LOBBY, "Notice: New game created")
	Logger.log_info(Logger.LogArea.AI, "Info: AI player made move")
	Logger.log_debug(Logger.LogArea.UI, "Debug: Button clicked")
	
	# Test 2: Configuration from Global
	print("\n2. Testing configuration from Global autoload:")
	var config = Global.get_logging_config()
	print("Global logging config: %s" % config)
	
	# Test 3: Runtime level changes
	print("\n3. Testing runtime level changes:")
	print("Setting NETWORK area to DEBUG level...")
	Logger.set_area_log_level(Logger.LogArea.NETWORK, Logger.LogLevel.DEBUG)
	Logger.log_debug(Logger.LogArea.NETWORK, "This network debug message should appear")
	
	print("Setting UI area to ERROR level...")
	Logger.set_area_log_level(Logger.LogArea.UI, Logger.LogLevel.ERROR)
	Logger.log_debug(Logger.LogArea.UI, "This UI debug message should NOT appear")
	Logger.log_error(Logger.LogArea.UI, "This UI error message should appear")
	
	# Test 4: Backward compatibility
	print("\n4. Testing backward compatibility with Global.debug_print:")
	Global.debug_print("Old-style admin message", "admin")
	Global.debug_print("Old-style network message", "network")
	Global.debug_print("Old-style general message")
	
	# Test 5: Configuration display
	print("\n5. Current logging configuration:")
	Logger.print_config()
	
	# Test 6: Mexican Train specific logging
	print("\n6. Mexican Train specific logging examples:")
	Logger.log_info(Logger.LogArea.MULTIPLAYER, "Server started on port 9957")
	Logger.log_info(Logger.LogArea.LOBBY, "Game ABCD12 created by player 1")
	Logger.log_debug(Logger.LogArea.AI, "AI player evaluating move options")
	Logger.log_info(Logger.LogArea.GAME, "Turn changed to player 2")
	Logger.log_warning(Logger.LogArea.ADMIN, "Admin authentication failed for user@example.com")
	
	print("\n" + separator)
	print("LOGGING SYSTEM TEST COMPLETE")
	print(separator + "\n")
	
	# Clean up: reset logging levels
	Logger.set_global_log_level(Logger.LogLevel.INFO)
	Logger.set_area_log_level(Logger.LogArea.NETWORK, Logger.LogLevel.INFO)
	Logger.set_area_log_level(Logger.LogArea.UI, Logger.LogLevel.WARNING)
	
	# Exit after a brief pause
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()
