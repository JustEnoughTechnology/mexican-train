extends Control

## Admin Login Panel
## Handles admin authentication interface

signal login_requested(email: String, password: String)

# UI References
@onready var email_input: LineEdit = $VBox/EmailInput
@onready var password_input: LineEdit = $VBox/PasswordInput
@onready var login_button: Button = $VBox/LoginButton
@onready var status_label: Label = $VBox/StatusLabel

func _ready() -> void:
	setup_ui()
	setup_connections()

func setup_ui() -> void:
	# Pre-fill admin credentials for convenience
	if email_input:
		email_input.text = "admin@mexicantrain.local"
		email_input.placeholder_text = "Enter admin email"
	
	if password_input:
		password_input.text = "admin123"
		password_input.placeholder_text = "Enter password"
		password_input.secret = true
	
	if status_label:
		status_label.text = "Please enter admin credentials"
		status_label.modulate = Color.WHITE

func setup_connections() -> void:
	if login_button:
		login_button.pressed.connect(_on_login_button_pressed)
	
	if email_input:
		email_input.text_submitted.connect(_on_text_submitted)
	
	if password_input:
		password_input.text_submitted.connect(_on_text_submitted)
	
	# Connect to ServerAdmin signals
	ServerAdmin.admin_authenticated.connect(_on_admin_authenticated)
	ServerAdmin.admin_access_denied.connect(_on_admin_access_denied)

func _on_login_button_pressed() -> void:
	attempt_login()

func _on_text_submitted(_text: String) -> void:
	attempt_login()

func attempt_login() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text
	
	if email.is_empty():
		show_status("Please enter an email address", Color.RED)
		return
	
	if password.is_empty():
		show_status("Please enter a password", Color.RED)
		return
	
	show_status("Connecting to server...", Color.YELLOW)
	login_button.disabled = true
	
	# Emit signal to main dashboard
	login_requested.emit(email, password)

func _on_admin_authenticated(_admin_email: String) -> void:
	show_status("Login successful!", Color.GREEN)
	# Dashboard will handle showing the main panel

func _on_admin_access_denied(_email: String, reason: String) -> void:
	show_status("Access denied: " + reason, Color.RED)
	enable_login_button()
	# Clear sensitive data on failed login
	if password_input:
		password_input.text = ""

func show_status(message: String, color: Color) -> void:
	if status_label:
		status_label.text = message
		status_label.modulate = color

func enable_login_button() -> void:
	"""Re-enable the login button (called when authentication fails or times out)"""
	if login_button:
		login_button.disabled = false

func reset_form() -> void:
	if password_input:
		password_input.text = ""
	if login_button:
		login_button.disabled = false
	show_status("Please enter admin credentials", Color.WHITE)
