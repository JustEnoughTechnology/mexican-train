class_name ColorThemeManager
extends RefCounted

## Mexican Train Dominoes Color Theme Manager
## Provides aesthetically pleasing color palettes for the game

# Available color themes
static var themes := [
	{
		"name": "Ocean Breeze",
		"description": "Cool blues and teals with warm accents",
		"background": Color(0.12, 0.16, 0.22, 1),
		"surface": Color(0.18, 0.22, 0.28, 1),
		"primary": Color(0.3, 0.6, 0.8, 1),
		"secondary": Color(0.4, 0.7, 0.7, 1),
		"accent": Color(0.8, 0.6, 0.3, 1),
		"players": [
			Color(0.3, 0.6, 0.8, 0.9),   # Sky Blue
			Color(0.6, 0.4, 0.7, 0.9),   # Lavender
			Color(0.5, 0.7, 0.4, 0.9),   # Sage Green
			Color(0.8, 0.6, 0.3, 0.9),   # Warm Gold
			Color(0.7, 0.5, 0.6, 0.9),   # Rose
			Color(0.4, 0.7, 0.7, 0.9),   # Teal
			Color(0.6, 0.3, 0.5, 0.9),   # Plum
			Color(0.8, 0.4, 0.2, 0.9)    # Coral
		]
	},
	{
		"name": "Forest Glade",
		"description": "Natural greens and earth tones",
		"background": Color(0.08, 0.15, 0.1, 1),
		"surface": Color(0.12, 0.2, 0.14, 1),
		"primary": Color(0.4, 0.7, 0.3, 1),
		"secondary": Color(0.6, 0.5, 0.3, 1),
		"accent": Color(0.8, 0.4, 0.2, 1),
		"players": [
			Color(0.4, 0.7, 0.3, 0.9),   # Forest Green
			Color(0.6, 0.7, 0.4, 0.9),   # Olive
			Color(0.3, 0.5, 0.4, 0.9),   # Pine
			Color(0.7, 0.5, 0.3, 0.9),   # Amber
			Color(0.5, 0.6, 0.7, 0.9),   # Storm Blue
			Color(0.7, 0.4, 0.5, 0.9),   # Berry
			Color(0.4, 0.4, 0.6, 0.9),   # Twilight
			Color(0.8, 0.6, 0.4, 0.9)    # Sunset
		]
	},
	{
		"name": "Sunset Mesa",
		"description": "Warm desert colors and sunset hues",
		"background": Color(0.18, 0.12, 0.15, 1),
		"surface": Color(0.25, 0.18, 0.2, 1),
		"primary": Color(0.9, 0.5, 0.3, 1),
		"secondary": Color(0.7, 0.4, 0.5, 1),
		"accent": Color(0.8, 0.7, 0.4, 1),
		"players": [
			Color(0.9, 0.5, 0.3, 0.9),   # Sunset Orange
			Color(0.7, 0.4, 0.5, 0.9),   # Desert Rose
			Color(0.6, 0.5, 0.7, 0.9),   # Sage Purple
			Color(0.8, 0.7, 0.4, 0.9),   # Golden Sand
			Color(0.5, 0.6, 0.5, 0.9),   # Cactus Green
			Color(0.7, 0.6, 0.6, 0.9),   # Clay Pink
			Color(0.4, 0.5, 0.6, 0.9),   # Storm Gray
			Color(0.6, 0.3, 0.4, 0.9)    # Mesa Red
		]
	},
	{
		"name": "Arctic Dawn",
		"description": "Cool whites and blues with subtle purples",
		"background": Color(0.15, 0.18, 0.22, 1),
		"surface": Color(0.2, 0.24, 0.28, 1),
		"primary": Color(0.7, 0.8, 0.9, 1),
		"secondary": Color(0.6, 0.7, 0.8, 1),
		"accent": Color(0.8, 0.7, 0.6, 1),
		"players": [
			Color(0.7, 0.8, 0.9, 0.9),   # Ice Blue
			Color(0.6, 0.7, 0.8, 0.9),   # Frost
			Color(0.5, 0.7, 0.7, 0.9),   # Glacier
			Color(0.8, 0.8, 0.7, 0.9),   # Snow
			Color(0.7, 0.6, 0.8, 0.9),   # Aurora Purple
			Color(0.6, 0.8, 0.7, 0.9),   # Mint Ice
			Color(0.5, 0.6, 0.7, 0.9),   # Steel Blue
			Color(0.8, 0.7, 0.6, 0.9)    # Warm White
		]
	},
	{
		"name": "Royal Court",
		"description": "Rich purples, golds, and deep colors",
		"background": Color(0.1, 0.08, 0.15, 1),
		"surface": Color(0.15, 0.12, 0.2, 1),
		"primary": Color(0.6, 0.3, 0.7, 1),
		"secondary": Color(0.8, 0.6, 0.2, 1),
		"accent": Color(0.9, 0.7, 0.3, 1),
		"players": [
			Color(0.6, 0.3, 0.7, 0.9),   # Royal Purple
			Color(0.8, 0.6, 0.2, 0.9),   # Gold
			Color(0.3, 0.5, 0.7, 0.9),   # Sapphire Blue
			Color(0.7, 0.3, 0.4, 0.9),   # Ruby Red
			Color(0.4, 0.6, 0.3, 0.9),   # Emerald Green
			Color(0.8, 0.5, 0.6, 0.9),   # Rose Gold
			Color(0.5, 0.4, 0.6, 0.9),   # Amethyst
			Color(0.7, 0.6, 0.4, 0.9)    # Bronze
		]
	},
	{
		"name": "Neon Nights",
		"description": "Vibrant neons with dark background",
		"background": Color(0.05, 0.05, 0.1, 1),
		"surface": Color(0.1, 0.1, 0.15, 1),
		"primary": Color(0.0, 0.8, 1.0, 1),
		"secondary": Color(1.0, 0.2, 0.8, 1),
		"accent": Color(0.2, 1.0, 0.4, 1),
		"players": [
			Color(0.0, 0.8, 1.0, 0.9),   # Cyan
			Color(1.0, 0.2, 0.8, 0.9),   # Magenta
			Color(0.2, 1.0, 0.4, 0.9),   # Lime
			Color(1.0, 0.6, 0.0, 0.9),   # Orange
			Color(0.8, 0.0, 1.0, 0.9),   # Purple
			Color(1.0, 1.0, 0.0, 0.9),   # Yellow
			Color(0.0, 1.0, 0.8, 0.9),   # Aqua
			Color(1.0, 0.4, 0.4, 0.9)    # Pink
		]
	}
]

