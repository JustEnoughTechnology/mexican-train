## Performance Test Instructions

The performance test script has been successfully created! Here's how to run it:

### 🎯 **STEP 1: Open Performance Test Scene**
1. In Godot, open the scene: `scenes/experimental/performance_test.tscn`
2. You should see a UI with:
   - A "Start Performance Test" button
   - A progress bar
   - Status label 
   - Results display area

### 🚀 **STEP 2: Run the Test**
1. Click the "Play Scene" button (F6) in Godot
2. OR run the scene directly from the Scene tab
3. Click "Start Performance Test" button in the UI
4. Wait for the test to complete (this will take a few minutes)

### 📊 **STEP 3: View Results**
The test will automatically display:
- **Loading Times**: Average and median for both approaches
- **Performance Improvement**: Percentage comparison
- **Test Configuration**: Number of iterations and configurations tested
- **Conclusion**: Recommendation based on results

### 🔍 **What the Test Measures**

**Original Approach:**
- Loads `res://scenes/domino/domino.tscn`
- Calls `set_dots(left, right)` - triggers runtime SVG loading
- Calls `set_orientation()` - applies orientation changes
- Measures total time for instantiation + configuration

**New Approach:**
- Loads pre-generated scene files like `domino-6-3_top.tscn`
- Scene has embedded shader materials with pre-configured colors
- Measures time for instantiation only (no runtime processing)

### 📈 **Expected Results**
The new approach should be significantly faster because:
- ✅ No runtime SVG file loading
- ✅ No runtime color calculations  
- ✅ Pre-compiled shader materials
- ✅ Immediate rendering without processing delays

### 🎮 **Alternative: Console Output**
Results are also printed to Godot's console for easier copying/analysis.

---

**Ready to test!** Open the scene and click the button to see how much faster the shader-based approach is! 🏃‍♂️💨
