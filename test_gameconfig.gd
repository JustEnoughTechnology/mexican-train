extends SceneTree

## Test GameConfig Autoload
## Simple test to verify GameConfig constants and functionality

func _init() -> void:
	print("=== GameConfig Test ===")
	
	# Test GameConfig constants
	test_game_config()
	
	# Exit after test
	quit()

func test_game_config() -> void:
	print("Testing GameConfig autoload...")
	
	# Check if GameConfig is available
	if not GameConfig:
		print("❌ GameConfig autoload not found!")
		return
	
	print("✅ GameConfig autoload found")
	
	# Test constants
	print("Default Port: %d" % GameConfig.DEFAULT_PORT)
	print("Max Players: %d" % GameConfig.MAX_PLAYERS)
	print("Max Dots: %d" % GameConfig.MAX_DOTS)
	
	print("✅ GameConfig test completed")