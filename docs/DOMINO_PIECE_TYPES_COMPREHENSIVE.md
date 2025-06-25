# Comprehensive Domino Piece Types for Mexican Train

**Date**: June 23, 2025  
**Project**: Mexican Train Dominoes  
**Scope**: Complete analysis of domino piece types for game implementation

## Executive Summary

This document provides a comprehensive breakdown of all domino piece types required for the Mexican Train dominoes game, analyzing both the standard double-6 set and the extended double-12 set currently being implemented.

---

## 1. Standard Double-6 Set (28 Pieces)

The traditional domino set contains **28 unique pieces** ranging from 0-0 to 6-6.

### 1.1 Mathematical Formula
```
For each number n from 0 to 6:
Total pieces = (n + 1) + (n + 2) + ... + (6 + 1)
            = Σ(i=1 to 7) i = 7 × 8 / 2 = 28 pieces
```

### 1.2 Complete Piece List
```
Doubles (7 pieces):
0-0, 1-1, 2-2, 3-3, 4-4, 5-5, 6-6

Mixed Combinations (21 pieces):
0-series (6): 0-1, 0-2, 0-3, 0-4, 0-5, 0-6
1-series (5): 1-2, 1-3, 1-4, 1-5, 1-6
2-series (4): 2-3, 2-4, 2-5, 2-6
3-series (3): 3-4, 3-5, 3-6
4-series (2): 4-5, 4-6
5-series (1): 5-6
```

### 1.3 Usage in Current Project
- **Test Scenes**: Several test files generate double-6 sets
- **Current Status**: Fully implemented and working
- **Files Using**: `test_complete_mexican_train.gd`, `test_train_station_drag_drop.gd`

---

## 2. Double-12 Set (91 Pieces) - Current Target

The extended double-12 set contains **91 unique pieces** ranging from 0-0 to 12-12.

### 2.1 Mathematical Formula
```
For each number n from 0 to 12:
Total pieces = (n + 1) + (n + 2) + ... + (12 + 1)
            = Σ(i=1 to 13) i = 13 × 14 / 2 = 91 pieces
```

### 2.2 Complete Piece Breakdown

#### Doubles (13 pieces):
```
0-0, 1-1, 2-2, 3-3, 4-4, 5-5, 6-6, 7-7, 8-8, 9-9, 10-10, 11-11, 12-12
```

#### Mixed Combinations (78 pieces):
```
0-series (12): 0-1, 0-2, 0-3, 0-4, 0-5, 0-6, 0-7, 0-8, 0-9, 0-10, 0-11, 0-12
1-series (11): 1-2, 1-3, 1-4, 1-5, 1-6, 1-7, 1-8, 1-9, 1-10, 1-11, 1-12
2-series (10): 2-3, 2-4, 2-5, 2-6, 2-7, 2-8, 2-9, 2-10, 2-11, 2-12
3-series (9):  3-4, 3-5, 3-6, 3-7, 3-8, 3-9, 3-10, 3-11, 3-12
4-series (8):  4-5, 4-6, 4-7, 4-8, 4-9, 4-10, 4-11, 4-12
5-series (7):  5-6, 5-7, 5-8, 5-9, 5-10, 5-11, 5-12
6-series (6):  6-7, 6-8, 6-9, 6-10, 6-11, 6-12
7-series (5):  7-8, 7-9, 7-10, 7-11, 7-12
8-series (4):  8-9, 8-10, 8-11, 8-12
9-series (3):  9-10, 9-11, 9-12
10-series (2): 10-11, 10-12
11-series (1): 11-12
```

### 2.3 Current Implementation Status
- **Scene Files**: 13 double domino scenes implemented (0-0 through 12-12)
- **Color System**: High-contrast color scheme applied to all doubles
- **Size**: Standard game size Vector2(40, 82) for vertical orientation
- **Missing**: Mixed combination scenes (0-1, 0-2, etc.)

---

## 3. Piece Type Categories

### 3.1 By Dot Count Total
```
0 dots total:  0-0 (1 piece)
1 dot total:   0-1 (1 piece)
2 dots total:  0-2, 1-1 (2 pieces)
3 dots total:  0-3, 1-2 (2 pieces)
4 dots total:  0-4, 1-3, 2-2 (3 pieces)
5 dots total:  0-5, 1-4, 2-3 (3 pieces)
6 dots total:  0-6, 1-5, 2-4, 3-3 (4 pieces)
...
24 dots total: 12-12 (1 piece)
```

### 3.2 By Symmetry
```
Doubles (13):    Same dots on both sides
Non-doubles (78): Different dots on each side
```

### 3.3 By Engine Potential
```
Engine Dominoes (13): All doubles can serve as engines
Starting Pieces (78): Must match existing engine value
```

---

## 4. Generation Patterns

