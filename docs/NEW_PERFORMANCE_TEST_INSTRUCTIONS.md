# New Performance Test Instructions

## 🚀 Quick Start

**Option 1: PowerShell Launcher**
```powershell
.\run_new_performance_test.ps1
```

**Option 2: Manual Godot**
1. Open Godot
2. Load scene: `scenes/experimental/new_performance_test.tscn`
3. Press F6 or click "Play Scene"
4. Click "Start Test" button

## 🎯 What This Test Does

**Simple & Reliable Approach:**
- Tests only 10 iterations (fast execution)
- Uses 2 domino configurations (6-3 top/bottom)
- Measures actual loading/instantiation time
- Clear progress feedback
- Stop button to cancel if needed

**Measurements:**
- **Original**: Load `domino.tscn` → `set_dots()` → `set_orientation()` 
- **New**: Load pre-generated `domino-6-3_top.tscn` directly
- **Timing**: High-precision microsecond timing
- **Results**: Average times + performance improvement percentage

## 📊 Expected Results

The new approach should be faster because:
- ✅ No runtime SVG processing
- ✅ Pre-configured shader materials  
- ✅ No orientation calculations
- ✅ Direct scene instantiation

## 🔧 Features

- **Real-time progress** with progress bar
- **Stop button** to cancel test anytime
- **Console logging** for detailed timing info
- **Clear results display** with conclusions
- **Error handling** for missing scene files

## 🐛 Debug Info

All timing information is printed to Godot's console:
```
Original test 1/40: 15.23 ms
Original test 2/40: 12.45 ms
New test 21/40: 3.21 ms
New test 22/40: 2.87 ms
```

---

**This is a completely fresh implementation - no legacy code issues!** 🎉
