#!/usr/bin/env python3
"""
API-Consistent AI Testing - Docker Environment Version
Uses GameManager and message handlers for realistic testing
"""

import argparse
import sys
import json
import logging
import asyncio
import os
from pathlib import Path

# Add app to path
sys.path.insert(0, '/app')

from testing_frameworks.api_consistent_runner import APIConsistentAIRunner
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

async def run_single_match(args):
    """Run a single API-consistent match"""
    results_dir = os.path.join("/app/results", "api_consistent_results")
    runner = APIConsistentAIRunner(results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Docker API-consistent: {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"🎮 Running API-consistent match: {' vs '.join(args.strategies)}")
    print(f"📊 Games per match: {args.games}")
    
    # Run match
    result = await runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id=args.match_id or f"docker_match"
    )
    
    # Save result
    runner.save_match_result(result)
    
    # Print summary
    print("\\n🏆 === API-CONSISTENT MATCH RESULTS ===")
    print(f"🎯 Testing Method: {result.get('testing_method', 'api_consistent')}")
    print(f"👑 Winner: {result.get('winner', 'No winner')}")
    print(f"⏱️  Duration: {result['duration_seconds']:.2f} seconds")
    print(f"🎲 Games played: {result['games_played']}/{result['games_to_play']}")
    print(f"📨 Total messages processed: {sum(p.get('messages_received', 0) for p in result['players'].values())}")
    print()
    
    print("📋 Player Results:")
    for player, data in result['players'].items():
        print(f"  🤖 {player:20} | {data['total_score']:4d} pts | {data['games_won']} wins | {data['strategy']}")
        print(f"     {'':20} | {data.get('messages_received', 0):3d} msgs | avg: {data.get('average_game_score', 0):5.1f}")

async def run_batch_test(args):
    """Run multiple API-consistent matches"""
    results_dir = os.path.join("/app/results", "api_consistent_results")
    runner = APIConsistentAIRunner(results_dir)
    
    # Parse AI configurations  
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Docker API batch: {args.count}x {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"🔄 Running {args.count} API-consistent matches...")
    print(f"🎮 {args.games} games per match")
    
    results = []
    wins_by_strategy = {strategy: 0 for strategy in args.strategies}
    total_messages = 0
    
    for i in range(args.count):
        print(f"\\n--- 📊 Match {i+1}/{args.count} ---")
        
        result = await runner.run_single_match(
            ai_configs,
            games_to_play=args.games,
            match_id=f"docker_batch_{i+1}"
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
        
        total_messages += sum(p.get('messages_received', 0) for p in result['players'].values())
        
        print(f"   Winner: {result.get('winner', 'None')} ({winner_strategy})")
        print(f"   Duration: {result['duration_seconds']:.2f}s")
    
    # Print batch summary
    print(f"\\n🎯 === API-CONSISTENT BATCH RESULTS ===")
    print(f"📊 Matches completed: {len(results)}/{args.count}")
    print(f"📨 Total messages processed: {total_messages}")
    print(f"⚡ Average messages per match: {total_messages/len(results):.1f}")
    print()
    
    print("🏆 Strategy Performance:")
    # Sort by wins
    strategy_stats = [(strategy, wins) for strategy, wins in wins_by_strategy.items()]
    strategy_stats.sort(key=lambda x: x[1], reverse=True)
    
    for strategy, wins in strategy_stats:
        win_rate = (wins / args.count) * 100 if args.count > 0 else 0
        print(f"  🤖 {strategy:20} | {wins:3d} wins | {win_rate:5.1f}%")

def main():
    parser = argparse.ArgumentParser(description="API-Consistent AI Testing - Docker Environment")
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='info',
                       help='Logging level (default: info)')
    parser.add_argument('--log-file', type=str, help='Log to file')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match
    match_parser = subparsers.add_parser('match', help='Run single API-consistent match')
    match_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    match_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    match_parser.add_argument('--match-id', help='Custom match ID')
    
    # Batch test
    batch_parser = subparsers.add_parser('batch', help='Run multiple API-consistent matches')
    batch_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    batch_parser.add_argument('--count', type=int, default=3, help='Number of matches (default: 3)')
    batch_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    
    args = parser.parse_args()
    
    setup_logging(args.log_level, args.log_file)
    
    print(f"🐳 Docker API-Consistent AI Testing Environment")
    print(f"🤖 Loaded AI config: {len(ai_config.tactics)} tactics, {len(ai_config.strategies)} strategies")
    
    if args.command == 'list':
        list_strategies()
    elif args.command == 'match':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for a match")
            sys.exit(1)
        asyncio.run(run_single_match(args))
    elif args.command == 'batch':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for batch testing")
            sys.exit(1)
        asyncio.run(run_batch_test(args))
    else:
        parser.print_help()

if __name__ == '__main__':
    main()