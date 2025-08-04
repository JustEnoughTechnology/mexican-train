from typing import Dict, List, Set
from fastapi import WebSocket
import json
import asyncio
from app.game.mexican_train import MexicanTrainGame
from app.core.config import settings

class GameManager:
    def __init__(self):
        self.active_games: Dict[str, MexicanTrainGame] = {}
        self.game_connections: Dict[str, Set[WebSocket]] = {}
        self.player_connections: Dict[WebSocket, str] = {}
        # TODO: Add Redis connection when Docker is available
        # self.redis = None
    
    async def initialize(self):
        # TODO: Initialize Redis connection when Docker is available
        # self.redis = redis.from_url(settings.redis_url)
        pass
    
    async def cleanup(self):
        # TODO: Close Redis connection when available
        # if self.redis:
        #     await self.redis.close()
        pass
    
    async def connect(self, websocket: WebSocket, game_id: str):
        await websocket.accept()
        
        if game_id not in self.game_connections:
            self.game_connections[game_id] = set()
        
        self.game_connections[game_id].add(websocket)
        self.player_connections[websocket] = game_id
        
        # Send current game state to new connection
        if game_id in self.active_games:
            game_state = self.active_games[game_id].get_game_state()
            await websocket.send_json({
                "type": "game_state",
                "data": game_state
            })
    
    async def disconnect(self, websocket: WebSocket, game_id: str):
        if game_id in self.game_connections:
            self.game_connections[game_id].discard(websocket)
            if not self.game_connections[game_id]:
                del self.game_connections[game_id]
        
        if websocket in self.player_connections:
            del self.player_connections[websocket]
    
    async def handle_message(self, websocket: WebSocket, game_id: str, data: dict):
        message_type = data.get("type")
        
        if message_type == "make_move":
            await self.handle_move(game_id, data)
        elif message_type == "draw_domino":
            await self.handle_draw(game_id, data)
        elif message_type == "chat_message":
            await self.handle_chat(game_id, data)
    
    async def handle_move(self, game_id: str, data: dict):
        game = self.active_games.get(game_id)
        if not game:
            return
        
        player_id = data.get("player_id")
        domino_data = data.get("domino")
        train_type = data.get("train_type")
        train_owner = data.get("train_owner")
        
        # Reconstruct domino object
        from app.game.mexican_train import Domino
        domino = Domino(domino_data["left"], domino_data["right"], domino_data["id"])
        
        # Make the move
        result = game.make_move(player_id, domino, train_type, train_owner)
        
        # Broadcast result to all connected players
        await self.broadcast_to_game(game_id, {
            "type": "move_result",
            "data": result
        })
    
    async def handle_draw(self, game_id: str, data: dict):
        game = self.active_games.get(game_id)
        if not game:
            return
        
        player_id = data.get("player_id")
        result = game.draw_from_boneyard(player_id)
        
        # Broadcast to all players (but domino details only to the drawing player)
        await self.broadcast_to_game(game_id, {
            "type": "draw_result",
            "data": {
                "success": result["success"],
                "player_id": player_id,
                "error": result.get("error")
            }
        })
    
    async def handle_chat(self, game_id: str, data: dict):
        # Broadcast chat message to all players in the game
        await self.broadcast_to_game(game_id, {
            "type": "chat_message",
            "data": data
        })
    
    async def broadcast_to_game(self, game_id: str, message: dict):
        if game_id not in self.game_connections:
            return
        
        disconnected = set()
        for websocket in self.game_connections[game_id]:
            try:
                await websocket.send_json(message)
            except Exception:
                disconnected.add(websocket)
        
        # Remove disconnected websockets
        for websocket in disconnected:
            self.game_connections[game_id].discard(websocket)
    
    def create_game(self, game_id: str, players: List[str]) -> MexicanTrainGame:
        game = MexicanTrainGame(game_id, players)
        self.active_games[game_id] = game
        return game
    
    def get_game(self, game_id: str) -> MexicanTrainGame:
        return self.active_games.get(game_id)

# Global game manager instance
game_manager = GameManager()