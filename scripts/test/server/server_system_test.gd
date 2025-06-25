extends Control

## Automated Test Runner for Mexican Train Server System
## Tests server startup, admin access, and basic functionality

@onready var test_output = $VBox/ScrollContainer/TestOutput
@onready var run_tests_button = $VBox/RunTestsButton
@onready var progress_bar = $VBox/ProgressBar

var test_results: Array[String] = []
var current_test: int = 0
var total_tests: int = 8

func _ready() -> void:
	get_window().title = "Mexican Train - System Tests"
	run_tests_button.pressed.connect(_run_all_tests)
	_add_log("=== Mexican Train Server Test Suite ===")
	_add_log("Click 'Run Tests' to begin automated testing")

func _run_all_tests() -> void:
	run_tests_button.disabled = true
	test_results.clear()
	current_test = 0
	progress_bar.value = 0
	
	_add_log("\n=== Starting Test Suite ===")
	
	# Run tests sequentially
	_test_autoloads()
	_test_server_admin()
	_test_network_manager()
	_test_lobby_manager()
	_test_game_creation()
	_test_statistics_tracking()
	_test_admin_authentication()
	_test_server_metrics()
	
	_show_test_summary()
	run_tests_button.disabled = false

func _test_autoloads() -> void:
	_start_test("Testing Autoload Systems")
	
	var autoloads = ["Global", "EventBus", "GameConfig", "LobbyManager", "NetworkManager", "ServerAdmin"]
	var success = true
	
	for autoload_name in autoloads:
		if has_node("/root/" + autoload_name):
			_add_log("✅ %s autoload: LOADED" % autoload_name)
		else:
			_add_log("❌ %s autoload: MISSING" % autoload_name)
			success = false
	
	_finish_test(success, "Autoload systems")

func _test_server_admin() -> void:
	_start_test("Testing ServerAdmin System")
	
	var success = true
	
	if not ServerAdmin:
		_finish_test(false, "ServerAdmin not available")
		return
	
	# Test authentication
	var auth_result = ServerAdmin.authenticate_admin("admin@mexicantrain.local", "admin123")
	if auth_result:
		_add_log("✅ Admin authentication: SUCCESS")
	else:
		_add_log("❌ Admin authentication: FAILED")
		success = false
	
	# Test metrics
	var metrics = ServerAdmin.get_server_metrics()
	if metrics.has("server_info") and metrics.has("current_state"):
		_add_log("✅ Server metrics: AVAILABLE")
		_add_log("   Version: %s" % metrics.server_info.get("version", "Unknown"))
		_add_log("   Uptime: %s" % metrics.server_info.get("uptime_formatted", "Unknown"))
	else:
		_add_log("❌ Server metrics: INCOMPLETE")
		success = false
	
	_finish_test(success, "ServerAdmin system")

func _test_network_manager() -> void:
	_start_test("Testing NetworkManager System")
	
	var success = true
	
	if not NetworkManager:
		_finish_test(false, "NetworkManager not available")
		return
	
	# Test configuration
	_add_log("✅ NetworkManager loaded")
	_add_log("   Default port: %d" % NetworkManager.DEFAULT_PORT)
	_add_log("   Max players: %d" % NetworkManager.MAX_PLAYERS)
	
	# Test server capabilities
	if NetworkManager.has_method("start_server"):
		_add_log("✅ Server start capability: AVAILABLE")
	else:
		_add_log("❌ Server start capability: MISSING")
		success = false
	
	_finish_test(success, "NetworkManager system")

func _test_lobby_manager() -> void:
	_start_test("Testing LobbyManager System")
	
	var success = true
	
	if not LobbyManager:
		_finish_test(false, "LobbyManager not available")
		return
	
	_add_log("✅ LobbyManager loaded")
	_add_log("   Max players per game: %d" % LobbyManager.MAX_PLAYERS_PER_GAME)
	
	# Test initial state
	var lobby_data = LobbyManager.get_lobby_data()
	_add_log("✅ Lobby data accessible")
	_add_log("   Active games: %d" % lobby_data.size())
	
	_finish_test(success, "LobbyManager system")

