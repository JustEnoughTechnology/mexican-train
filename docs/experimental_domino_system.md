# Experimental Shader-Based Domino System

## Overview

This experimental system creates an alternative approach to domino rendering that:

1. **Pre-loads SVG assets** instead of loading them at runtime
2. **Uses shaders** to dynamically color dots based on dot count
3. **Maintains separation** from the existing game system
4. **Provides performance testing** opportunities

## What Was Created

### Assets Generated

- **768 White-dot SVG files** in `assets/experimental/dominos_white/`
  - Converted from existing SVG files
  - Black dots changed to white (`#ffffff`)
  - Maintains all orientations and combinations (0-18 dots)
  - File naming: `white_domino-{left}-{right}_{orientation}.svg`

### Shader System

- **Domino Dot Color Shader** (`shaders/domino_dot_color.gdshader`)
  - Takes white-dot SVGs as input
  - Colors dots based on uniforms: `left_dots`, `right_dots`, `is_vertical`
  - Uses 18-color palette from `domino_dot_colors.txt`
  - Preserves background and divider line colors

### Scripts and Scenes

- **ExperimentalDomino Script** (`scripts/experimental/experimental_domino.gd`)
  - TextureRect-based domino that uses shader coloring
  - Methods: `configure_domino()`, `set_left_dots()`, `set_right_dots()`
  - Automatically loads appropriate white-dot SVG
  - Updates shader parameters in real-time

- **Experimental Domino Scene** (`scenes/experimental/experimental_domino.tscn`)
  - Pre-configured with shader material
  - Ready to use in other scenes

- **Test Scenes**
  - `scenes/experimental/experimental_domino_test.tscn` - Full test suite
  - `scenes/experimental/simple_experimental_test.tscn` - Basic validation

## Color Mapping (18 Colors)

Based on `docs/domino_dot_colors.txt`:

```
0:  White (no dots)
1:  Light Blue
2:  Green  
3:  Pink
4:  Gray (yellow tinted)
5:  Dark Blue
6:  Yellow
7:  Lavender
8:  Dark Green
9:  Royal Purple
10: Orange
11: Black
12: Gray (normal)
13: Cadet Blue
14: Dark Gray (yellow-tinted)
15: Classic Purple
16: Oxford Blue
17: Jade Green
18: Red
```

## Testing the System

### Quick Test

1. Open Godot project
2. Navigate to `scenes/experimental/simple_experimental_test.tscn`
3. Run the scene
4. Check console output for validation results

### Full Test Suite

1. Open `scenes/experimental/experimental_domino_test.tscn`
2. Run the scene to see multiple domino combinations
3. Use "Refresh Test" button to reload dominoes
4. Verify colors match the expected palette

### Manual Testing

```gdscript
# Create experimental domino in your own scene
var domino = preload("res://scenes/experimental/experimental_domino.tscn").instantiate()
domino.configure_domino(3, 6, "top")  # Pink dots (3) and Yellow dots (6)
add_child(domino)
```

## Advantages of This Approach

1. **Performance**: Pre-loaded textures vs runtime SVG loading
2. **Memory**: Single shader material vs multiple texture resources
3. **Flexibility**: Easy color changes via shader parameters
4. **Separation**: No impact on existing game systems
5. **Scalability**: Easy to add new color schemes or effects

## Integration Path

If this experimental approach proves superior:

1. **Performance comparison** with existing system
2. **Visual quality assessment** 
3. **Code integration** into main domino system
4. **Gradual migration** of existing functionality
5. **Fallback mechanisms** for compatibility

## Files Created

```
assets/experimental/
├── dominos_white/           # 768 white-dot SVG files
│   ├── white_domino-0-0_top.svg
│   ├── white_domino-1-1_top.svg
│   └── ... (all combinations)
└── materials/
    └── domino_shader_base.tres  # Base shader material

scenes/experimental/
├── experimental_domino.tscn      # Main experimental domino scene
├── experimental_domino_test.tscn # Full test suite
└── simple_experimental_test.tscn # Basic validation

scripts/experimental/
├── experimental_domino.gd        # Main experimental domino class
└── experimental_domino_test.gd   # Test suite controller

shaders/
└── domino_dot_color.gdshader     # Dot coloring shader (already existed)
```

## Next Steps

1. **Test the experimental system** in Godot
2. **Compare performance** with existing system
3. **Evaluate visual quality** of shader-colored dots
4. **Consider integration** if results are positive
5. **Document any issues** or improvements needed

---

*This experimental system is completely separate from the main game and can be safely tested without affecting existing functionality.*