## Get a specific theme by index
static func get_theme(index: int) -> Dictionary:
	if index < 0 or index >= themes.size():
		return themes[0]  # Default to first theme
	return themes[index]

## Get a theme by name
static func get_theme_by_name(name: String) -> Dictionary:
	for theme in themes:
		if theme.name == name:
			return theme
	return themes[0]  # Default to first theme

## Get the number of available themes
static func get_theme_count() -> int:
	return themes.size()

## Get all theme names
static func get_theme_names() -> Array[String]:
	var names: Array[String] = []
	for theme in themes:
		names.append(theme.name)
	return names

## Apply a theme to a specific node based on its type
static func apply_theme_to_node(node: Node, theme: Dictionary, node_type: String = "") -> void:
	if not node or theme.is_empty():
		return
	
	# Auto-detect node type if not specified
	if node_type.is_empty():
		if node is Hand:
			node_type = "hand"
		elif node is Train:
			node_type = "train"
		elif node is BoneYard:
			node_type = "boneyard"
		elif node is Station:
			node_type = "station"
		elif node.name.to_lower().contains("background"):
			node_type = "background"
	
	# Apply colors based on node type
	match node_type.to_lower():
		"background":
			if node.has_method("set") and node.has_property("color"):
				node.color = theme.background
		"boneyard":
			if node.has_property("bg_color"):
				node.bg_color = theme.primary.darkened(0.3)
		"station":
			if node.has_property("modulate"):
				node.modulate = theme.secondary
		"hand", "train":
			if node.has_property("bg_color") or node.has_property("color"):
				var color_property = "bg_color" if node.has_property("bg_color") else "color"
				node.set(color_property, theme.primary)

## Get a player color from a theme
static func get_player_color(theme: Dictionary, player_index: int) -> Color:
	if player_index < 0 or player_index >= theme.players.size():
		return theme.primary  # Fallback to primary color
	return theme.players[player_index]

## Create a harmonious color variation
static func create_color_variation(base_color: Color, variation_factor: float = 0.2) -> Color:
	var h := base_color.h
	var s := base_color.s
	var v := base_color.v
	var a := base_color.a
	
	# Vary hue slightly
	h += randf_range(-variation_factor, variation_factor)
	if h < 0.0:
		h += 1.0
	elif h > 1.0:
		h -= 1.0
	
	# Vary saturation and value slightly
	s = clamp(s + randf_range(-variation_factor * 0.5, variation_factor * 0.5), 0.0, 1.0)
	v = clamp(v + randf_range(-variation_factor * 0.3, variation_factor * 0.3), 0.0, 1.0)
	
	return Color.from_hsv(h, s, v, a)

## Log all available themes (for debugging)
static func print_available_themes() -> void:
	Logger.log_info(Logger.LogArea.UI, "=== Available Color Themes ===")
	for i in range(themes.size()):
		var theme = themes[i]
		Logger.log_info(Logger.LogArea.UI, "%d. %s - %s" % [i + 1, theme.name, theme.description])
	Logger.log_info(Logger.LogArea.UI, "=============================")

## Get a random theme
static func get_random_theme() -> Dictionary:
	return themes[randi() % themes.size()]
