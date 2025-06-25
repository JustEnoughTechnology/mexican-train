extends Control

## Admin Dashboard Test Script
## Simple test runner for the admin dashboard functionality

@onready var test_results_label: Label = $VBox/TestResultsLabel
@onready var run_tests_button: Button = $VBox/RunTestsButton
@onready var launch_dashboard_button: Button = $VBox/LaunchDashboardButton

var tests_passed: int = 0
var tests_total: int = 0

func _ready() -> void:
	setup_ui()
	run_basic_tests()

func setup_ui() -> void:
	get_window().title = "Admin Dashboard Test"
	
	if run_tests_button:
		run_tests_button.pressed.connect(_on_run_tests_pressed)
	
	if launch_dashboard_button:
		launch_dashboard_button.pressed.connect(_on_launch_dashboard_pressed)

func run_basic_tests() -> void:
	tests_passed = 0
	tests_total = 0
	
	var results = []
	
	# Test 1: Check if ServerAdmin autoload exists
	if test_autoload_exists("ServerAdmin"):
		results.append("✅ ServerAdmin autoload: PASS")
		tests_passed += 1
	else:
		results.append("❌ ServerAdmin autoload: FAIL")
	tests_total += 1
	
	# Test 2: Check if NetworkManager autoload exists
	if test_autoload_exists("NetworkManager"):
		results.append("✅ NetworkManager autoload: PASS")
		tests_passed += 1
	else:
		results.append("❌ NetworkManager autoload: FAIL")
	tests_total += 1
	
	# Test 3: Check if admin dashboard scene can be loaded
	if test_scene_exists("res://scenes/admin/admin_dashboard.tscn"):
		results.append("✅ Admin dashboard scene: PASS")
		tests_passed += 1
	else:
		results.append("❌ Admin dashboard scene: FAIL")
	tests_total += 1
	
	# Test 4: Check if admin scripts exist
	if test_script_exists("res://scripts/admin/admin_dashboard.gd"):
		results.append("✅ Admin dashboard script: PASS")
		tests_passed += 1
	else:
		results.append("❌ Admin dashboard script: FAIL")
	tests_total += 1
	
	# Test 5: Test admin authentication
	if test_admin_authentication():
		results.append("✅ Admin authentication: PASS")
		tests_passed += 1
	else:
		results.append("❌ Admin authentication: FAIL")
	tests_total += 1
	
	# Display results
	var summary = "Test Results: %d/%d PASSED\n\n" % [tests_passed, tests_total]
	summary += "\n".join(results)
	
	if tests_passed == tests_total:
		summary += "\n\n🎉 All tests passed! Admin dashboard is ready."
	else:
		summary += "\n\n⚠️ Some tests failed. Check the autoloads and file structure."
	
	if test_results_label:
		test_results_label.text = summary

func test_autoload_exists(autoload_name: String) -> bool:
	return has_node("/root/" + autoload_name)

func test_scene_exists(scene_path: String) -> bool:
	return ResourceLoader.exists(scene_path)

func test_script_exists(script_path: String) -> bool:
	return FileAccess.file_exists(script_path)

func test_admin_authentication() -> bool:
	if not has_node("/root/ServerAdmin"):
		return false
	
	# Test with valid credentials
	var server_admin = get_node("/root/ServerAdmin")
	var result = server_admin.call("authenticate_admin", "admin@mexicantrain.local", "admin123")
	
	if result:
		# Clean up - logout the admin
		server_admin.call("logout_admin", "admin@mexicantrain.local")
		return true
	
	return false

func _on_run_tests_pressed() -> void:
	run_basic_tests()

func _on_launch_dashboard_pressed() -> void:
	# Load and show the admin dashboard
	var dashboard_scene = preload("res://scenes/admin/admin_dashboard.tscn")
	var dashboard_instance = dashboard_scene.instantiate()
	
	# Create a new window for the dashboard
	var new_window = Window.new()
	new_window.title = "Admin Dashboard"
	new_window.size = Vector2i(1000, 700)
	new_window.add_child(dashboard_instance)
	
	get_tree().root.add_child(new_window)
	new_window.popup_centered()
	
	print("Admin dashboard launched in new window")
