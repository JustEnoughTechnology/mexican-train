#!/usr/bin/env python3
"""
AI Testing Command Line Interface
Run AI-only matches to evaluate strategy performance
"""

import argparse
import sys
import json
import logging
from pathlib import Path

# Add the app directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "app"))

from app.testing.ai_match_runner import AIMatchRunner
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

def run_single_match(args):
    """Run a single AI match"""
    runner = AIMatchRunner(args.results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Single match: {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    # Run match
    result = runner.run_single_match(
        ai_configs,
        games_to_play=args.games,
        match_id=args.match_id
    )
    
    # Save result
    runner.save_match_result(result)
    
    # Print summary
    print("\n=== MATCH SUMMARY ===")
    print(f"Winner: {result['winner']}")
    print(f"Duration: {result['duration_seconds']} seconds")
    print(f"Games played: {result['games_played']}")
    print()
    
    print("Final Scores:")
    for player, data in result['players'].items():
        print(f"  {player:15} | {data['total_score']:4d} points | {data['games_won']} games won | Strategy: {data['strategy']}")

def run_tournament(args):
    """Run a round-robin tournament"""
    runner = AIMatchRunner(args.results_dir)
    
    # Create session
    session_desc = f"Tournament: {', '.join(args.strategies)} ({args.rounds} rounds each)"
    runner.create_test_session(session_desc)
    
    # Run tournament
    results = runner.run_tournament(
        strategies=args.strategies,
        rounds_per_matchup=args.rounds,
        games_per_match=args.games
    )
    
    print(f"\nTournament saved to: tournament_{results['tournament_id']}.json")

def run_batch_test(args):
    """Run multiple matches of the same configuration"""
    runner = AIMatchRunner(args.results_dir)
    
    # Parse AI configurations
    ai_configs = []
    for i, strategy in enumerate(args.strategies):
        ai_configs.append({
            "name": f"AI_{i+1}_{strategy}",
            "strategy": strategy
        })
    
    # Create session
    session_desc = f"Batch test: {args.count} matches of {' vs '.join(args.strategies)}"
    runner.create_test_session(session_desc)
    
    print(f"Running {args.count} matches...")
    
    results = []
    wins_by_strategy = {strategy: 0 for strategy in args.strategies}
    games_won_by_strategy = {strategy: 0 for strategy in args.strategies}
    total_games_played = 0
    
    for i in range(args.count):
        print(f"\nMatch {i+1}/{args.count}")
        
        result = runner.run_single_match(
            ai_configs,
            games_to_play=args.games,
            match_id=f"batch_{i+1}"
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
        
        # Track individual game wins by strategy
        total_games_played += result['games_played']
        for player, data in result['players'].items():
            strategy = data['strategy']
            games_won_by_strategy[strategy] += data['games_won']
    
    # Print batch summary sorted by specified criteria
    sort_type = "game wins" if args.sort_by == 'games' else "match wins"
    print(f"\n=== BATCH TEST SUMMARY ({args.count} matches, {total_games_played} total games) ===")
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

def analyze_results(args):
    """Analyze saved results"""
    results_dir = Path(args.results_dir)
    
    if args.session:
        # Analyze specific session
        session_file = results_dir / f"{args.session}.json"
        if not session_file.exists():
            print(f"Session file not found: {session_file}")
            return
        
        with open(session_file, 'r') as f:
            session_data = json.load(f)
        
        print(f"Session: {session_data['session_id']}")
        print(f"Description: {session_data.get('description', 'No description')}")
        print(f"Matches: {len(session_data['matches'])}")
        print()
        
        # Strategy performance summary
        strategy_wins = {}
        total_matches = 0
        
        for match in session_data['matches']:
            total_matches += 1
            winner_strategy = None
            
            for player, data in match['players'].items():
                if player == match['winner']:
                    winner_strategy = data['strategy']
                    break
            
            if winner_strategy:
                strategy_wins[winner_strategy] = strategy_wins.get(winner_strategy, 0) + 1
        
        print("Strategy Performance:")
        for strategy, wins in strategy_wins.items():
            win_rate = (wins / total_matches) * 100 if total_matches > 0 else 0
            print(f"  {strategy:20} | {wins:3d} wins | {win_rate:5.1f}%")
    else:
        # List all sessions
        print("Available Sessions:")
        print("-" * 50)
        
        for session_file in results_dir.glob("session_*.json"):
            try:
                with open(session_file, 'r') as f:
                    session_data = json.load(f)
                
                session_id = session_data['session_id']
                description = session_data.get('description', 'No description')
                match_count = len(session_data['matches'])
                
                print(f"{session_id:25} | {match_count:3d} matches | {description}")
            except Exception as e:
                print(f"Error reading {session_file}: {e}")

def main():
    parser = argparse.ArgumentParser(description="AI Strategy Testing Tool")
    parser.add_argument('--results-dir', default='ai_test_results', 
                       help='Directory to store test results')
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='off',
                       help='Logging level (default: off)')
    parser.add_argument('--log-file', type=str,
                       help='Log to file instead of console (optional)')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies command
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match command
    match_parser = subparsers.add_parser('match', help='Run a single AI match')
    match_parser.add_argument('strategies', nargs='+', 
                             help='AI strategies to compete (2-8 strategies)')
    match_parser.add_argument('--games', type=int, default=13,
                             help='Number of games in the match (default: 13)')
    match_parser.add_argument('--match-id', 
                             help='Custom match ID (optional)')
    
    # Tournament command
    tournament_parser = subparsers.add_parser('tournament', help='Run round-robin tournament')
    tournament_parser.add_argument('strategies', nargs='+',
                                  help='AI strategies to compete (2+ strategies)')
    tournament_parser.add_argument('--rounds', type=int, default=5,
                                  help='Rounds per matchup (default: 5)')
    tournament_parser.add_argument('--games', type=int, default=13,
                                  help='Games per match (default: 13)')
    
    # Batch test command
    batch_parser = subparsers.add_parser('batch', help='Run multiple matches with same configuration')
    batch_parser.add_argument('strategies', nargs='+',
                             help='AI strategies to compete (2-8 strategies)')
    batch_parser.add_argument('--count', type=int, default=10,
                             help='Number of matches to run (default: 10)')
    batch_parser.add_argument('--games', type=int, default=13,
                             help='Games per match (default: 13)')
    batch_parser.add_argument('--sort-by', choices=['games', 'matches'], default='games',
                             help='Sort results by game wins or match wins (default: games)')
    
    # Analyze results command
    analyze_parser = subparsers.add_parser('analyze', help='Analyze saved results')
    analyze_parser.add_argument('--session', help='Specific session to analyze')
    
    args = parser.parse_args()
    
    # Setup logging based on command line arguments
    setup_logging(args.log_level, args.log_file)
    
    if args.command == 'list':
        list_strategies()
    elif args.command == 'match':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("Error: Need 2-8 strategies for a match")
            sys.exit(1)
        run_single_match(args)
    elif args.command == 'tournament':
        if len(args.strategies) < 2:
            print("Error: Need at least 2 strategies for a tournament")
            sys.exit(1)
        run_tournament(args)
    elif args.command == 'batch':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("Error: Need 2-8 strategies for batch testing")
            sys.exit(1)
        run_batch_test(args)
    elif args.command == 'analyze':
        analyze_results(args)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()