#!/usr/bin/env python3
"""
Classic AI Testing - Docker Environment Version  
Direct game method calls (original approach) for comparison testing
"""

import argparse
import sys
import json
import logging
import statistics
import os
from pathlib import Path

# Add app to path
sys.path.insert(0, '/app')

from app.testing.ai_match_runner import AIMatchRunner
from app.core.ai_config import ai_config

def setup_logging(log_level: str, log_file: str = None):
    """Configure logging"""
    if log_level == 'off':
        logging.disable(logging.CRITICAL)
        return
    
    level_map = {'info': logging.INFO, 'debug': logging.DEBUG}
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
    if log_file:
        logging.basicConfig(level=level_map[log_level], format=log_format, filename=log_file, filemode='w')
        print(f"📝 Logging to file: {log_file}")
    else:
        logging.basicConfig(level=level_map[log_level], format=log_format)
        print(f"📝 Logging to console at level: {log_level}")

def list_strategies():
    """List all available AI strategies"""
    print("🤖 Available AI Strategies:")
    print("-" * 50)
    
    for name, config in ai_config.strategies.items():
        display_name = config.get('name', name)
        description = config.get('description', 'No description')
        tactics_count = len(config.get('tactics', []))
        
        print(f"{name:20} | {display_name}")
        print(f"{'':20} | {description}")
        print(f"{'':20} | {tactics_count} tactics")
        print()

def run_single_match(args):
    """Run a single classic AI match"""
    results_dir = os.path.join("/app/results", "classic_results")
    runner = AIMatchRunner(results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Docker classic: {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"🎮 Running classic match: {' vs '.join(args.strategies)}")
    print(f"📊 Games per match: {args.games}")
    
    # Run match
    result = runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id=args.match_id or "docker_classic_match"
    )
    
    # Save result
    runner.save_match_result(result)
    
    # Print summary
    print("\\n🏆 === CLASSIC AI MATCH RESULTS ===")
    print(f"🎯 Testing Method: Classic (Direct Game Calls)")
    print(f"👑 Winner: {result.get('winner', 'No winner')}")
    print(f"⏱️  Duration: {result['duration_seconds']:.2f} seconds")
    print(f"🎲 Games played: {result['games_played']}/{result['games_to_play']}")
    print(f"✅ Match completed: {result['match_completed']}")
    print()
    
    print("📋 Player Results:")
    for player, data in result['players'].items():
        print(f"  🤖 {player:20} | {data['total_score']:4d} pts | {data['games_won']} wins | {data['strategy']}")
        print(f"     {'':20} | avg: {data.get('average_game_score', 0):5.1f} | best: {data.get('best_game_score', 0)}")

def run_batch_test(args):
    """Run multiple classic AI matches"""
    results_dir = os.path.join("/app/results", "classic_results")
    runner = AIMatchRunner(results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Docker classic batch: {args.count}x {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"🔄 Running {args.count} classic AI matches...")
    print(f"🎮 {args.games} games per match")
    
    results = []
    wins_by_strategy = {strategy: 0 for strategy in args.strategies}
    games_won_by_strategy = {strategy: 0 for strategy in args.strategies}
    total_games_played = 0
    
    for i in range(args.count):
        print(f"\\n--- 📊 Match {i+1}/{args.count} ---")
        
        result = runner.run_single_match(
            ai_configs,
            games_to_play=args.games,
            match_id=f"docker_classic_batch_{i+1}"
        )
        
        results.append(result)
        runner.save_match_result(result)
        
        # Track stats
        winner_strategy = None
        for player, data in result['players'].items():
            if player == result['winner']:
                winner_strategy = data['strategy']
                break
        
        if winner_strategy:
            wins_by_strategy[winner_strategy] += 1
        
        # Track individual game wins by strategy
        total_games_played += result['games_played']
        for player, data in result['players'].items():
            strategy = data['strategy']
            games_won_by_strategy[strategy] += data['games_won']
        
        print(f"   Winner: {result.get('winner', 'None')} ({winner_strategy})")
        print(f"   Duration: {result['duration_seconds']:.2f}s")
    
    # Print batch summary sorted by specified criteria
    sort_type = "game wins" if args.sort_by == 'games' else "match wins"
    print(f"\\n🎯 === CLASSIC BATCH RESULTS ({len(results)} matches, {total_games_played} total games) ===")
    print(f"📊 Testing Method: Classic (Direct Game Calls)")
    print(f"📈 Sorted by: {sort_type}")
    print()
    
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
    
    print("🏆 Strategy Performance:")
    for strategy, match_wins, match_win_rate, game_wins, game_win_rate in strategy_stats:
        print(f"  🤖 {strategy:20} | {match_wins:3d} match wins ({match_win_rate:5.1f}%) | {game_wins:3d} game wins ({game_win_rate:5.1f}%)")

def main():
    parser = argparse.ArgumentParser(description="Classic AI Testing - Docker Environment")
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='info',
                       help='Logging level (default: info)')
    parser.add_argument('--log-file', type=str, help='Log to file')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match
    match_parser = subparsers.add_parser('match', help='Run single classic match')
    match_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    match_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    match_parser.add_argument('--match-id', help='Custom match ID')
    
    # Batch test
    batch_parser = subparsers.add_parser('batch', help='Run multiple classic matches')
    batch_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    batch_parser.add_argument('--count', type=int, default=3, help='Number of matches (default: 3)')
    batch_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    batch_parser.add_argument('--sort-by', choices=['games', 'matches'], default='games',
                             help='Sort results by game wins or match wins (default: games)')
    
    args = parser.parse_args()
    
    setup_logging(args.log_level, args.log_file)
    
    print(f"🐳 Docker Classic AI Testing Environment")
    print(f"🤖 Loaded AI config: {len(ai_config.tactics)} tactics, {len(ai_config.strategies)} strategies")
    
    if args.command == 'list':
        list_strategies()
    elif args.command == 'match':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for a match")
            sys.exit(1)
        run_single_match(args)
    elif args.command == 'batch':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for batch testing")
            sys.exit(1)
        run_batch_test(args)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()