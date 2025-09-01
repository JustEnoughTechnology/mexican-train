#!/usr/bin/env python3
"""
API-Consistent AI Testing Command Line Interface
Run AI matches using the same GameManager and message handlers as real WebSocket connections
This ensures testing uses identical code paths to the frontend
"""

import argparse
import sys
import json
import logging
import asyncio
import statistics
from pathlib import Path

# Add the app directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "app"))

from app.testing.api_consistent_runner import APIConsistentAIRunner
from app.core.ai_config import ai_config

def setup_logging(log_level: str, log_file: str = None):
    """Configure logging based on command line arguments"""
    if log_level == 'off':
        # Disable all logging
        logging.disable(logging.CRITICAL)
        return
    
    # Map log levels
    level_map = {
        'info': logging.INFO,
        'debug': logging.DEBUG
    }
    
    # Configure logging
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    if log_file:
        logging.basicConfig(
            level=level_map[log_level],
            format=log_format,
            filename=log_file,
            filemode='w'
        )
        print(f"Logging to file: {log_file}")
    else:
        logging.basicConfig(
            level=level_map[log_level],
            format=log_format
        )
        print(f"Logging to console at level: {log_level}")

def list_strategies():
    """List all available AI strategies"""
    print("Available AI Strategies:")
    print("-" * 50)
    
    for name, config in ai_config.strategies.items():
        display_name = config.get('name', name)
        description = config.get('description', 'No description')
        tactics_count = len(config.get('tactics', []))
        
        print(f"{name:20} | {display_name}")
        print(f"{'':20} | {description}")
        print(f"{'':20} | {tactics_count} tactics")
        print()

async def run_single_match(args):
    """Run a single API-consistent AI match"""
    runner = APIConsistentAIRunner(args.results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"API-consistent match: {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    # Run match
    result = await runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id=args.match_id
    )
    
    # Save result
    runner.save_match_result(result)
    
    # Print summary
    print("\\n=== API-CONSISTENT MATCH SUMMARY ===")
    print(f"Testing Method: {result.get('testing_method', 'api_consistent')}")
    print(f"Winner: {result.get('winner', 'Unknown')}")
    print(f"Duration: {result['duration_seconds']} seconds")
    print(f"Games played: {result['games_played']}")
    print()
    
    print("Final Scores:")
    for player, data in result['players'].items():
        print(f"  {player:15} | {data['total_score']:4d} points | {data['games_won']} games won | Strategy: {data['strategy']}")
        print(f"  {'':15} | Messages: {data.get('messages_received', 0):3d} | Avg score: {data.get('average_game_score', 0):5.1f}")

