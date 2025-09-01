# AI Strategy Configuration System

The Mexican Train game now supports fully configurable AI strategies using a JSON-based configuration system. You can create custom AI personalities, modify existing ones, and even remap difficulty levels.

## Quick Start

### Viewing Current Configuration

```bash
# List all strategies
curl http://localhost:8000/api/ai/strategies

# List all tactics
curl http://localhost:8000/api/ai/tactics

# View level mappings
curl http://localhost:8000/api/ai/levels
```

### Creating a Custom Strategy

```bash
curl -X POST http://localhost:8000/api/ai/strategies \
  -H "Content-Type: application/json" \
  -d '{
    "strategy_name": "my_custom_ai",
    "strategy": {
      "name": "Custom Aggressive AI",
      "description": "Focuses on blocking opponents while dumping high-value dominoes",
      "tactics": [
        {"name": "block_opponents", "weight": 2.5, "priority": 1},
        {"name": "maximize_pips", "weight": 2.0, "priority": 2},
        {"name": "dump_doubles", "weight": 1.5, "priority": 3}
      ]
    }
  }'
```

### Remapping AI Levels

```bash
# Make level 3 use your custom strategy instead of the default
curl -X PUT http://localhost:8000/api/ai/levels/3 \
  -H "Content-Type: application/json" \
  -d '{"level": 3, "strategy_name": "my_custom_ai"}'
```

## Configuration File Structure

The AI configuration is stored in `backend/app/ai_strategies.json`:

```json
{
  "tactics": {
    "tactic_name": {
      "description": "What this tactic does",
      "weight": 1.0
    }
  },
  "strategies": {
    "strategy_name": {
      "name": "Display Name",
      "description": "Strategy description", 
      "tactics": [
        {"name": "tactic_name", "weight": 2.0, "priority": 1}
      ]
    }
  },
  "level_mappings": {
    "1": "strategy_name"
  }
}
```

## Available Tactics

| Tactic | Description | Best For |
|--------|-------------|----------|
| `random` | Choose moves randomly | Beginner AI, unpredictability |
| `maximize_pips` | Play high-value dominoes first | Reducing end-game penalties |
| `minimize_pips` | Play low-value dominoes first | Keeping high cards for blocking |
| `prefer_own_train` | Prefer playing on own train | Keeping train closed |
| `prefer_mexican_train` | Prefer the Mexican train | Safe, neutral play |
| `prefer_open_trains` | Target opponent's open trains | Aggressive play |
| `block_opponents` | Play uncommon numbers | Defensive/competitive play |
| `preserve_doubles` | Avoid playing doubles | Risk management |
| `dump_doubles` | Play doubles when possible | Avoiding getting stuck |
| `endgame_awareness` | Adjust for few remaining dominoes | End-game optimization |
| `hand_composition` | Consider whole hand makeup | Advanced strategy |

## Strategy Examples

### 1. Ultra-Aggressive Blocker
```json
{
  "name": "Ruthless Blocker",
  "description": "Maximizes opponent disruption",
  "tactics": [
    {"name": "block_opponents", "weight": 3.0, "priority": 1},
    {"name": "prefer_open_trains", "weight": 2.5, "priority": 2},
    {"name": "dump_doubles", "weight": 2.0, "priority": 3}
  ]
}
```

### 2. Risk-Averse Conservative
```json
{
  "name": "Careful Player", 
  "description": "Focuses on self-protection and penalty minimization",
  "tactics": [
    {"name": "prefer_own_train", "weight": 3.0, "priority": 1},
    {"name": "maximize_pips", "weight": 2.0, "priority": 2},
    {"name": "preserve_doubles", "weight": 1.8, "priority": 3},
    {"name": "endgame_awareness", "weight": 1.5, "priority": 4}
  ]
}
```

### 3. Balanced All-Rounder
```json
{
  "name": "Versatile Player",
  "description": "Well-rounded strategy with situational awareness",
  "tactics": [
    {"name": "endgame_awareness", "weight": 2.5, "priority": 1},
    {"name": "hand_composition", "weight": 2.0, "priority": 2},
    {"name": "prefer_own_train", "weight": 1.8, "priority": 3},
    {"name": "maximize_pips", "weight": 1.5, "priority": 4},
    {"name": "block_opponents", "weight": 1.0, "priority": 5}
  ]
}
```

## Strategy Design Tips

### Weight Values
- **0.5-1.0**: Weak influence
- **1.0-2.0**: Moderate influence  
- **2.0-3.0**: Strong influence
- **3.0+**: Dominant behavior

### Priority Order
Lower priority numbers get applied first. Early tactics set the baseline, later tactics fine-tune.

### Tactic Combinations

**Good Combinations:**
- `maximize_pips` + `endgame_awareness` = Smart penalty management
- `block_opponents` + `prefer_open_trains` = Aggressive harassment
- `prefer_own_train` + `preserve_doubles` = Conservative safety

**Conflicting Combinations:**
- `maximize_pips` + `minimize_pips` = Counterproductive
- `preserve_doubles` + `dump_doubles` = Contradictory

## API Endpoints

### GET `/api/ai/strategies`
List all available strategies with their configurations.

### GET `/api/ai/tactics`  
List all available tactics with descriptions.

### GET `/api/ai/levels`
Show current level-to-strategy mappings.

### POST `/api/ai/strategies`
Create a new custom strategy.

### PUT `/api/ai/levels/{level}`
Map a level to a different strategy.

### DELETE `/api/ai/strategies/{strategy_name}`
Delete a custom strategy (if not in use).

### POST `/api/ai/save`
Save current configuration to file.

### POST `/api/ai/reload`
Reload configuration from file.

### GET `/api/ai/strategy/{strategy_name}`
Get detailed information about a specific strategy.

## Testing Your Strategies

1. **Create a test match** with AI players at different levels
2. **Observe AI reasoning** in game logs (shows which tactics influenced decisions)
3. **Adjust weights/priorities** based on observed behavior
4. **Save successful configurations** using the save endpoint

## Advanced Usage

### Dynamic Strategy Switching
You can change AI strategies mid-development by:
1. Modifying the JSON file
2. Calling `/api/ai/reload`
3. New games will use the updated strategies

### A/B Testing Strategies
1. Create multiple strategy variants
2. Map them to different AI levels
3. Create matches with varied AI compositions
4. Compare performance over multiple games

### Debugging AI Decisions
Enable debug logging to see detailed AI reasoning:
- Each move shows which tactics influenced the decision
- Weights and scores are displayed
- Helps identify if strategies work as intended

## Default Strategies

The system includes 5 built-in strategies:

1. **Sleepy Caboose** (Level 1): Pure random
2. **Slow Freight** (Level 2): Penalty minimization
3. **Local Express** (Level 3): Basic hand management
4. **Fast Passenger** (Level 4): Opponent awareness
5. **Locomotive Legend** (Level 5): Expert multi-factor optimization

You can override any of these by remapping levels to your custom strategies.

## Troubleshooting

### Strategy Not Working
- Check that all referenced tactics exist in the tactics list
- Verify weight values are reasonable (0.1-3.0 range)
- Ensure priorities don't conflict

### AI Playing Poorly
- Review tactic combinations for conflicts
- Adjust weight values (too high = dominant, too low = ineffective)
- Consider adding `endgame_awareness` for better late-game decisions

### Configuration Errors
- Use `/api/ai/reload` to reload from file after manual edits
- Check JSON syntax with a validator
- Review API error messages for specific issues