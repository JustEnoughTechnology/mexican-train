# Test script to generate a few BaseDomino scenes
$baseDir = "c:\development\mexican-train\scenes\dominos\base_dominos"
$uidCounter = 1000

Write-Host "Starting generation..."

# Test with just 0-0 domino in all 4 orientations
$largest = 0
$smallest = 0

$orientations = @(
    @{ name = "horizontal_left"; vector = "Vector2i(0, 0)"; container = "HBoxContainer"; size = "Vector2(81, 40)"; sep_size = "Vector2(1, 40)" },
    @{ name = "horizontal_right"; vector = "Vector2i(0, 1)"; container = "HBoxContainer"; size = "Vector2(81, 40)"; sep_size = "Vector2(1, 40)" },
    @{ name = "vertical_top"; vector = "Vector2i(1, 0)"; container = "VBoxContainer"; size = "Vector2(40, 81)"; sep_size = "Vector2(40, 1)" },
    @{ name = "vertical_bottom"; vector = "Vector2i(1, 1)"; container = "VBoxContainer"; size = "Vector2(40, 81)"; sep_size = "Vector2(40, 1)" }
)

foreach ($orientation in $orientations) {
    $fileName = "base_domino_${largest}_${smallest}_$($orientation.name).tscn"
    $filePath = Join-Path $baseDir $fileName
    
    Write-Host "Creating: $fileName"
    
    $uid = "uid://bd{0:D6}" -f $uidCounter
    $uidCounter++
    
    # For 0-0, both textures are the same
    $firstTexture = 0
    $secondTexture = 0
    
    $sceneContent = @"
[gd_scene load_steps=3 format=3 uid="$uid"]

[ext_resource type="Script" path="res://scripts/dominos/base_domino.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/dominos/half/half-$firstTexture.svg" id="2"]

[node name="BaseDomino" type="Control"]
layout_mode = 3
anchors_preset = 0
custom_minimum_size = $($orientation.size)
script = ExtResource("1")
largest_value = $largest
smallest_value = $smallest
orientation = $($orientation.vector)

[node name="DominoVisual" type="$($orientation.container)" parent="."]
layout_mode = 2
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0

[node name="LargestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("2")
expand_mode = 1
stretch_mode = 5

[node name="Separator" type="ColorRect" parent="DominoVisual"]
custom_minimum_size = $($orientation.sep_size)
layout_mode = 2
color = Color(0, 0, 0, 1)

[node name="SmallestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("2")
expand_mode = 1
stretch_mode = 5
"@
    
    [System.IO.File]::WriteAllText($filePath, $sceneContent, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $fileName"
}

Write-Host "Test generation complete!"
