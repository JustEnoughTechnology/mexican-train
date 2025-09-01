"""
API-Consistent AI Testing Framework
Uses the same GameManager and message handling paths as the real WebSocket connections
This ensures AI testing uses identical code paths to the frontend
"""

import asyncio
import json
import time
import uuid
import logging
import sys
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

# Add app to path for Docker environment
sys.path.insert(0, '/app')

from app.websockets.game_manager import GameManager
from app.core.ai_config import ai_config
from app.game.mexican_train import Domino

class MockWebSocket:
    """Mock WebSocket for testing that captures sent messages"""
    def __init__(self, player_name: str):
        self.player_name = player_name
        self.messages_received = []
        self.connected = True
        
    async def accept(self):
        """Mock accept method for WebSocket interface"""
        pass
        
    async def send(self, message: str):
        """Capture sent messages for analysis"""
        try:
            data = json.loads(message)
            self.messages_received.append(data)
        except json.JSONDecodeError:
            pass
    
    async def send_text(self, message: str):
        """Mock send_text method"""
        await self.send(message)
    
    async def send_json(self, data: dict):
        """Mock send_json method"""
        self.messages_received.append(data)
    
    async def close(self):
        """Mock close method"""
        self.connected = False

class APIConsistentAIRunner:
    """
    AI Testing Framework that uses the same GameManager and message handlers
    as real WebSocket connections, ensuring identical code paths
    """
    
    def __init__(self, results_dir: str = "api_consistent_results"):
        self.results_dir = Path(results_dir)
        self.results_dir.mkdir(exist_ok=True)
        self.current_session_id = None
        self.logger = logging.getLogger("APIConsistentAIRunner")
        self.game_manager = GameManager()
        
    def create_test_session(self, description: str = "") -> str:
        """Create a new testing session"""
        self.current_session_id = f"api_session_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        session_info = {
            "session_id": self.current_session_id,
            "created_at": datetime.now().isoformat(),
            "description": description,
            "testing_method": "api_consistent",
            "matches": []
        }
        
        session_file = self.results_dir / f"{self.current_session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_info, f, indent=2)
        
        self.logger.info(f"Created API-consistent test session: {self.current_session_id}")
        return self.current_session_id
    
    async def run_single_match(
        self, 
        ai_configs: List[Dict[str, any]], 
        games_to_play: int = 13,
        match_id: str = None
    ) -> Dict:
        """Run a single AI match using the same GameManager code paths as WebSocket"""
        
        if not match_id:
            match_id = f"api_match_{uuid.uuid4().hex[:8]}"
        
        self.logger.info(f"Starting API-consistent match {match_id}")
        
        # Create mock WebSocket connections for each AI player
        mock_websockets = {}
        player_strategies = {}
        
        for config in ai_configs:
            player_name = config.get("name", f"AI_{len(mock_websockets)+1}")
            strategy = config.get("strategy", "locomotive_legend")
            
            mock_ws = MockWebSocket(player_name)
            mock_websockets[player_name] = mock_ws
            player_strategies[player_name] = strategy
            
            # Connect through GameManager using the same path as real connections
            await self.game_manager.connect(mock_ws, match_id, user_id=player_name, display_name=player_name)
            
            # Join game using the same message handler as WebSocket
            join_message = {
                "type": "join_game",
                "data": {
                    "player_name": player_name,
                    "display_name": player_name
                }
            }
            await self.game_manager.handle_message(mock_ws, match_id, join_message)
        
        # Start the game using the same message handler
        start_message = {
            "type": "start_game", 
            "data": {
                "games_to_play": games_to_play,
                "max_players": len(ai_configs)
            }
        }
        
        first_player = list(mock_websockets.keys())[0]
        await self.game_manager.handle_message(mock_websockets[first_player], match_id, start_message)
        
        match_start_time = time.time()
        
        # Run the match using AI automation
        match_results = await self.run_automated_match(match_id, mock_websockets, player_strategies)
        
        match_duration = time.time() - match_start_time
        
        # Get final game state from GameManager
        game = self.game_manager.active_games.get(match_id)
        match_obj = self.game_manager.active_matches.get(match_id)
        
        if match_obj:
            final_state = match_obj.get_match_state()
        elif game:
            final_state = game.get_game_state()
        else:
            final_state = {"error": "No game or match found"}
        
        # Determine winner
        match_winner = final_state.get("winner") or final_state.get("match_winner")
        if not match_winner and "match_scores" in final_state:
            scores = final_state["match_scores"]
            match_winner = min(scores.keys(), key=lambda p: scores[p]) if scores else None
        
        # Build results in same format as original runner
        result = {
            "match_id": match_id,
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": round(match_duration, 2),
            "games_played": final_state.get("games_played", games_to_play),
            "games_to_play": games_to_play,
            "testing_method": "api_consistent",
            "players": {},
            "winner": match_winner,
            "game_results": final_state.get("game_results", []),
            "match_completed": final_state.get("match_completed", True),
            "final_state": final_state
        }
        
        # Collect player statistics
        for player_name, strategy in player_strategies.items():
            player_data = {
                "strategy": strategy,
                "total_score": final_state.get("match_scores", {}).get(player_name, 0),
                "games_won": len([g for g in result["game_results"] if g.get("winner") == player_name]),
                "average_game_score": 0,
                "best_game_score": 0,
                "worst_game_score": 0,
                "messages_received": len(mock_websockets[player_name].messages_received)
            }
            
            # Calculate per-game statistics
            player_scores = [g.get("scores", {}).get(player_name, 0) for g in result["game_results"]]
            if player_scores:
                import statistics
                player_data["average_game_score"] = round(statistics.mean(player_scores), 1)
                player_data["best_game_score"] = min(player_scores)
                player_data["worst_game_score"] = max(player_scores)
            
            result["players"][player_name] = player_data
        
        # Disconnect all mock connections
        for mock_ws in mock_websockets.values():
            await self.game_manager.disconnect(mock_ws, match_id)
        
        self.logger.info(f"API-consistent match completed in {match_duration:.1f}s - Winner: {match_winner}")
        
        return result
    
    async def run_automated_match(
        self, 
        match_id: str, 
        mock_websockets: Dict[str, MockWebSocket], 
        player_strategies: Dict[str, str]
    ) -> Dict:
        """Run the match with AI automation using GameManager message handlers"""
        
        max_turns = 2000  # Safety limit
        turn_count = 0
        last_activity_time = time.time()
        
        while turn_count < max_turns:
            # Get current game from GameManager
            game = self.game_manager.active_games.get(match_id)
            match_obj = self.game_manager.active_matches.get(match_id)
            
            if not game and not match_obj:
                self.logger.info("No active game or match found - ending")
                break
            
            # Check if match is complete
            if match_obj and match_obj.is_match_complete():
                self.logger.info("Match is complete")
                break
                
            if game and game.is_game_over():
                # Game is over, but match might continue
                if not match_obj or match_obj.is_match_complete():
                    self.logger.info("Game over and match complete")
                    break
            
            # Get current player
            current_player = None
            if game:
                current_player = game.get_current_player()
            
            if not current_player:
                # No current player - check if we need to start next game
                await asyncio.sleep(0.1)
                turn_count += 1
                continue
            
            # Get strategy for current player
            strategy = player_strategies.get(current_player, "locomotive_legend")
            mock_ws = mock_websockets.get(current_player)
            
            if not mock_ws:
                self.logger.warning(f"No mock websocket for player {current_player}")
                break
            
            # Make AI move using the same message handlers as real WebSocket
            await self.make_ai_move_via_messages(game, match_id, current_player, strategy, mock_ws)
            
            turn_count += 1
            last_activity_time = time.time()
            
            # Small delay to prevent tight loops
            await asyncio.sleep(0.01)
        
        if turn_count >= max_turns:
            self.logger.warning(f"Match reached turn limit ({max_turns})")
        
        return {"turns_taken": turn_count, "success": True}
    
    async def make_ai_move_via_messages(
        self, 
        game, 
        match_id: str, 
        player_name: str, 
        strategy: str, 
        mock_ws: MockWebSocket
    ):
        """Make an AI move using the same WebSocket message handlers"""
        
        # Get valid moves using game's method (same as WebSocket handler would)
        valid_moves = game.get_valid_moves(player_name)
        
        if valid_moves:
            # Use AI strategy to choose move (same logic as original game)
            chosen_move = self.choose_ai_move(game, player_name, valid_moves, strategy)
            
            if chosen_move:
                domino = chosen_move["domino"]
                train_name = chosen_move["train"]
                
                # Convert to message format expected by WebSocket handler
                move_message = {
                    "type": "make_move",
                    "data": {
                        "player_id": player_name,
                        "domino": {
                            "left": domino.left,
                            "right": domino.right,
                            "id": domino.id
                        },
                        "train_type": self.get_train_type(train_name, player_name),
                        "train_owner": self.get_train_owner(train_name, player_name)
                    }
                }
                
                # Send through GameManager message handler (same path as WebSocket)
                await self.game_manager.handle_message(mock_ws, match_id, move_message)
                
            else:
                # No valid move found, try to draw using message handler
                draw_message = {
                    "type": "draw_domino",
                    "data": {
                        "player_id": player_name
                    }
                }
                
                await self.game_manager.handle_message(mock_ws, match_id, draw_message)
        else:
            # No valid moves, try to draw using message handler
            draw_message = {
                "type": "draw_domino",
                "data": {
                    "player_id": player_name
                }
            }
            
            await self.game_manager.handle_message(mock_ws, match_id, draw_message)
    
    def choose_ai_move(self, game, player_name: str, valid_moves: List[Dict], strategy: str) -> Optional[Dict]:
        """Choose AI move using the same logic as the main game"""
        # This delegates to the game's existing AI move logic
        return game._choose_ai_move(player_name, valid_moves)
    
    def get_train_type(self, train_name: str, player_name: str) -> str:
        """Convert train name to train_type for message"""
        if train_name == "mexican":
            return "mexican"
        else:
            return "personal"
    
    def get_train_owner(self, train_name: str, player_name: str) -> Optional[str]:
        """Convert train name to train_owner for message"""
        if train_name == "mexican":
            return None
        else:
            return train_name  # Could be player_name or another player
    
    def save_match_result(self, match_result: Dict) -> None:
        """Save match result to session"""
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
        
        self.logger.info(f"Saved API-consistent match result to session {self.current_session_id}")