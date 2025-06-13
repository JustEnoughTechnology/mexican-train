extends SceneTree

func _initialize():
	print("Testing GameConfig autoload...")
	print("GameConfig.MAX_DOTS = ", GameConfig.MAX_DOTS)
	print("GameConfig.DEFAULT_PORT = ", GameConfig.DEFAULT_PORT)
	print("Test complete")
	quit()
