# PowerShell script to update script references in renamed scene files
# This updates the res:// paths to point to the newly renamed script files

Write-Host "Updating script references in renamed scene files..." -ForegroundColor Green

$scenesPath = "c:\development\mexican-train\scenes\test"

# Define script path mappings (old_script_path -> new_script_path)
$scriptPathUpdates = @{
    "res://scripts/test/test_boneyard_hand_drag_drop.gd" = "res://scripts/test/boneyard_hand_drag_drop_test.gd"
    "res://scripts/test/test_multiplayer_mexican_train.gd" = "res://scripts/test/mexican_train_multiplayer_test.gd"
    "res://scripts/test/test_train_orientation.gd" = "res://scripts/test/train_orientation_test.gd"
    "res://scripts/test/test_complete_mexican_train.gd" = "res://scripts/test/mexican_train_complete_test.gd"
    "res://scripts/test/test_player_hand.gd" = "res://scripts/test/player_hand_test.gd"
    "res://scripts/test/test_train_simple.gd" = "res://scripts/test/train_simple_test.gd"
    "res://scripts/test/test_comparison.gd" = "res://scripts/test/comparison_test.gd"
    "res://scripts/test/test_station_only.gd" = "res://scripts/test/station_only_test.gd"
    "res://scripts/test/test_train_drag_drop.gd" = "res://scripts/test/train_drag_drop_test.gd"
    "res://scripts/test/test_domino_basic.gd" = "res://scripts/test/domino_basic_test.gd"
    "res://scripts/test/test_domino_orientation.gd" = "res://scripts/test/domino_orientation_test.gd"
    "res://scripts/test/test_double_dominoes.gd" = "res://scripts/test/dominoes_double_test.gd"
    "res://scripts/test/test_player_naming.gd" = "res://scripts/test/player_naming_test.gd"
    "res://scripts/test/test_boneyard_basic.gd" = "res://scripts/test/boneyard_basic_test.gd"
    "res://scripts/test/test_station_drag_fix.gd" = "res://scripts/test/station_drag_fix_test.gd"
    "res://scripts/test/test_server_admin_dashboard.gd" = "res://scripts/test/server_admin_dashboard_test.gd"
    "res://scripts/test/test_server_mechanics.gd" = "res://scripts/test/server_mechanics_test.gd"
    "res://scripts/test/test_train_station_drag_drop.gd" = "res://scripts/test/train_station_drag_drop_test.gd"
    "res://scripts/test/test_bone_yard.gd" = "res://scripts/test/bone_yard_test.gd"
    "res://scripts/test/test_hand_drag_drop.gd" = "res://scripts/test/hand_drag_drop_test.gd"
    "res://scripts/test/test_train.gd" = "res://scripts/test/train_test.gd"
    "res://scripts/test/test_server_system.gd" = "res://scripts/test/server_system_test.gd"
    "res://scripts/test/test_8_player_layout_clean.gd" = "res://scripts/test/player_layout_8_clean_test.gd"
    "res://scripts/test/test_8_player_mexican_train.gd" = "res://scripts/test/mexican_train_8_player_test.gd"
    "res://scripts/test/test_unique_player_names.gd" = "res://scripts/test/player_names_unique_test.gd"
}

# Get all .tscn files in the test directory
$sceneFiles = Get-ChildItem -Path $scenesPath -Filter "*.tscn" | Where-Object { $_.Name -like "*_test.tscn" }

foreach ($sceneFile in $sceneFiles) {
    Write-Host "Checking: $($sceneFile.Name)" -ForegroundColor Yellow
    
    $content = Get-Content $sceneFile.FullName -Raw
    $originalContent = $content
    
    # Update each script path mapping
    foreach ($pathUpdate in $scriptPathUpdates.GetEnumerator()) {
        if ($content -like "*$($pathUpdate.Key)*") {
            $content = $content -replace [regex]::Escape($pathUpdate.Key), $pathUpdate.Value
            Write-Host "  Updated path: $($pathUpdate.Key) -> $($pathUpdate.Value)" -ForegroundColor Cyan
        }
    }
    
    # Write back if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $sceneFile.FullName -Value $content -NoNewline
        Write-Host "  File updated: $($sceneFile.Name)" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Gray
    }
}

Write-Host "`nScript reference updates completed!" -ForegroundColor Green
