# AI Testing Framework Guide

The Mexican Train game includes a comprehensive AI testing framework for evaluating strategy performance through headless matches. This allows you to run hundreds of AI-only games to measure how different strategies perform against each other.

## Quick Start

### Prerequisites
```bash
cd backend
python -m pip install -r requirements.txt  # Ensure dependencies are installed
```

### List Available Strategies
```bash
python ai_test.py list
```

### Run a Single Match
```bash
# 2-player match: Slow Freight vs Fast Passenger (13 games)
python ai_test.py match slow_freight fast_passenger

# 4-player match with custom game count
python ai_test.py match sleepy_caboose slow_freight local_express fast_passenger --games 7
```

### Run a Tournament
```bash
# Round-robin tournament with all default strategies (5 rounds each matchup)
python ai_test.py tournament sleepy_caboose slow_freight local_express fast_passenger

# Quick tournament with fewer rounds
python ai_test.py tournament slow_freight local_express fast_passenger --rounds 3 --games 7
```

### Batch Testing
```bash
# Run 50 matches of the same configuration for statistical significance
python ai_test.py batch slow_freight fast_passenger --count 50 --games 13
```

### Analyze Results
```bash
# List all test sessions
python ai_test.py analyze

# Analyze specific session
python ai_test.py analyze --session session_20241201_143022
```

## Commands Reference

### `list` - List Available Strategies
Shows all AI strategies with descriptions and tactic counts.

```bash
python ai_test.py list
```

### `match` - Single AI Match
Run one match between 2-4 AI strategies.

```bash
python ai_test.py match <strategy1> <strategy2> [strategy3] [strategy4] [options]

Options:
  --games N       Number of games per match (default: 13)
  --match-id ID   Custom match identifier
  --results-dir   Directory to store results (default: ai_test_results)
```

**Examples:**
```bash
# Basic 2-player match
python ai_test.py match slow_freight fast_passenger

# 3-player match with fewer games
python ai_test.py match sleepy_caboose local_express locomotive_legend --games 5

# Custom match ID for tracking
python ai_test.py match slow_freight fast_passenger --match-id "penalty_vs_blocking_test_1"
```

### `tournament` - Round-Robin Tournament
All strategies compete against each other in multiple rounds.

```bash
python ai_test.py tournament <strategy1> <strategy2> ... [options]

Options:
  --rounds N      Rounds per unique matchup (default: 5)
  --games N       Games per match (default: 13)  
  --results-dir   Directory to store results
```

**Examples:**
```bash
# Full tournament with all strategies
python ai_test.py tournament sleepy_caboose slow_freight local_express fast_passenger locomotive_legend

# Quick tournament for testing
python ai_test.py tournament slow_freight fast_passenger locomotive_legend --rounds 2 --games 5

# Custom strategies tournament
python ai_test.py tournament my_custom_ai aggressive_blocker conservative_player
```

### `batch` - Batch Testing
Run multiple matches with the same configuration for statistical analysis.

```bash
python ai_test.py batch <strategy1> <strategy2> ... [options]

Options:
  --count N       Number of matches to run (default: 10)
  --games N       Games per match (default: 13)
  --results-dir   Directory to store results
```

**Examples:**
```bash
# 100 matches for statistical significance
python ai_test.py batch slow_freight fast_passenger --count 100

# Quick batch test
python ai_test.py batch sleepy_caboose locomotive_legend --count 20 --games 5
```

### `analyze` - Results Analysis
Analyze saved test results and sessions.

```bash
python ai_test.py analyze [options]

Options:
  --session ID    Analyze specific session
  --results-dir   Results directory to analyze
```

**Examples:**
```bash
# List all sessions
python ai_test.py analyze

# Analyze specific session
python ai_test.py analyze --session session_20241201_143022

# Use custom results directory
python ai_test.py analyze --results-dir my_test_results
```

## Understanding Results

### Match Results Structure
Each match produces detailed JSON results:

```json
{
  "match_id": "test_match_abc123",
  "timestamp": "2024-12-01T14:30:22",
  "duration_seconds": 45.2,
  "games_played": 13,
  "winner": "AI_2_fast_passenger",
  "players": {
    "AI_1_slow_freight": {
      "strategy": "slow_freight",
      "total_score": 267,
      "games_won": 4,
      "average_game_score": 20.5,
      "best_game_score": 8,
      "worst_game_score": 35
    },
    "AI_2_fast_passenger": {
      "strategy": "fast_passenger", 
      "total_score": 243,
      "games_won": 9,
      "average_game_score": 18.7,
      "best_game_score": 5,
      "worst_game_score": 31
    }
  },
  "game_results": [...] // Detailed per-game results
}
```

### Tournament Results
Tournaments produce comprehensive statistics:

```json
{
  "summary": {
    "locomotive_legend": {
      "matches_played": 20,
      "matches_won": 16,
      "win_rate": 80.0,
      "game_win_rate": 73.5,
      "average_score": 15.2
    },
    "fast_passenger": {
      "matches_played": 20,
      "matches_won": 12,
      "win_rate": 60.0,
      "game_win_rate": 58.3,
      "average_score": 18.7
    }
  }
}
```

