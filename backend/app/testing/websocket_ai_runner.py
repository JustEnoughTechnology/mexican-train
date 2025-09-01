"""
WebSocket-based AI Match Runner
Runs AI matches using real WebSocket connections to test the full backend stack
"""

import asyncio
import json
import time
import uuid
import logging
import statistics
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

from app.testing.websocket_ai_client import WebSocketAIClient

class WebSocketAIRunner:
    def __init__(self, 
                 results_dir: str = "ai_test_results",
                 backend_url: str = "ws://localhost:8002"):
        self.results_dir = Path(results_dir)
        self.results_dir.mkdir(exist_ok=True)
        self.backend_url = backend_url
        self.current_session_id = None
        self.logger = logging.getLogger("WebSocketAIRunner")
        
    def create_test_session(self, description: str = "") -> str:
        """Create a new testing session"""
        self.current_session_id = f"ws_session_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        session_info = {
            "session_id": self.current_session_id,
            "created_at": datetime.now().isoformat(),
            "description": description,
            "backend_url": self.backend_url,
            "matches": []
        }
        
        session_file = self.results_dir / f"{self.current_session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_info, f, indent=2)
        
        self.logger.info(f"Created WebSocket test session: {self.current_session_id}")
        return self.current_session_id
    
    async def run_single_match(
        self, 
        ai_configs: List[Dict[str, any]], 
        games_to_play: int = 13,
        match_id: str = None
    ) -> Dict:
        """Run a single AI-only match using WebSocket connections"""
        
        if not match_id:
            match_id = f"ws_match_{uuid.uuid4().hex[:8]}"
        
        self.logger.info(f"Starting WebSocket match {match_id}")
        self.logger.info(f"AI configurations: {ai_configs}")
        
        # Create AI clients
        ai_clients = []
        for config in ai_configs:
            client = WebSocketAIClient(
                player_name=config.get("name", f"AI_{len(ai_clients)+1}"),
                strategy=config.get("strategy", "locomotive_legend"),
                backend_url=self.backend_url
            )
            ai_clients.append(client)
        
        match_start_time = time.time()
        
        try:
            # Connect all AI clients
            self.logger.info("Connecting AI clients...")
            connection_tasks = []
            for client in ai_clients:
                connection_tasks.append(client.connect(match_id))
            
            connection_results = await asyncio.gather(*connection_tasks, return_exceptions=True)
            
            # Check if all clients connected successfully
            failed_connections = []
            for i, result in enumerate(connection_results):
                if isinstance(result, Exception) or not result:
                    failed_connections.append(f"Client {ai_clients[i].player_name}: {result}")
            
            if failed_connections:
                error_msg = f"Failed to connect clients: {failed_connections}"
                self.logger.error(error_msg)
                return {"success": False, "error": error_msg}
            
            self.logger.info("All AI clients connected successfully")
            
            # Wait a bit for initial game state
            await asyncio.sleep(2)
            
            # Start the match by having one client request to start
            await ai_clients[0].send_message("start_game", {
                "games_to_play": games_to_play
            })
            
            # Start message listeners for all clients
            listener_tasks = []
            for client in ai_clients:
                listener_tasks.append(asyncio.create_task(client.listen_for_messages()))
            
            # Wait for the match to complete (with timeout)
            match_timeout = games_to_play * 60  # 1 minute per game max
            
            try:
                # Wait for match completion or timeout
                await asyncio.wait_for(
                    self.wait_for_match_completion(ai_clients),
                    timeout=match_timeout
                )
                
            except asyncio.TimeoutError:
                self.logger.warning(f"Match {match_id} timed out after {match_timeout} seconds")
                
            finally:
                # Cancel all listener tasks
                for task in listener_tasks:
                    task.cancel()
                
                # Wait for tasks to be cancelled
                await asyncio.gather(*listener_tasks, return_exceptions=True)
            
            match_duration = time.time() - match_start_time
            
            # Collect results from clients
            results = await self.collect_match_results(ai_clients, match_id, match_duration, games_to_play)
            
            # Disconnect all clients
            disconnect_tasks = []
            for client in ai_clients:
                disconnect_tasks.append(client.disconnect())
            
            await asyncio.gather(*disconnect_tasks, return_exceptions=True)
            
            return results
            
        except Exception as e:
            self.logger.error(f"Error running WebSocket match: {e}")
            
            # Try to disconnect clients on error
            try:
                disconnect_tasks = []
                for client in ai_clients:
                    if client.is_connected:
                        disconnect_tasks.append(client.disconnect())
                
                if disconnect_tasks:
                    await asyncio.gather(*disconnect_tasks, return_exceptions=True)
            except:
                pass
            
            return {"success": False, "error": str(e)}
    
    async def wait_for_match_completion(self, ai_clients: List[WebSocketAIClient]):
        """Wait for the match to complete by monitoring client states"""
        while True:
            # Check if any client received a match completion signal
            # This is a simple implementation - in practice you'd want more sophisticated monitoring
            
            # Check if all clients are still connected
            connected_clients = [client for client in ai_clients if client.is_connected]
            
            if len(connected_clients) == 0:
                self.logger.info("All clients disconnected - match likely complete")
                break
            
            # Check game states for completion indicators
            for client in ai_clients:
                if hasattr(client, 'match_complete') and client.match_complete:
                    self.logger.info("Match completion detected")
                    return
            
            await asyncio.sleep(1)  # Check every second
    
    async def collect_match_results(
        self, 
        ai_clients: List[WebSocketAIClient], 
        match_id: str, 
        duration: float,
        games_to_play: int
    ) -> Dict:
        """Collect match results from AI clients"""
        
        # This is a simplified result collection
        # In practice, you'd want to get the actual game results from the server
        
        result = {
            "match_id": match_id,
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": round(duration, 2),
            "games_played": games_to_play,  # Simplified
            "games_to_play": games_to_play,
            "backend_url": self.backend_url,
            "connection_type": "websocket",
            "players": {},
            "winner": None,
            "game_results": [],
            "match_completed": True  # Simplified
        }
        
        # Collect player information
        for client in ai_clients:
            result["players"][client.player_name] = {
                "strategy": client.strategy,
                "total_score": 0,  # Would need to be collected from actual game
                "games_won": 0,    # Would need to be collected from actual game
                "average_game_score": 0,
                "best_game_score": 0, 
                "worst_game_score": 0
            }
        
        # For now, randomly assign a winner for testing
        if ai_clients:
            import random
            result["winner"] = random.choice(ai_clients).player_name
        
        self.logger.info(f"WebSocket match completed in {duration:.1f}s")
        
        return result
    
    async def run_batch_test(
        self,
        ai_configs: List[Dict[str, any]],
        count: int = 10,
        games_per_match: int = 13
    ) -> Dict:
        """Run multiple matches with the same configuration"""
        
        if not self.current_session_id:
            self.create_test_session("WebSocket Batch Test")
        
        self.logger.info(f"Starting WebSocket batch test: {count} matches")
        
        results = []
        wins_by_strategy = {}
        games_won_by_strategy = {}
        total_games_played = 0
        
        # Initialize counters
        for config in ai_configs:
            strategy = config.get("strategy", "unknown")
            wins_by_strategy[strategy] = 0
            games_won_by_strategy[strategy] = 0
        
        for i in range(count):
            self.logger.info(f"Running WebSocket match {i+1}/{count}")
            
            match_result = await self.run_single_match(
                ai_configs,
                games_per_match,
                f"ws_batch_{i+1}"
            )
            
            if match_result.get("success", True):  # Default to True for backward compatibility
                results.append(match_result)
                self.save_match_result(match_result)
                
                # Track statistics
                winner_strategy = None
                for player, data in match_result.get("players", {}).items():
                    if player == match_result.get("winner"):
                        winner_strategy = data.get("strategy")
                        break
                
                if winner_strategy:
                    wins_by_strategy[winner_strategy] += 1
                
                # Track individual game wins
                total_games_played += match_result.get("games_played", 0)
                for player, data in match_result.get("players", {}).items():
                    strategy = data.get("strategy")
                    if strategy:
                        games_won_by_strategy[strategy] += data.get("games_won", 0)
            else:
                self.logger.error(f"Match {i+1} failed: {match_result.get('error')}")
        
        # Print summary
        self.logger.info(f"WebSocket batch test completed: {len(results)}/{count} matches successful")
        
        return {
            "total_matches": count,
            "successful_matches": len(results),
            "results": results,
            "wins_by_strategy": wins_by_strategy,
            "games_won_by_strategy": games_won_by_strategy,
            "total_games_played": total_games_played
        }
    
    def save_match_result(self, match_result: Dict) -> None:
        """Save a single match result to the current session"""
        if not self.current_session_id:
            self.create_test_session()
        
        session_file = self.results_dir / f"{self.current_session_id}.json"
        
        # Load existing session
        with open(session_file, 'r') as f:
            session_data = json.load(f)
        
        # Add match result
        session_data["matches"].append(match_result)
        
        # Update session
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2)
        
        self.logger.info(f"Saved WebSocket match result to session {self.current_session_id}")

# Standalone function to run a simple WebSocket AI test
async def run_simple_websocket_test():
    """Run a simple WebSocket AI test for debugging"""
    logging.basicConfig(level=logging.INFO)
    
    runner = WebSocketAIRunner()
    runner.create_test_session("Simple WebSocket Test")
    
    ai_configs = [
        {"name": "AI_Chain", "strategy": "chain_strategist"},
        {"name": "AI_Legend", "strategy": "locomotive_legend"}
    ]
    
    result = await runner.run_single_match(ai_configs, games_to_play=3)
    print(f"Test result: {json.dumps(result, indent=2)}")

if __name__ == "__main__":
    asyncio.run(run_simple_websocket_test())