func _test_game_creation() -> void:
	_start_test("Testing Game Creation")
	
	var success = true
	
	# Test game code generation
	var game_code = LobbyManager.generate_game_code()
	if game_code.length() == 6:
		_add_log("✅ Game code generation: SUCCESS (%s)" % game_code)
	else:
		_add_log("❌ Game code generation: FAILED")
		success = false
	
	# Test game creation
	var test_game_code = LobbyManager.create_game(12345, "TestHost")
	if test_game_code.length() > 0:
		_add_log("✅ Game creation: SUCCESS (%s)" % test_game_code)
		
		# Test game info
		var game_info = LobbyManager.get_game_info(test_game_code)
		if game_info.has("host_name") and game_info.host_name == "TestHost":
			_add_log("✅ Game info retrieval: SUCCESS")
		else:
			_add_log("❌ Game info retrieval: FAILED")
			success = false
	else:
		_add_log("❌ Game creation: FAILED")
		success = false
	
	_finish_test(success, "Game creation")

func _test_statistics_tracking() -> void:
	_start_test("Testing Statistics Tracking")
	
	var success = true
	
	# Get initial metrics
	var initial_metrics = ServerAdmin.get_server_metrics()
	var initial_games = initial_metrics.statistics.total_games_created
	
	# Record a game creation
	ServerAdmin.record_game_created()
	
	# Get updated metrics
	var updated_metrics = ServerAdmin.get_server_metrics()
	var updated_games = updated_metrics.statistics.total_games_created
	
	if updated_games > initial_games:
		_add_log("✅ Game statistics tracking: SUCCESS")
		_add_log("   Games tracked: %d → %d" % [initial_games, updated_games])
	else:
		_add_log("❌ Game statistics tracking: FAILED")
		success = false
	
	_finish_test(success, "Statistics tracking")

func _test_admin_authentication() -> void:
	_start_test("Testing Admin Authentication")
	
	var success = true
	
	# Test valid credentials
	var valid_auth = ServerAdmin.authenticate_admin("admin@mexicantrain.local", "admin123")
	if valid_auth:
		_add_log("✅ Valid credentials: ACCEPTED")
	else:
		_add_log("❌ Valid credentials: REJECTED")
		success = false
	
	# Test invalid credentials
	var invalid_auth = ServerAdmin.authenticate_admin("invalid@test.com", "wrong")
	if not invalid_auth:
		_add_log("✅ Invalid credentials: REJECTED")
	else:
		_add_log("❌ Invalid credentials: ACCEPTED (security issue)")
		success = false
	
	# Test unauthorized email
	var unauth_email = ServerAdmin.authenticate_admin("hacker@bad.com", "admin123")
	if not unauth_email:
		_add_log("✅ Unauthorized email: REJECTED")
	else:
		_add_log("❌ Unauthorized email: ACCEPTED (security issue)")
		success = false
	
	_finish_test(success, "Admin authentication")

func _test_server_metrics() -> void:
	_start_test("Testing Server Metrics")
	
	var success = true
	
	var metrics = ServerAdmin.get_server_metrics()
	
	# Check required sections
	var required_sections = ["server_info", "current_state", "statistics", "system_resources", "network_status"]
	for section in required_sections:
		if metrics.has(section):
			_add_log("✅ Metrics section '%s': PRESENT" % section)
		else:
			_add_log("❌ Metrics section '%s': MISSING" % section)
			success = false
	
	# Check specific data
	if metrics.server_info.has("version") and metrics.server_info.version == "0.6.0":
		_add_log("✅ Version information: CORRECT")
	else:
		_add_log("❌ Version information: INCORRECT")
		success = false
	
	_finish_test(success, "Server metrics")

func _start_test(test_name: String) -> void:
	current_test += 1
	@warning_ignore("integer_division")
	progress_bar.value = float(current_test * 100) / float(total_tests)
	_add_log("\n--- Test %d/%d: %s ---" % [current_test, total_tests, test_name])

func _finish_test(success: bool, test_name: String) -> void:
	var status = "PASSED" if success else "FAILED"
	var icon = "✅" if success else "❌"
	_add_log("%s Test Result: %s" % [icon, status])
	test_results.append("%s: %s" % [test_name, status])
	
	# Brief pause between tests
	await get_tree().create_timer(0.5).timeout

func _show_test_summary() -> void:
	_add_log("\n=== TEST SUMMARY ===")
	var passed = 0
	var failed = 0
	
	for result in test_results:
		_add_log(result)
		if result.ends_with("PASSED"):
			passed += 1
		else:
			failed += 1
	
	_add_log("\nResults: %d PASSED, %d FAILED" % [passed, failed])
	
	if failed == 0:
		_add_log("🎉 ALL TESTS PASSED! Server system is ready for use.")
	else:
		_add_log("⚠️  Some tests failed. Check configuration and try again.")
	
	progress_bar.value = 100

func _add_log(message: String) -> void:
	test_output.text += message + "\n"
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = test_output.get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
