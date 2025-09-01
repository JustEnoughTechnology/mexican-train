"""
WebSocket-based AI Client for Testing
Connects to the backend via WebSocket like a real frontend would
"""

import asyncio
import websockets
import json
import logging
from typing import Dict, List, Optional

# Import with try/catch to handle different execution contexts
try:
    from app.core.ai_config import ai_config
    from app.game.mexican_train import Domino
except ImportError:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from core.ai_config import ai_config
    from game.mexican_train import Domino

class WebSocketAIClient:
    def __init__(self, 
                 player_name: str,
                 strategy: str = "locomotive_legend", 
                 backend_url: str = "ws://localhost:8002"):
        self.player_name = player_name
        self.strategy = strategy
        self.backend_url = backend_url
        self.websocket: Optional[websockets.WebSocketServerProtocol] = None
        self.game_id: Optional[str] = None
        self.game_state = {}
        self.hand = []
        self.is_connected = False
        self.logger = logging.getLogger(f"AIClient.{player_name}")
        
    async def connect(self, game_id: str):
        """Connect to the WebSocket game endpoint"""
        self.game_id = game_id
        ws_url = f"{self.backend_url}/ws/game/{game_id}"
        
        try:
            self.websocket = await websockets.connect(ws_url)
            self.is_connected = True
            self.logger.info(f"Connected to game {game_id}")
            
            # Join the game
            await self.send_message("join_game", {
                "player_name": self.player_name,
                "display_name": self.player_name
            })
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to connect: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from WebSocket"""
        if self.websocket:
            await self.websocket.close()
            self.is_connected = False
            self.logger.info("Disconnected from WebSocket")
    
    async def send_message(self, message_type: str, data: Dict):
        """Send a message to the WebSocket server"""
        if not self.websocket:
            return
        
        message = {
            "type": message_type,
            "data": data
        }
        
        await self.websocket.send(json.dumps(message))
        self.logger.debug(f"Sent {message_type}: {data}")
    
    async def listen_for_messages(self):
        """Listen for messages from the WebSocket server"""
        if not self.websocket:
            return
        
        try:
            async for message in self.websocket:
                try:
                    data = json.loads(message)
                    await self.handle_message(data)
                except json.JSONDecodeError as e:
                    self.logger.error(f"Failed to parse message: {e}")
                    
        except websockets.exceptions.ConnectionClosed:
            self.logger.info("WebSocket connection closed")
            self.is_connected = False
        except Exception as e:
            self.logger.error(f"Error listening for messages: {e}")
            self.is_connected = False
    
    async def handle_message(self, message: Dict):
        """Handle incoming WebSocket messages"""
        message_type = message.get("type")
        data = message.get("data", {})
        
        self.logger.debug(f"Received {message_type}")
        
        if message_type == "game_state":
            await self.handle_game_state(data)
        elif message_type == "move_result":
            await self.handle_move_result(data)
        elif message_type == "draw_result":
            await self.handle_draw_result(data)
        elif message_type == "turn_notification":
            await self.handle_turn_notification(data)
        elif message_type == "game_ended":
            await self.handle_game_ended(data)
        elif message_type == "error":
            self.logger.error(f"Server error: {data}")
    
    async def handle_game_state(self, data: Dict):
        """Handle game state updates"""
        # Extract our hand from the personalized game state
        player_data = data.get("players", {}).get(self.player_name, {})
        hand_data = player_data.get("hand", [])
        
        # Convert hand data back to Domino objects
        self.hand = []
        for domino_data in hand_data:
            domino = Domino(
                domino_data["left"], 
                domino_data["right"], 
                domino_data["id"]
            )
            self.hand.append(domino)
        
        self.game_state = data
        self.logger.debug(f"Updated game state, hand size: {len(self.hand)}")
    
    async def handle_turn_notification(self, data: Dict):
        """Handle turn notifications and make AI moves"""
        current_player = data.get("current_player")
        
        if current_player == self.player_name:
            self.logger.info(f"My turn! Making AI move...")
            await asyncio.sleep(0.5)  # Small delay for realism
            await self.make_ai_move()
    
    async def handle_move_result(self, data: Dict):
        """Handle move results"""
        success = data.get("success", False)
        if data.get("player") == self.player_name:
            if success:
                self.logger.info(f"Move successful!")
            else:
                self.logger.warning(f"Move failed: {data.get('error')}")
    
    async def handle_draw_result(self, data: Dict):
        """Handle draw results"""
        if data.get("player_id") == self.player_name:
            success = data.get("success", False)
            if success:
                domino_data = data.get("domino")
                self.logger.info(f"Drew domino: {domino_data['left']}-{domino_data['right']}")
                
                # Check if we can play the drawn domino
                if data.get("can_play_drawn"):
                    self.logger.info("Can play drawn domino, making move...")
                    await asyncio.sleep(0.5)
                    await self.make_ai_move()
            else:
                self.logger.info(f"Draw failed: {data.get('error')}")
    
    async def handle_game_ended(self, data: Dict):
        """Handle game end"""
        winner = data.get("winner")
        final_scores = data.get("final_scores", {})
        
        my_score = final_scores.get(self.player_name, 0)
        self.logger.info(f"Game ended! Winner: {winner}, My score: {my_score}")
    
    async def make_ai_move(self):
        """Make an AI move using the configured strategy"""
        try:
            # Get valid moves first
            await self.send_message("get_valid_moves", {
                "player_id": self.player_name
            })
            
            # Wait a bit for the response (in real implementation, we'd handle this async)
            await asyncio.sleep(0.2)
            
            # Get valid moves from current game state
            valid_moves = await self.get_valid_moves()
            
            if valid_moves:
                # Use AI strategy to choose the best move
                chosen_move = self.choose_ai_move(valid_moves)
                
                if chosen_move:
                    # Send the move
                    await self.send_message("make_move", {
                        "player_id": self.player_name,
                        "domino": {
                            "left": chosen_move["domino"].left,
                            "right": chosen_move["domino"].right,
                            "id": chosen_move["domino"].id
                        },
                        "train_type": chosen_move["train_type"],
                        "train_owner": chosen_move.get("train_owner")
                    })
                    
                    self.logger.info(f"Played {chosen_move['domino'].left}-{chosen_move['domino'].right} on {chosen_move['train_type']} train")
                else:
                    # No valid moves, try to draw
                    await self.send_message("draw_domino", {
                        "player_id": self.player_name
                    })
                    self.logger.info("No valid moves, drawing from boneyard")
            else:
                # No valid moves, try to draw
                await self.send_message("draw_domino", {
                    "player_id": self.player_name
                })
                self.logger.info("No valid moves available, drawing from boneyard")
                
        except Exception as e:
            self.logger.error(f"Error making AI move: {e}")
    
    async def get_valid_moves(self) -> List[Dict]:
        """Get valid moves from current game state"""
        # This would be extracted from the game state or requested via WebSocket
        # For now, we'll implement a simplified version
        
        if not self.hand:
            return []
        
        valid_moves = []
        
        # Get train information from game state
        trains = self.game_state.get("trains", {})
        current_player = self.game_state.get("current_player")
        
        if current_player != self.player_name:
            return []
        
        # Check each domino in hand against each train
        for domino in self.hand:
            # Check personal train
            personal_train = trains.get(self.player_name, {})
            if self.can_play_on_train(domino, personal_train):
                valid_moves.append({
                    "domino": domino,
                    "train_type": "personal",
                    "train_owner": self.player_name,
                    "train": self.player_name
                })
            
            # Check Mexican train
            mexican_train = trains.get("mexican", {})
            if self.can_play_on_train(domino, mexican_train):
                valid_moves.append({
                    "domino": domino,
                    "train_type": "mexican", 
                    "train_owner": None,
                    "train": "mexican"
                })
            
            # Check other players' trains if they're open
            for train_owner, train_data in trains.items():
                if train_owner != self.player_name and train_owner != "mexican":
                    if train_data.get("is_open", False) and self.can_play_on_train(domino, train_data):
                        valid_moves.append({
                            "domino": domino,
                            "train_type": "personal",
                            "train_owner": train_owner,
                            "train": train_owner
                        })
        
        return valid_moves
    
    def can_play_on_train(self, domino: Domino, train_data: Dict) -> bool:
        """Check if a domino can be played on a train"""
        dominoes = train_data.get("dominoes", [])
        
        if not dominoes:
            # Empty train, check against engine
            engine_value = self.game_state.get("engine_value", 12)  # Default to 12
            return domino.left == engine_value or domino.right == engine_value
        
        # Check against last domino in train
        last_domino = dominoes[-1]
        required_value = last_domino.get("right", last_domino.get("value", 0))
        
        return domino.left == required_value or domino.right == required_value
    
    def choose_ai_move(self, valid_moves: List[Dict]) -> Optional[Dict]:
        """Choose the best move using AI strategy"""
        if not valid_moves:
            return None
        
        # Get strategy configuration
        strategy_config = ai_config.get_strategy_by_name(self.strategy)
        if not strategy_config:
            # Fallback to random choice
            import random
            chosen = random.choice(valid_moves)
            return chosen
        
        # Apply strategy scoring (simplified version of the main game logic)
        return self.apply_strategy_scoring(valid_moves, strategy_config)
    
    def apply_strategy_scoring(self, valid_moves: List[Dict], strategy: Dict) -> Dict:
        """Apply strategy scoring to choose the best move"""
        tactics = strategy.get("tactics", [])
        
        # Initialize scores
        for move in valid_moves:
            move["score"] = 0.0
            move["reason_parts"] = []
        
        # Apply each tactic (simplified)
        for tactic_config in sorted(tactics, key=lambda t: t.get("priority", 999)):
            tactic_name = tactic_config["name"]
            tactic_weight = tactic_config.get("weight", 1.0)
            
            if tactic_name == "prefer_own_train":
                for move in valid_moves:
                    if move["train"] == self.player_name:
                        move["score"] += tactic_weight
                        move["reason_parts"].append(f"own_train({tactic_weight:.1f})")
            
            elif tactic_name == "prefer_mexican_train":
                for move in valid_moves:
                    if move["train"] == "mexican":
                        move["score"] += tactic_weight
                        move["reason_parts"].append(f"mexican({tactic_weight:.1f})")
            
            elif tactic_name == "maximize_pips":
                if valid_moves:
                    max_pips = max(move["domino"].value() for move in valid_moves)
                    for move in valid_moves:
                        pip_score = (move["domino"].value() / max_pips) * tactic_weight if max_pips > 0 else 0
                        move["score"] += pip_score
                        if pip_score > 0:
                            move["reason_parts"].append(f"max_pips({move['domino'].value()})")
        
        # Choose highest scoring move
        best_move = max(valid_moves, key=lambda m: m["score"])
        reason_text = f"{strategy.get('name', 'Unknown')}: " + ", ".join(best_move["reason_parts"])
        best_move["reason"] = reason_text
        
        self.logger.info(f"Chose move: {best_move['reason']}")
        
        return best_move