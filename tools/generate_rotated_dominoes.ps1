#!/usr/bin/env powershell
# generate_rotated_dominoes.ps1
# Generates rotated versions of domino SVG files for orientation support

param(
    [string]$InkscapePath = "C:\Program Files\Inkscape\bin\inkscape.exe",
    [string]$DominoDir = "c:\development\mexican-train\assets\tiles\dominos"
)

# Verify Inkscape exists
if (-not (Test-Path $InkscapePath)) {
    Write-Error "Inkscape not found at: $InkscapePath"
    Write-Host "Please install Inkscape or update the path parameter"
    exit 1
}

# Verify domino directory exists
if (-not (Test-Path $DominoDir)) {
    Write-Error "Domino directory not found: $DominoDir"
    exit 1
}

Write-Host "Starting domino rotation generation..."
Write-Host "Inkscape Path: $InkscapePath"
Write-Host "Domino Directory: $DominoDir"

# Get all domino SVG files (excluding back and already rotated files)
$dominoFiles = Get-ChildItem -Path $DominoDir -Name "domino-*.svg" | Where-Object { 
    $_ -notmatch "domino-back" -and 
    $_ -notmatch "_top" -and 
    $_ -notmatch "_bottom" -and 
    $_ -notmatch "_left" -and 
    $_ -notmatch "_right"
}

Write-Host "Found $($dominoFiles.Count) domino files to process"

$processed = 0
$failed = 0

foreach ($file in $dominoFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $fullPath = Join-Path $DominoDir $file
    
    Write-Host "Processing: $file"
    
    # Define rotation operations
    $rotations = @(
        @{ suffix = "_left"; rotation = 0; description = "Left (0°)" },
        @{ suffix = "_right"; rotation = 180; description = "Right (180°)" },
        @{ suffix = "_top"; rotation = 90; description = "Top (90°)" },
        @{ suffix = "_bottom"; rotation = 270; description = "Bottom (270°)" }
    )
    
    foreach ($rot in $rotations) {
        $outputFile = Join-Path $DominoDir "${baseName}$($rot.suffix).svg"
        
        # Skip if file already exists
        if (Test-Path $outputFile) {
            Write-Host "  Skipping $($rot.description) - already exists"
            continue
        }
        
        try {
            # Use Inkscape to rotate and save
            $arguments = @(
                "--file=`"$fullPath`"",
                "--verb=SelectAll",
                "--verb=ObjectRotate90",  # This rotates 90° clockwise
                "--verb=FileSave",
                "--verb=FileQuit"
            )
            
            # For specific rotations, we need to rotate multiple times
            $rotateCount = $rot.rotation / 90
            $inkscapeArgs = @("--file=`"$fullPath`"")
            
            # Add select all
            $inkscapeArgs += "--verb=SelectAll"
            
            # Add rotation commands
            for ($i = 0; $i -lt $rotateCount; $i++) {
                $inkscapeArgs += "--verb=ObjectRotate90"
            }
            
            # Save to new file
            $inkscapeArgs += "--export-filename=`"$outputFile`""
            $inkscapeArgs += "--verb=FileQuit"
            
            # Execute Inkscape command
            $processInfo = Start-Process -FilePath $InkscapePath -ArgumentList $inkscapeArgs -Wait -PassThru -WindowStyle Hidden
            
            if ($processInfo.ExitCode -eq 0 -and (Test-Path $outputFile)) {
                Write-Host "  ✓ Created $($rot.description): $outputFile"
                $processed++
            } else {
                Write-Warning "  ✗ Failed to create $($rot.description)"
                $failed++
            }
        }
        catch {
            Write-Warning "  ✗ Error processing $($rot.description): $($_.Exception.Message)"
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Rotation generation complete!"
Write-Host "Successfully created: $processed files"
if ($failed -gt 0) {
    Write-Host "Failed to create: $failed files" -ForegroundColor Yellow
}

# Now generate .import files for Godot
Write-Host ""
Write-Host "Generating Godot .import files..."

$newSvgFiles = Get-ChildItem -Path $DominoDir -Name "*.svg" | Where-Object { 
    ($_ -match "_top" -or $_ -match "_bottom" -or $_ -match "_left" -or $_ -match "_right") -and
    -not (Test-Path (Join-Path $DominoDir "$_.import"))
}

foreach ($svgFile in $newSvgFiles) {
    $importFile = Join-Path $DominoDir "$svgFile.import"
    $importContent = @"
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://$(([guid]::NewGuid()).ToString().Replace('-','').Substring(0,16))"
path="res://.godot/imported/$svgFile-$(([guid]::NewGuid()).ToString().Replace('-','').Substring(0,16)).ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="res://assets/tiles/dominos/$svgFile"
dest_files=["res://.godot/imported/$svgFile-$(([guid]::NewGuid()).ToString().Replace('-','').Substring(0,16)).ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
svg/scale=1.0
editor/scale_with_editor_scale=false
editor/convert_colors_with_editor_theme=false
"@
    
    try {
        Set-Content -Path $importFile -Value $importContent -Encoding UTF8
        Write-Host "  ✓ Created import file: $svgFile.import"
    }
    catch {
        Write-Warning "  ✗ Failed to create import file for: $svgFile"
    }
}

Write-Host ""
Write-Host "All operations complete!"
Write-Host "Note: You may need to refresh the Godot FileSystem dock to see the new files."