### Key Metrics

- **Win Rate**: Percentage of matches won
- **Game Win Rate**: Percentage of individual games won
- **Average Score**: Lower is better (fewer penalty points)
- **Best/Worst Game Score**: Range of individual game performance

## Testing Strategies

### 1. Basic Strategy Comparison
```bash
# Compare two specific strategies
python ai_test.py batch strategy_a strategy_b --count 50
```

### 2. Difficulty Progression Testing
```bash
# Test if higher levels actually perform better
python ai_test.py tournament sleepy_caboose slow_freight local_express fast_passenger locomotive_legend --rounds 10
```

### 3. Custom Strategy Validation
```bash
# Test your custom strategy against established ones
python ai_test.py match my_new_strategy locomotive_legend --count 25
```

### 4. Statistical Significance Testing
```bash
# Large batch for statistical confidence
python ai_test.py batch strategy_a strategy_b --count 200
```

### 5. Multi-Player Dynamics
```bash
# How strategies perform in 3-4 player games
python ai_test.py tournament strategy_a strategy_b strategy_c strategy_d --rounds 10
```

## Performance Optimization Tips

### Speed vs Accuracy Trade-offs
- **Quick tests**: `--games 5` for rapid iteration
- **Balanced tests**: `--games 13` (default) for good accuracy
- **Thorough tests**: `--games 25` for maximum confidence

### Sample Sizes
- **Development**: 10-20 matches per comparison
- **Validation**: 50-100 matches per comparison  
- **Publication**: 200+ matches per comparison

### Session Management
- Use descriptive session names when creating tests
- Regularly archive old results to keep directories clean
- Save important tournament results with meaningful names

## Results Storage

### File Structure
```
ai_test_results/
├── session_20241201_143022.json    # Individual session
├── tournament_20241201_145533.json # Tournament results
└── session_20241201_150800.json    # Another session
```

### Session Files
Each testing session creates a JSON file containing:
- Session metadata (ID, timestamp, description)
- All match results from that session
- Cumulative statistics

### Tournament Files
Tournament results are saved separately with:
- Complete round-robin results
- Per-strategy performance summaries
- Head-to-head matchup details

## Advanced Usage

### Custom Results Directory
```bash
python ai_test.py match strategy_a strategy_b --results-dir experiment_1_results
```

### Scripted Testing
Create bash/batch scripts for repeated testing:

```bash
#!/bin/bash
# test_all_strategies.sh

echo "Running comprehensive strategy evaluation..."

# Test each strategy against the baseline
for strategy in slow_freight local_express fast_passenger locomotive_legend; do
    echo "Testing $strategy vs sleepy_caboose..."
    python ai_test.py batch sleepy_caboose $strategy --count 50 --games 13
done

# Full tournament
echo "Running tournament..."
python ai_test.py tournament sleepy_caboose slow_freight local_express fast_passenger locomotive_legend --rounds 10

echo "Testing complete!"
```

### Integration with Strategy Development
1. Create new strategy in `ai_strategies.json`
2. Test against existing strategies: `python ai_test.py batch new_strategy locomotive_legend --count 25`
3. Analyze results: `python ai_test.py analyze`
4. Iterate strategy design based on performance
5. Run full tournament when satisfied

## Troubleshooting

### Common Issues

**"Strategy not found" Error**
- Use `python ai_test.py list` to see available strategies
- Check spelling of strategy names
- Ensure `ai_strategies.json` is properly loaded

**Long execution times**
- Reduce `--games` count for faster tests
- Use fewer `--rounds` in tournaments  
- Reduce `--count` in batch tests

**Memory issues with large tournaments**
- Run tournaments in smaller batches
- Clear results directory periodically
- Use fewer concurrent strategies

### Debug Mode
Add debugging prints to the match runner for detailed execution tracking:

```python
# In ai_match_runner.py, set debug=True for verbose output
DEBUG_MODE = True  # Add this flag for troubleshooting
```

## Example Testing Workflow

### 1. Initial Strategy Development
```bash
# Create and test new strategy
curl -X POST http://localhost:8000/api/ai/strategies -d '...'
python ai_test.py match new_strategy locomotive_legend --count 10
```

### 2. Refinement Testing
```bash
# Quick comparison after adjustments
python ai_test.py batch new_strategy_v2 new_strategy_v1 --count 25 --games 7
```

### 3. Comprehensive Validation
```bash
# Full tournament with refined strategy
python ai_test.py tournament new_strategy_final slow_freight local_express fast_passenger locomotive_legend --rounds 20
```

### 4. Statistical Confirmation
```bash
# Large sample size for final validation
python ai_test.py batch new_strategy_final locomotive_legend --count 500
```

This framework provides everything needed to scientifically evaluate and improve AI strategies for Mexican Train dominoes!