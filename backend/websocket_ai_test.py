#!/usr/bin/env python3
"""
WebSocket AI Testing Command Line Interface  
Run AI-only matches using real WebSocket connections to test the full backend stack
"""

import argparse
import sys
import json
import logging
import asyncio
from pathlib import Path

# Add the app directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "app"))

from app.testing.websocket_ai_runner import WebSocketAIRunner
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
    """Run a single WebSocket AI match"""
    runner = WebSocketAIRunner(
        results_dir=args.results_dir,
        backend_url=f"ws://localhost:{args.port}"
    )
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"WebSocket match: {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    # Run match
    result = await runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id=args.match_id
    )
    
    # Save result
    if result.get("success", True):
        runner.save_match_result(result)
        
        # Print summary
        print("\\n=== WEBSOCKET MATCH SUMMARY ===")
        print(f"Match ID: {result['match_id']}")
        print(f"Backend URL: {result.get('backend_url', 'unknown')}")
        print(f"Connection: {result.get('connection_type', 'websocket')}")
        print(f"Winner: {result.get('winner', 'Unknown')}")
        print(f"Duration: {result['duration_seconds']} seconds")
        print(f"Games played: {result['games_played']}")
        print()
        
        print("Players:")
        for player, data in result.get('players', {}).items():
            print(f"  {player:15} | {data.get('total_score', 0):4d} points | {data.get('games_won', 0)} games won | Strategy: {data.get('strategy', 'unknown')}")
    else:
        print(f"\\n=== MATCH FAILED ===")
        print(f"Error: {result.get('error', 'Unknown error')}")

async def run_batch_test(args):
    """Run multiple WebSocket matches of the same configuration"""
    runner = WebSocketAIRunner(
        results_dir=args.results_dir,
        backend_url=f"ws://localhost:{args.port}"
    )
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"WebSocket batch: {args.count} matches of {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"Running {args.count} WebSocket matches...")
    print(f"Backend URL: ws://localhost:{args.port}")
    
    batch_result = await runner.run_batch_test(
        ai_configs,
        count=args.count,
        games_per_match=args.games
    )
    
    # Print batch summary
    successful_matches = batch_result["successful_matches"] 
    total_matches = batch_result["total_matches"]
    wins_by_strategy = batch_result["wins_by_strategy"]
    games_won_by_strategy = batch_result["games_won_by_strategy"]
    total_games_played = batch_result["total_games_played"]
    
    sort_type = "game wins" if args.sort_by == 'games' else "match wins"
    print(f"\\n=== WEBSOCKET BATCH TEST SUMMARY ({successful_matches}/{total_matches} matches, {total_games_played} total games) ===")
    print(f"Backend: ws://localhost:{args.port}")
    print(f"Sorted by: {sort_type}")
    
    # Create list of strategies with their stats for sorting
    strategy_stats = []
    for strategy in args.strategies:
        match_wins = wins_by_strategy.get(strategy, 0)
        match_win_rate = (match_wins / successful_matches) * 100 if successful_matches > 0 else 0
        game_wins = games_won_by_strategy.get(strategy, 0)
        game_win_rate = (game_wins / total_games_played) * 100 if total_games_played > 0 else 0
        strategy_stats.append((strategy, match_wins, match_win_rate, game_wins, game_win_rate))
    
    # Sort by specified criteria (descending)
    if args.sort_by == 'games':
        strategy_stats.sort(key=lambda x: x[4], reverse=True)  # Sort by game win rate
    else:  # args.sort_by == 'matches'
        strategy_stats.sort(key=lambda x: x[2], reverse=True)  # Sort by match win rate
    
    for strategy, match_wins, match_win_rate, game_wins, game_win_rate in strategy_stats:
        print(f"{strategy:20} | {match_wins:3d} match wins ({match_win_rate:5.1f}%) | {game_wins:3d} game wins ({game_win_rate:5.1f}%)")

def main():
    parser = argparse.ArgumentParser(description="WebSocket AI Strategy Testing Tool")
    parser.add_argument('--results-dir', default='websocket_ai_results', 
                       help='Directory to store test results')
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='off',
                       help='Logging level (default: off)')
    parser.add_argument('--log-file', type=str,
                       help='Log to file instead of console (optional)')
    parser.add_argument('--port', type=int, default=8002,
                       help='Backend WebSocket port (default: 8002)')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies command
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match command
    match_parser = subparsers.add_parser('match', help='Run a single WebSocket AI match')
    match_parser.add_argument('strategies', nargs='+', 
                             help='AI strategies to compete (2-8 strategies)')
    match_parser.add_argument('--games', type=int, default=13,
                             help='Number of games in the match (default: 13)')
    match_parser.add_argument('--match-id', 
                             help='Custom match ID (optional)')
    
    # Batch test command
    batch_parser = subparsers.add_parser('batch', help='Run multiple WebSocket matches with same configuration')
    batch_parser.add_argument('strategies', nargs='+',
                             help='AI strategies to compete (2-8 strategies)')
    batch_parser.add_argument('--count', type=int, default=10,
                             help='Number of matches to run (default: 10)')
    batch_parser.add_argument('--games', type=int, default=13,
                             help='Games per match (default: 13)')
    batch_parser.add_argument('--sort-by', choices=['games', 'matches'], default='games',
                             help='Sort results by game wins or match wins (default: games)')
    
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
    else:
        parser.print_help()

if __name__ == '__main__':
    main()