async def run_batch_test(args):
    """Run multiple API-consistent matches of the same configuration"""
    runner = APIConsistentAIRunner(args.results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"API-consistent batch: {args.count} matches of {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"Running {args.count} API-consistent matches...")
    
    results = []
    wins_by_strategy = {strategy: 0 for strategy in args.strategies}
    games_won_by_strategy = {strategy: 0 for strategy in args.strategies}
    total_games_played = 0
    total_messages = 0
    
    for i in range(args.count):
        print(f"\\nMatch {i+1}/{args.count}")
        
        result = await runner.run_single_match(
            ai_configs,
            games_to_play=args.games,
            match_id=f"api_batch_{i+1}"
        )
        
        results.append(result)
        runner.save_match_result(result)
        
        # Track match wins by strategy
        winner_strategy = None
        for player, data in result['players'].items():
            if player == result['winner']:
                winner_strategy = data['strategy']
                break
        
        if winner_strategy:
            wins_by_strategy[winner_strategy] += 1
        
        # Track individual game wins by strategy and messages
        total_games_played += result['games_played']
        for player, data in result['players'].items():
            strategy = data['strategy']
            games_won_by_strategy[strategy] += data['games_won']
            total_messages += data.get('messages_received', 0)
    
    # Print batch summary sorted by specified criteria
    sort_type = "game wins" if args.sort_by == 'games' else "match wins"
    print(f"\\n=== API-CONSISTENT BATCH SUMMARY ({args.count} matches, {total_games_played} total games) ===")
    print(f"Testing Method: API-Consistent (GameManager + Message Handlers)")
    print(f"Total Messages Processed: {total_messages}")
    print(f"Sorted by: {sort_type}")
    
    # Create list of strategies with their stats for sorting
    strategy_stats = []
    for strategy in args.strategies:
        match_wins = wins_by_strategy[strategy]
        match_win_rate = (match_wins / args.count) * 100 if args.count > 0 else 0
        game_wins = games_won_by_strategy[strategy]
        game_win_rate = (game_wins / total_games_played) * 100 if total_games_played > 0 else 0
        strategy_stats.append((strategy, match_wins, match_win_rate, game_wins, game_win_rate))
    
    # Sort by specified criteria (descending)
    if args.sort_by == 'games':
        strategy_stats.sort(key=lambda x: x[4], reverse=True)  # Sort by game win rate
    else:  # args.sort_by == 'matches'
        strategy_stats.sort(key=lambda x: x[2], reverse=True)  # Sort by match win rate
    
    for strategy, match_wins, match_win_rate, game_wins, game_win_rate in strategy_stats:
        print(f"{strategy:20} | {match_wins:3d} match wins ({match_win_rate:5.1f}%) | {game_wins:3d} game wins ({game_win_rate:5.1f}%)")

async def run_comparison_test(args):
    """Run matches with both old and new testing methods for comparison"""
    print("=== RUNNING COMPARISON TEST ===")
    print("Testing both original AI runner and new API-consistent runner")
    print()
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Run with original method
    print("Running with ORIGINAL method (direct game calls)...")
    from app.testing.ai_match_runner import AIMatchRunner
    
    original_runner = AIMatchRunner("comparison_original_results")
    original_runner.create_test_session("Comparison Test - Original Method")
    
    original_result = original_runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id="comparison_original"
    )
    
    original_runner.save_match_result(original_result)
    
    print(f"Original method: Winner = {original_result.get('winner')}, Duration = {original_result['duration_seconds']:.2f}s")
    print()
    
    # Run with new method
    print("Running with API-CONSISTENT method (GameManager + message handlers)...")
    
    api_runner = APIConsistentAIRunner("comparison_api_results")
    api_runner.create_test_session("Comparison Test - API-Consistent Method")
    
    api_result = await api_runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id="comparison_api"
    )
    
    api_runner.save_match_result(api_result)
    
    print(f"API-consistent method: Winner = {api_result.get('winner')}, Duration = {api_result['duration_seconds']:.2f}s")
    print()
    
    # Compare results
    print("=== COMPARISON RESULTS ===")
    print(f"Original method duration:     {original_result['duration_seconds']:8.2f}s")
    print(f"API-consistent duration:      {api_result['duration_seconds']:8.2f}s")
    print(f"Games played (original):      {original_result['games_played']:8d}")
    print(f"Games played (api):           {api_result['games_played']:8d}")
    print(f"Messages processed (api):     {sum(p.get('messages_received', 0) for p in api_result['players'].values()):8d}")
    
    # Note: Winners may differ due to randomness in AI decisions

def main():
    parser = argparse.ArgumentParser(description="API-Consistent AI Strategy Testing Tool")
    parser.add_argument('--results-dir', default='api_consistent_results', 
                       help='Directory to store test results')
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='off',
                       help='Logging level (default: off)')
    parser.add_argument('--log-file', type=str,
                       help='Log to file instead of console (optional)')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies command
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match command
    match_parser = subparsers.add_parser('match', help='Run a single API-consistent AI match')
    match_parser.add_argument('strategies', nargs='+', 
                             help='AI strategies to compete (2-8 strategies)')
    match_parser.add_argument('--games', type=int, default=13,
                             help='Number of games in the match (default: 13)')
    match_parser.add_argument('--match-id', 
                             help='Custom match ID (optional)')
    
    # Batch test command
    batch_parser = subparsers.add_parser('batch', help='Run multiple API-consistent matches')
    batch_parser.add_argument('strategies', nargs='+',
                             help='AI strategies to compete (2-8 strategies)')
    batch_parser.add_argument('--count', type=int, default=10,
                             help='Number of matches to run (default: 10)')
    batch_parser.add_argument('--games', type=int, default=13,
                             help='Games per match (default: 13)')
    batch_parser.add_argument('--sort-by', choices=['games', 'matches'], default='games',
                             help='Sort results by game wins or match wins (default: games)')
    
    # Comparison test command
    compare_parser = subparsers.add_parser('compare', help='Compare original vs API-consistent methods')
    compare_parser.add_argument('strategies', nargs='+',
                               help='AI strategies to compete (2-8 strategies)')
    compare_parser.add_argument('--games', type=int, default=13,
                               help='Number of games in the match (default: 13)')
    
    args = parser.parse_args()
    
    # Setup logging based on command line arguments
    setup_logging(args.log_level, args.log_file)
    
    print(f"Loaded AI config: {len(ai_config.tactics)} tactics, {len(ai_config.strategies)} strategies")
    
    if args.command == 'list':
        list_strategies()
    elif args.command == 'match':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("Error: Need 2-8 strategies for a match")
            sys.exit(1)
        asyncio.run(run_single_match(args))
    elif args.command == 'batch':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("Error: Need 2-8 strategies for batch testing")
            sys.exit(1)
        asyncio.run(run_batch_test(args))
    elif args.command == 'compare':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("Error: Need 2-8 strategies for comparison")
            sys.exit(1)
        asyncio.run(run_comparison_test(args))
    else:
        parser.print_help()

if __name__ == '__main__':
    main()