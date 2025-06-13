# PowerShell script to batch rename all test files to follow *_test naming convention
# This script renames both .tscn scene files and their corresponding .gd script files

Write-Host "Starting batch rename of test files..." -ForegroundColor Green

# Define the base paths
$scenesPath = "c:\development\mexican-train\scenes\test"
$scriptsPath = "c:\development\mexican-train\scripts\test"

# Define the renaming mappings (old_name -> new_name)
$sceneRenames = @{
    "test_8_player_layout_clean.tscn" = "player_layout_8_clean_test.tscn"
    "test_8_player_mexican_train.tscn" = "mexican_train_8_player_test.tscn"
    "test_boneyard_basic.tscn" = "boneyard_basic_test.tscn"
    "test_boneyard_hand_drag_drop-debugging.tscn" = "boneyard_hand_drag_drop_debugging_test.tscn"
    "test_boneyard_hand_drag_drop.tscn" = "boneyard_hand_drag_drop_test.tscn"
    "test_bone_yard.tscn" = "bone_yard_test.tscn"
    "test_comparison.tscn" = "comparison_test.tscn"
    "test_complete_mexican_train.tscn" = "mexican_train_complete_test.tscn"
    "test_domino_basic.tscn" = "domino_basic_test.tscn"
    "test_domino_game_container.tscn" = "domino_game_container_test.tscn"
    "test_domino_orientation.tscn" = "domino_orientation_test.tscn"
    "test_double_dominoes.tscn" = "dominoes_double_test.tscn"
    "test_hand_drag_drop.tscn" = "hand_drag_drop_test.tscn"
    "test_multiplayer_mexican_train.tscn" = "mexican_train_multiplayer_test.tscn"
    "test_player_hand.tscn" = "player_hand_test.tscn"
    "test_player_naming.tscn" = "player_naming_test.tscn"
    "test_server_admin_dashboard.tscn" = "server_admin_dashboard_test.tscn"
    "test_server_mechanics.tscn" = "server_mechanics_test.tscn"
    "test_server_system.tscn" = "server_system_test.tscn"
    "test_station_drag_fix.tscn" = "station_drag_fix_test.tscn"
    "test_station_only.tscn" = "station_only_test.tscn"
    "test_train.tscn" = "train_test.tscn"
    "test_train_drag_drop.tscn" = "train_drag_drop_test.tscn"
    "test_train_orientation.tscn" = "train_orientation_test.tscn"
    "test_train_simple.tscn" = "train_simple_test.tscn"
    "test_train_station_drag_drop.tscn" = "train_station_drag_drop_test.tscn"
    "test_unique_player_names.tscn" = "player_names_unique_test.tscn"
}

$scriptRenames = @{
    "test_8_player_layout_clean.gd" = "player_layout_8_clean_test.gd"
    "test_8_player_mexican_train.gd" = "mexican_train_8_player_test.gd"
    "test_boneyard_basic.gd" = "boneyard_basic_test.gd"
    "test_boneyard_hand_drag_drop.gd" = "boneyard_hand_drag_drop_test.gd"
    "test_bone_yard.gd" = "bone_yard_test.gd"
    "test_comparison.gd" = "comparison_test.gd"
    "test_complete_mexican_train.gd" = "mexican_train_complete_test.gd"
    "test_domino.gd" = "domino_test.gd"
    "test_domino_basic.gd" = "domino_basic_test.gd"
    "test_domino_orientation.gd" = "domino_orientation_test.gd"
    "test_double_dominoes.gd" = "dominoes_double_test.gd"
    "test_hand_drag_drop.gd" = "hand_drag_drop_test.gd"
    "test_multiplayer_mexican_train.gd" = "mexican_train_multiplayer_test.gd"
    "test_orientation_debug.gd" = "orientation_debug_test.gd"
    "test_orientation_fix.gd" = "orientation_fix_test.gd"
    "test_player_hand.gd" = "player_hand_test.gd"
    "test_player_naming.gd" = "player_naming_test.gd"
    "test_player_object_names.gd" = "player_object_names_test.gd"
    "test_server_admin_dashboard.gd" = "server_admin_dashboard_test.gd"
    "test_server_mechanics.gd" = "server_mechanics_test.gd"
    "test_server_system.gd" = "server_system_test.gd"
    "test_station_drag_fix.gd" = "station_drag_fix_test.gd"
    "test_station_only.gd" = "station_only_test.gd"
    "test_texture_debug.gd" = "texture_debug_test.gd"
    "test_train.gd" = "train_test.gd"
    "test_train_drag_drop.gd" = "train_drag_drop_test.gd"
    "test_train_orientation.gd" = "train_orientation_test.gd"
    "test_train_station_drag_drop.gd" = "train_station_drag_drop_test.gd"
    "test_train_station_drag_drop_simple.gd" = "train_station_drag_drop_simple_test.gd"
}

# Function to rename files with .uid files
function Rename-FileWithUID {
    param (
        [string]$SourcePath,
        [string]$OldName,
        [string]$NewName
    )
    
    $oldFile = Join-Path $SourcePath $OldName
    $newFile = Join-Path $SourcePath $NewName
    $oldUID = $oldFile + ".uid"
    $newUID = $newFile + ".uid"
    
    if (Test-Path $oldFile) {
        Write-Host "  Renaming: $OldName -> $NewName" -ForegroundColor Yellow
        Move-Item $oldFile $newFile -Force
        
        # Also rename .uid file if it exists
        if (Test-Path $oldUID) {
            Move-Item $oldUID $newUID -Force
            Write-Host "  Renamed UID: $OldName.uid -> $NewName.uid" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  File not found: $OldName" -ForegroundColor Red
    }
}

# Rename scene files
Write-Host "`nRenaming scene files (.tscn)..." -ForegroundColor Blue
foreach ($rename in $sceneRenames.GetEnumerator()) {
    Rename-FileWithUID -SourcePath $scenesPath -OldName $rename.Key -NewName $rename.Value
}

# Rename script files
Write-Host "`nRenaming script files (.gd)..." -ForegroundColor Blue
foreach ($rename in $scriptRenames.GetEnumerator()) {
    Rename-FileWithUID -SourcePath $scriptsPath -OldName $rename.Key -NewName $rename.Value
}

# Clean up temporary files
Write-Host "`nCleaning up temporary files..." -ForegroundColor Blue
Get-ChildItem -Path $scenesPath -Filter "*.tmp" | Remove-Item -Force
Write-Host "  Removed .tmp files from scenes/test/"

Write-Host "`nBatch rename completed!" -ForegroundColor Green
Write-Host "Next step: Update script references in renamed scene files..." -ForegroundColor Yellow
