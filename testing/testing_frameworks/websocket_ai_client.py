"""
WebSocket AI Client - Docker Environment Version
Connects to backend via WebSocket for realistic testing
"""

import asyncio
import websockets
import json
import logging
import sys
from typing import Dict, List, Optional

# Add app to path
sys.path.insert(0, '/app')

from app.core.ai_config import ai_config
from app.game.mexican_train import Domino

class WebSocketAIClient:
    def __init__(self, 
                 player_name: str,
                 strategy: str = "locomotive_legend", 
                 backend_url: str = "ws://backend:8000"):
        self.player_name = player_name
        self.strategy = strategy
        self.backend_url = backend_url
        self.websocket: Optional[websockets.WebSocketServerProtocol] = None
        self.game_id: Optional[str] = None
        self.is_connected = False
        self.logger = logging.getLogger(f"WSClient.{player_name}")
        self.match_complete = False
        
    async def connect(self, game_id: str) -> bool:
        """Connect to WebSocket game endpoint"""
        self.game_id = game_id
        ws_url = f"{self.backend_url}/ws/game/{game_id}"
        
        try:
            self.logger.info(f"Connecting to {ws_url}")
            self.websocket = await websockets.connect(
                ws_url,
                timeout=10,
                ping_timeout=10
            )
            self.is_connected = True
            
            # Join the game
            await self.send_message("join_game", {
                "player_name": self.player_name,
                "display_name": self.player_name
            })
            
            self.logger.info(f"Connected to game {game_id}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to connect: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from WebSocket"""
        if self.websocket:
            try:
                await self.websocket.close()
            except:
                pass
        self.is_connected = False
        self.logger.info("Disconnected")
    
    async def send_message(self, message_type: str, data: Dict):
        """Send message to WebSocket server"""
        if not self.websocket:
            return
        
        message = {
            "type": message_type,
            "data": data
        }
        
        try:
            await self.websocket.send(json.dumps(message))
            self.logger.debug(f"Sent {message_type}")
        except Exception as e:
            self.logger.error(f"Failed to send message: {e}")
    
    async def listen_for_messages(self):
        """Listen for WebSocket messages"""
        if not self.websocket:
            return
        
        try:
            async for message in self.websocket:
                try:
                    data = json.loads(message)
                    await self.handle_message(data)
                    
                    if self.match_complete:
                        break
                        
                except json.JSONDecodeError as e:
                    self.logger.error(f"Failed to parse message: {e}")
                    
        except websockets.exceptions.ConnectionClosed:
            self.logger.info("WebSocket connection closed")
            self.is_connected = False
        except Exception as e:
            self.logger.error(f"Error in message listener: {e}")
            self.is_connected = False
    
    async def handle_message(self, message: Dict):
        """Handle incoming WebSocket messages"""
        message_type = message.get("type")
        data = message.get("data", {})
        
        self.logger.debug(f"Received {message_type}")
        
        if message_type == "turn_notification":
            current_player = data.get("current_player")
            if current_player == self.player_name:
                self.logger.info("🎯 My turn! Making AI move...")
                await asyncio.sleep(1)  # Realistic delay
                await self.make_basic_ai_move()
                
        elif message_type == "game_ended":
            winner = data.get("winner")
            self.logger.info(f"🏁 Game ended! Winner: {winner}")
            
        elif message_type == "match_ended":
            winner = data.get("winner") 
            self.logger.info(f"🎉 Match ended! Winner: {winner}")
            self.match_complete = True
            
        elif message_type == "move_result":
            success = data.get("success", False)
            if data.get("player") == self.player_name:
                if success:
                    self.logger.info("✅ Move successful")
                else:
                    self.logger.warning(f"❌ Move failed: {data.get('error')}")
                    
        elif message_type == "draw_result":
            if data.get("player_id") == self.player_name:
                success = data.get("success", False)
                if success:
                    self.logger.info("🎲 Drew domino successfully")
                else:
                    self.logger.info("🎲 Draw failed (probably no dominoes left)")
                    
        elif message_type == "error":
            self.logger.error(f"❌ Server error: {data}")
    
    async def make_basic_ai_move(self):
        """Make a basic AI move (simplified for WebSocket testing)"""
        try:
            # For WebSocket testing, we'll use a simple approach
            # Real implementation would get valid moves and apply strategy
            
            # Try to make a move (this is simplified - real version would be more complex)
            await self.send_message("get_valid_moves", {
                "player_id": self.player_name
            })
            
            # Wait a bit then try a basic move or draw
            await asyncio.sleep(0.5)
            
            # For now, just try to draw (in real implementation we'd make strategic moves)
            await self.send_message("draw_domino", {
                "player_id": self.player_name
            })
            
        except Exception as e:
            self.logger.error(f"❌ Error making AI move: {e}")

# Simple test function
async def test_websocket_connection():
    """Test WebSocket connection"""
    client = WebSocketAIClient("TestPlayer", "locomotive_legend", "ws://backend:8000")
    
    success = await client.connect("test123")
    if success:
        print("✅ WebSocket connection test successful!")
        await client.disconnect()
        return True
    else:
        print("❌ WebSocket connection test failed!")
        return False

if __name__ == "__main__":
    asyncio.run(test_websocket_connection())