### 4.1 Code Pattern for Double-6
```gdscript
func generate_double_six_set() -> Array[Vector2i]:
    var dominoes: Array[Vector2i] = []
    for smaller in range(0, 7):
        for larger in range(smaller, 7):
            dominoes.append(Vector2i(larger, smaller))
    return dominoes
```

### 4.2 Code Pattern for Double-12
```gdscript
func generate_double_twelve_set() -> Array[Vector2i]:
    var dominoes: Array[Vector2i] = []
    for smaller in range(0, 13):
        for larger in range(smaller, 13):
            dominoes.append(Vector2i(larger, smaller))
    return dominoes
```

### 4.3 Validation Function
```gdscript
func validate_domino_set(max_dots: int) -> bool:
    var expected_count = (max_dots + 1) * (max_dots + 2) / 2
    var actual_count = generate_domino_set(max_dots).size()
    return actual_count == expected_count
```

---

## 5. Special Categories for Mexican Train

### 5.1 Engine Dominoes (Doubles)
These pieces can start a round:
```
0-0: Blank engine       7-7: Seven engine
1-1: One engine         8-8: Eight engine
2-2: Two engine         9-9: Nine engine
3-3: Three engine       10-10: Ten engine
4-4: Four engine        11-11: Eleven engine
5-5: Five engine        12-12: Twelve engine
6-6: Six engine (traditional starting engine)
```

### 5.2 High-Value Pieces
Pieces with 20+ total dots:
```
10-10 (20 dots)    11-10 (21 dots)    12-10 (22 dots)
11-11 (22 dots)    12-11 (23 dots)
                   12-12 (24 dots)
```

### 5.3 Frequently Used Pieces
Based on connection potential:
```
High connectivity: 6-6, 6-x pieces (traditional center values)
Medium connectivity: 0-x, 12-x pieces (endpoints)
Low connectivity: Middle-range non-doubles
```

---

## 6. Current Project Assets

### 6.1 Available Scene Files
```
✅ Complete: Double dominoes (0-0 through 12-12) - 13 files
❌ Missing: Mixed combinations (0-1, 0-2, etc.) - 78 files
🔧 In Progress: New half-based system (half-0.svg through half-12.svg)
```

### 6.2 Asset Locations
```
scenes/experimental/dominoes/: Current double domino scenes
assets/tiles/dominos/: SVG files for all pieces
assets/experimental/dominos_white/: Alternative white background versions
assets/new-dominos/: New half-based system (40x40 pixel squares)
assets/backup-dominos/: Backup of oversized domino files
```

### 6.3 Implementation Status
```
✅ Color System: High-contrast professional colors applied
✅ Size Standards: Vector2(40, 82) for game pieces
✅ Shader System: Supports white background to color conversion
🔧 Half System: 13 individual 40x40 halves created
❌ Complete Set: Only 13 of 91 pieces fully implemented
```

---

## 7. Recommendations

### 7.1 Immediate Actions
1. **Fix SVG Import Issues**: Resolve XML formatting in new half files
2. **Complete Half System**: Create combination logic for full dominoes
3. **Generate Missing Scenes**: Create remaining 78 mixed combination scenes

### 7.2 Long-term Strategy
1. **Standardize on Half System**: Use 40x40 halves for all pieces
2. **Implement Dynamic Generation**: Create pieces from half combinations
3. **Optimize Performance**: Use shader-based recoloring system

### 7.3 Quality Assurance
1. **Validate Counts**: Ensure exactly 91 unique pieces
2. **Test All Combinations**: Verify each piece works in game
3. **Performance Testing**: Confirm system handles full set efficiently

---

## 8. File Generation Requirements

### 8.1 For Complete Implementation
```
Total Files Needed:
- 91 scene files (.tscn)
- 91 SVG assets (or 13 half assets with combination logic)
- Color definitions for all 91 pieces
- Test coverage for all piece types
```

### 8.2 Naming Convention
```
Scene Files: domino-{larger}-{smaller}_top.tscn
SVG Files: domino-{larger}-{smaller}.svg
Example: domino-12-7_top.tscn, domino-12-7.svg
```

---

## 9. Testing Checklist

### 9.1 Piece Validation
- [ ] All 91 pieces generate correctly
- [ ] No duplicate combinations
- [ ] Proper dot counts for each piece
- [ ] Correct orientation behavior

### 9.2 Game Integration
- [ ] All pieces work as engine dominoes (doubles only)
- [ ] Proper connection validation
- [ ] Visual consistency across all pieces
- [ ] Performance acceptable with full set

---

## 10. Summary

The Mexican Train game requires a comprehensive set of 91 unique domino pieces ranging from 0-0 to 12-12. Currently, only the 13 double pieces are fully implemented, leaving 78 mixed combinations to be created. The new half-based system shows promise for efficient implementation, but requires resolution of SVG import issues and completion of the combination logic.

**Priority**: Complete the remaining 78 piece types to enable full double-12 Mexican Train gameplay.
