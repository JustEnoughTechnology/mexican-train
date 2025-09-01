#!/usr/bin/env python3
"""
WebSocket AI Testing - Docker Environment Version
Run AI-only matches using real WebSocket connections
"""

import argparse
import sys
import json
import logging
import asyncio
import statistics
import os
from pathlib import Path

# Add the app directory to Python path
sys.path.insert(0, '/app')

from testing_frameworks.websocket_ai_client import WebSocketAIClient
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
        print(f"Logging to file: {log_file}")
    else:
        logging.basicConfig(level=level_map[log_level], format=log_format)
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

async def run_websocket_match(args):
    """Run a WebSocket AI match"""
    backend_url = os.getenv('BACKEND_WS_URL', 'ws://backend:8000')
    
    print(f"🔗 Connecting to backend: {backend_url}")
    
    # Create AI clients
    clients = []
    for i, strategy in enumerate(args.strategies):
        client = WebSocketAIClient(
            player_name=f"AI_{i+1}_{strategy}",
            strategy=strategy,
            backend_url=backend_url
        )
        clients.append(client)
    
    match_id = args.match_id or f"ws_test_{len(clients)}players"
    
    try:
        # Connect all clients
        print(f"🤝 Connecting {len(clients)} AI clients...")
        for client in clients:
            success = await client.connect(match_id)
            if not success:
                print(f"❌ Failed to connect {client.player_name}")
                return
        
        print("✅ All clients connected!")
        
        # Start match
        await clients[0].send_message("start_game", {
            "games_to_play": args.games
        })
        
        # Run match with timeout
        print(f"🎮 Running match with {args.games} games...")
        
        # Start listeners
        tasks = [asyncio.create_task(client.listen_for_messages()) for client in clients]
        
        try:
            # Wait for completion (timeout after reasonable time)
            await asyncio.wait_for(
                asyncio.gather(*tasks, return_exceptions=True),
                timeout=args.games * 30  # 30 seconds per game
            )
        except asyncio.TimeoutError:
            print("⏰ Match timed out")
        finally:
            # Cancel tasks and disconnect
            for task in tasks:
                task.cancel()
            
            for client in clients:
                await client.disconnect()
        
        print("🏁 WebSocket match completed!")
        
    except Exception as e:
        print(f"❌ WebSocket match failed: {e}")
        for client in clients:
            if client.is_connected:
                await client.disconnect()

async def run_websocket_batch(args):
    """Run multiple WebSocket matches"""
    print(f"🔄 Running {args.count} WebSocket matches...")
    
    for i in range(args.count):
        print(f"\n--- Match {i+1}/{args.count} ---")
        
        # Create a copy of args for this match
        match_args = argparse.Namespace(**vars(args))
        match_args.match_id = f"batch_{i+1}"
        
        await run_websocket_match(match_args)
        
        if i < args.count - 1:
            print("⏳ Waiting 5 seconds before next match...")
            await asyncio.sleep(5)

def main():
    parser = argparse.ArgumentParser(description="WebSocket AI Testing - Docker Environment")
    parser.add_argument('--log-level', choices=['off', 'info', 'debug'], default='info',
                       help='Logging level (default: info)')
    parser.add_argument('--log-file', type=str, help='Log to file instead of console')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # List strategies
    list_parser = subparsers.add_parser('list', help='List available AI strategies')
    
    # Single match
    match_parser = subparsers.add_parser('match', help='Run a single WebSocket match')
    match_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    match_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    match_parser.add_argument('--match-id', help='Custom match ID')
    
    # Batch matches
    batch_parser = subparsers.add_parser('batch', help='Run multiple WebSocket matches')
    batch_parser.add_argument('strategies', nargs='+', help='AI strategies (2-8)')
    batch_parser.add_argument('--count', type=int, default=3, help='Number of matches (default: 3)')
    batch_parser.add_argument('--games', type=int, default=5, help='Games per match (default: 5)')
    
    args = parser.parse_args()
    
    setup_logging(args.log_level, args.log_file)
    
    print(f"🤖 Loaded AI config: {len(ai_config.tactics)} tactics, {len(ai_config.strategies)} strategies")
    backend_url = os.getenv('BACKEND_WS_URL', 'ws://backend:8000')
    print(f"🌐 Backend URL: {backend_url}")
    
    if args.command == 'list':
        list_strategies()
    elif args.command == 'match':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for a match")
            sys.exit(1)
        asyncio.run(run_websocket_match(args))
    elif args.command == 'batch':
        if len(args.strategies) < 2 or len(args.strategies) > 8:
            print("❌ Error: Need 2-8 strategies for batch testing")
            sys.exit(1)
        asyncio.run(run_websocket_batch(args))
    else:
        parser.print_help()

if __name__ == '__main__':
    main()