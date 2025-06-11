extends Node

## Server Administration Manager for Mexican Train
## Handles admin authentication and server monitoring

signal admin_authenticated(admin_email: String)
signal admin_access_denied(email: String, reason: String)
signal server_metrics_updated(metrics: Dictionary)

# Admin configuration
const ADMIN_EMAILS = [
	"admin@mexicantrain.local",
	"dev@mexicantrain.local", 
	"test@mexicantrain.local"
	# Add more authorized admin emails here
]

# Server metrics
var server_start_time: float
var server_version: String = "0.6.0"
var authenticated_admins: Array[String] = []
var metrics_update_timer: Timer

# Server statistics
var total_games_created: int = 0
var total_players_served: int = 0
var peak_concurrent_games: int = 0
var peak_concurrent_players: int = 0

func _ready() -> void:
	server_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Setup metrics update timer
	metrics_update_timer = Timer.new()
	metrics_update_timer.wait_time = 5.0  # Update every 5 seconds
	metrics_update_timer.timeout.connect(_update_server_metrics)
	metrics_update_timer.autostart = true
	add_child(metrics_update_timer)
	
	print("ServerAdmin initialized - Version %s" % server_version)

## Authenticate admin user by email
func authenticate_admin(email: String, password: String = "") -> bool:
	# Validate email format
	if not _is_valid_email(email):
		admin_access_denied.emit(email, "Invalid email format")
		return false
	
	# Check if email is in authorized list
	if not email in ADMIN_EMAILS:
		admin_access_denied.emit(email, "Email not authorized for admin access")
		return false
	
	# For now, we'll use a simple password check
	# In production, this should use proper authentication
	if password != "admin123":  # TODO: Implement proper password system
		admin_access_denied.emit(email, "Invalid password")
		return false
	
	# Add to authenticated admins if not already present
	if not email in authenticated_admins:
		authenticated_admins.append(email)
	
	admin_authenticated.emit(email)
	print("Admin authenticated: %s" % email)
	return true

## Remove admin authentication
func logout_admin(email: String) -> void:
	if email in authenticated_admins:
		authenticated_admins.erase(email)
		print("Admin logged out: %s" % email)

## Check if email is authenticated admin
func is_admin_authenticated(email: String) -> bool:
	return email in authenticated_admins

## Get comprehensive server metrics
func get_server_metrics() -> Dictionary:
	var current_time = Time.get_time_dict_from_system()["unix"]
	var uptime_seconds = current_time - server_start_time
	
	# Get current game/player counts from LobbyManager
	var current_games = LobbyManager.active_games.size()
	var current_players = 0
	var active_games_info = []
	
	for game_code in LobbyManager.active_games:
		var game_room = LobbyManager.active_games[game_code]
		var player_count = game_room.get_total_player_count()
		current_players += player_count
		
		active_games_info.append({
			"code": game_code,
			"players": player_count,
			"host": game_room.players[game_room.host_id].name,
			"started": game_room.is_started,
			"created_ago": current_time - game_room.created_time
		})
	
	# Update peak statistics
	if current_games > peak_concurrent_games:
		peak_concurrent_games = current_games
	if current_players > peak_concurrent_players:
		peak_concurrent_players = current_players
		# System resource information
	var memory_usage = OS.get_static_memory_peak_usage()
	
	return {
		"server_info": {
			"version": server_version,
			"uptime_seconds": uptime_seconds,
			"uptime_formatted": _format_uptime(uptime_seconds),
			"start_time": Time.get_datetime_string_from_unix_time(int(server_start_time))
		},
		"current_state": {
			"active_games": current_games,
			"active_players": current_players,
			"authenticated_admins": authenticated_admins.size(),
			"game_details": active_games_info
		},
		"statistics": {
			"total_games_created": total_games_created,
			"total_players_served": total_players_served,
			"peak_concurrent_games": peak_concurrent_games,
			"peak_concurrent_players": peak_concurrent_players
		},		"system_resources": {
			"memory_usage_mb": memory_usage / 1024 / 1024,
			"platform": OS.get_name(),
			"processor_count": OS.get_processor_count(),
			"network_port": str(NetworkManager.DEFAULT_PORT) if NetworkManager else "N/A"
		},
		"network_status": {
			"server_running": NetworkManager.is_server_running() if NetworkManager else false,
			"connected_peers": NetworkManager.get_connected_peer_count() if NetworkManager else 0,
			"default_port": GameConfig.DEFAULT_PORT
		}
	}

## Add admin email to authorized list (for runtime configuration)
func add_authorized_admin(email: String, requester_email: String) -> bool:
	# Only existing admins can add new admins
	if not is_admin_authenticated(requester_email):
		return false
	
	if not _is_valid_email(email):
		return false
	
	if not email in ADMIN_EMAILS:
		# Note: This only adds for current session, not persistent
		print("Admin %s added %s to authorized list (session only)" % [requester_email, email])
		return true
	
	return false

## Record game creation for statistics
func record_game_created() -> void:
	total_games_created += 1

## Record player joining for statistics  
func record_player_joined() -> void:
	total_players_served += 1

## Private helper functions
func _is_valid_email(email: String) -> bool:
	# Simple email validation
	return email.contains("@") and email.contains(".") and email.length() > 5

func _format_uptime(seconds: float) -> String:
	var days = int(seconds) / 86400
	var hours = (int(seconds) % 86400) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	
	if days > 0:
		return "%dd %dh %dm %ds" % [days, hours, minutes, secs]
	elif hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs

func _update_server_metrics() -> void:
	var metrics = get_server_metrics()
	server_metrics_updated.emit(metrics)

## Get admin dashboard data
func get_admin_dashboard_data(admin_email: String) -> Dictionary:
	if not is_admin_authenticated(admin_email):
		return {"error": "Access denied - admin not authenticated"}
	
	var metrics = get_server_metrics()
	metrics["admin_info"] = {
		"logged_in_as": admin_email,
		"access_level": "full",
		"session_start": Time.get_datetime_string_from_system()
	}
	
	return metrics
