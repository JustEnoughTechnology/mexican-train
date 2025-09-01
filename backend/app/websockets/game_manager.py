from typing import Dict, List, Set
from fastapi import WebSocket
import json
import asyncio
from app.game.mexican_train import MexicanTrainGame, MexicanTrainMatch
from app.core.config import settings

class GameManager:
    def __init__(self):
        self.active_matches: Dict[str, MexicanTrainMatch] = {}
        self.game_connections: Dict[str, Set[WebSocket]] = {}  # game_id -> websockets
        self.player_connections: Dict[WebSocket, str] = {}  # websocket -> game_id
        self.user_connections: Dict[str, Set[WebSocket]] = {}  # user_id -> websockets
        self.websocket_users: Dict[WebSocket, str] = {}  # websocket -> user_id
        self.lobby_connections: Set[WebSocket] = set()  # websockets connected to lobby
        self.lobby_users: Dict[WebSocket, str] = {}  # lobby websocket -> user_id
        self.spectator_connections: Dict[str, Set[WebSocket]] = {}  # game_id -> spectator websockets
        self.websocket_spectators: Dict[WebSocket, Tuple[str, str]] = {}  # websocket -> (game_id, spectator_name)
        self.websocket_players: Dict[WebSocket, str] = {}  # websocket -> player_name
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
    
    async def connect(self, websocket: WebSocket, game_id: str, user_id: str = None, display_name: str = None):
        await websocket.accept()
        
        # Auto-create match if it doesn't exist (everything is a match now)
        if game_id not in self.active_matches:
            print(f"Auto-creating match: {game_id}")
            
            # Priority order for getting display name:
            # 1. display_name parameter passed directly to WebSocket
            # 2. Most recent display name from lobby connection
            # 3. Fallback to user_id
            current_display_name = display_name
            
            if user_id:
                print(f"Match connection for user_id: {user_id}, passed display_name: {display_name}")
                
                if not current_display_name:
                    # Check if user has a lobby connection with a display name
                    for ws, user_info in self.lobby_users.items():
                        if isinstance(user_info, dict) and user_info.get("user_id") == user_id:
                            current_display_name = user_info.get("display_name")
                            print(f"Found lobby display name: {current_display_name}")
                            break
            
            # Create a new single-game match with the connecting user as the first player
            player_name = current_display_name or user_id or "Player1"
            print(f"Creating single-game match {game_id} with player: {player_name}")
            players = [player_name]
            # Create a 1-game match as default
            config = {
                "name": f"Quick Game {game_id}",
                "host": player_name,
                "max_players": 4,
                "min_players": 2,
                "allow_spectators": True,
                "ai_enabled": True,
                "ai_skill_level": 2,
                "games_to_play": 1  # Single game match
            }
            self.create_match_with_config(game_id, players, config)
        
        # Track game connections
        if game_id not in self.game_connections:
            self.game_connections[game_id] = set()
        self.game_connections[game_id].add(websocket)
        self.player_connections[websocket] = game_id
        
        # Track user connections (if user_id provided)
        if user_id:
            if user_id not in self.user_connections:
                self.user_connections[user_id] = set()
            self.user_connections[user_id].add(websocket)
            self.websocket_users[websocket] = user_id
        
        # Track player name for this websocket
        player_name = display_name or user_id
        if player_name:
            self.websocket_players[websocket] = player_name
        
        # Send current match state to new connection (everything is a match now)
        if game_id in self.active_matches:
            # Handle match connection
            match = self.active_matches[game_id]
            match_state = match.get_match_state(requesting_player=player_name)
            await websocket.send_json({
                "type": "match_state",
                "data": match_state
            })
            
            # If there's a current game in the match, also send game state
            if match.current_game:
                game_state = match.current_game.get_game_state(requesting_player=player_name)
                await websocket.send_json({
                    "type": "game_state", 
                    "data": game_state
                })
                
                # Check if it's an AI player's turn and trigger their move
                if match.current_game.game_started and match.current_game.get_current_player() in match.current_game.ai_players:
                    print(f"🔄 Reconnection detected - checking for stuck AI turn")
                    import asyncio
                    asyncio.create_task(self.trigger_ai_moves(game_id))
        else:
            # This should never happen since we auto-create matches above
            print(f"Warning: No match found for {game_id} after auto-creation attempt")
            await websocket.send_json({
                "type": "error",
                "message": "Failed to create or find match",
                "game_id": game_id
            })
    
    async def disconnect(self, websocket: WebSocket, game_id: str):
        # Clean up game connections
        if game_id in self.game_connections:
            self.game_connections[game_id].discard(websocket)
            if not self.game_connections[game_id]:
                del self.game_connections[game_id]
        
        # Clean up spectator connections
        if websocket in self.websocket_spectators:
            spectator_game_id, spectator_name = self.websocket_spectators[websocket]
            if spectator_game_id in self.spectator_connections:
                self.spectator_connections[spectator_game_id].discard(websocket)
                if not self.spectator_connections[spectator_game_id]:
                    del self.spectator_connections[spectator_game_id]
            
            # Remove spectator from game
            game = self.active_games.get(spectator_game_id)
            if game:
                game.remove_spectator(spectator_name)
                # Notify players that spectator left
                await self.broadcast_to_game(spectator_game_id, {
                    "type": "spectator_left",
                    "data": {
                        "spectator_name": spectator_name,
                        "spectators": game.spectators,
                        "spectator_count": len(game.spectators)
                    }
                })
            
            del self.websocket_spectators[websocket]
        
        # Clean up player connections
        if websocket in self.player_connections:
            del self.player_connections[websocket]
        
        # Clean up player name mapping
        if websocket in self.websocket_players:
            del self.websocket_players[websocket]
        
        # Clean up user connections
        if websocket in self.websocket_users:
            user_id = self.websocket_users[websocket]
            if user_id in self.user_connections:
                self.user_connections[user_id].discard(websocket)
                if not self.user_connections[user_id]:
                    del self.user_connections[user_id]
            del self.websocket_users[websocket]
    
    async def handle_message(self, websocket: WebSocket, game_id: str, data: dict):
        message_type = data.get("type")
        print(f"\n📨 WebSocket message received: {message_type}")
        print(f"   Game ID: {game_id}")
        print(f"   Data keys: {list(data.keys())}")
        
        if message_type == "make_move":
            await self.handle_move(game_id, data)
        elif message_type == "draw_domino":
            await self.handle_draw(game_id, data)
        elif message_type == "chat_message":
            await self.handle_chat(game_id, data)
        elif message_type == "join_game":
            await self.handle_join_game(websocket, game_id, data)
        elif message_type == "spectate_game":
            await self.handle_spectate_game(websocket, game_id, data)
        elif message_type == "start_game":
            await self.handle_start_game(websocket, game_id, data)
        elif message_type == "get_valid_moves":
            await self.handle_get_valid_moves(websocket, game_id, data)
        elif message_type == "get_all_valid_moves":
            await self.handle_get_all_valid_moves(websocket, game_id, data)
    
    async def handle_move(self, game_id: str, data: dict):
        game = self.active_games.get(game_id)
        if not game:
            return
        
        player_id = data.get("player_id")
        domino_data = data.get("domino")
        train_type = data.get("train_type")
        train_owner = data.get("train_owner")
        
        print(f"Move request: Player {player_id} playing {domino_data} on {train_type} train (owner: {train_owner})")
        
        # Reconstruct domino object
        from app.game.mexican_train import Domino
        domino = Domino(domino_data["left"], domino_data["right"], domino_data["id"])
        
        # Make the move
        result = game.make_move(player_id, domino, train_type, train_owner)
        
        print(f"Move result: {result}")
        
        # Broadcast result to all connected players
        await self.broadcast_to_game(game_id, {
            "type": "move_result",
            "data": result
        })
        
        # If move was successful, broadcast updated game state
        if result.get("success"):
            await self.broadcast_to_game(game_id, {
                "type": "game_state",
                "data": {}  # Will be personalized in broadcast_to_game
            })
            
            # Check if game ended
            if result.get("game_ended"):
                print(f"🎉 Game {game_id} ended! Winner: {result.get('winner')}")
                await self.broadcast_to_game(game_id, {
                    "type": "game_ended",
                    "data": {
                        "winner": result.get("winner"),
                        "final_scores": result.get("final_scores"),
                        "is_match_game": result.get("is_match_game", False),
                        "match_id": result.get("match_id"),
                        "game_number": result.get("game_number", 1)
                    }
                })
                
                # Check if this was part of a match and handle match progression
                if result.get("is_match_game") and result.get("match_id"):
                    match_id = result.get("match_id")
                    match = self.active_matches.get(match_id)
                    if match and match.current_game:
                        # Complete the current game in the match
                        match_result = match.complete_current_game(result.get("final_scores", {}))
                        
                        if match_result.get("match_completed"):
                            print(f"🏆 Match {match_id} completed! Winner: {match_result.get('winner')}")
                            await self.broadcast_to_game(game_id, {
                                "type": "match_ended",
                                "data": {
                                    "winner": match_result.get("winner"),
                                    "final_scores": match_result.get("final_scores"),
                                    "game_history": match_result.get("game_history"),
                                    "total_games": len(match_result.get("game_history", []))
                                }
                            })
            
            # Check if we should trigger AI moves
            elif result.get("should_trigger_ai"):
                # Add a small delay for visual effect
                import asyncio
                await asyncio.sleep(1.5)
                await self.trigger_ai_moves(game_id)
    
    async def handle_draw(self, game_id: str, data: dict):
        game = self.active_games.get(game_id)
        if not game:
            return
        
        player_id = data.get("player_id")
        result = game.draw_from_boneyard(player_id)
        
        # Broadcast draw result
        await self.broadcast_to_game(game_id, {
            "type": "draw_result",
            "data": {
                "success": result["success"],
                "player_id": player_id,
                "domino": result.get("domino") if result["success"] else None,
                "error": result.get("error"),
                "can_play_drawn": result.get("can_play_drawn"),
                "train_opened": result.get("train_opened"),
                "turn_passed": result.get("turn_passed"),
                "next_player": result.get("next_player"),
                "message": result.get("message"),
                "action": result.get("action")
            }
        })
        
        # If draw was successful, broadcast updated game state
        if result.get("success"):
            await self.broadcast_to_game(game_id, {
                "type": "game_state",
                "data": {}  # Will be personalized in broadcast_to_game
            })
            
            # If turn was passed automatically, trigger AI if next player is AI
            if result.get("turn_passed") and result.get("next_player"):
                next_player = result.get("next_player")
                if next_player in game.ai_players:
                    print(f"🤖 Triggering AI move for {next_player} after draw turn pass")
                    # Delay AI move slightly to ensure state is propagated
                    asyncio.create_task(self._delayed_ai_move(game_id, next_player))
    
    async def handle_chat(self, game_id: str, data: dict):
        # Broadcast chat message to all players in the game
        await self.broadcast_to_game(game_id, {
            "type": "chat_message",
            "data": data
        })
    
    async def handle_join_game(self, websocket: WebSocket, game_id: str, data: dict):
        """Handle a player joining an existing game or match"""
        # Check for matches first
        match = self.active_matches.get(game_id)
        game = None
        
        if match:
            # For matches, we need to join the match and potentially start it
            pass  # Handle match joining logic
        else:
            # Check for standalone games (backward compatibility)
            game = self.active_games.get(game_id)
        
        if not game and not match:
            await websocket.send_json({
                "type": "join_result",
                "success": False,
                "error": "Game not found"
            })
            return
        
        player_name = data.get("player_name")
        if not player_name:
            await websocket.send_json({
                "type": "join_result",
                "success": False,
                "error": "Player name is required"
            })
            return
        
        # Check if player is already in the game
        if player_name in game.players:
            # Player is already in the game (e.g., host reconnecting)
            await websocket.send_json({
                "type": "join_result",
                "success": True,
                "message": f"Reconnected to game as {player_name}",
                "already_in_game": True
            })
            
            # Send current game state to the reconnecting player
            game_state = game.get_game_state(requesting_player=player_name)
            await websocket.send_json({
                "type": "game_state",
                "data": game_state
            })
            return
        
        # Try to add the player to the game
        result = game.add_player(player_name)
        
        if result["success"]:
            # Broadcast to all players that someone joined
            await self.broadcast_to_game(game_id, {
                "type": "player_joined",
                "data": {
                    "player_name": player_name,
                    "players": result["players"],
                    "player_count": result["player_count"],
                    "game_started": result.get("game_started", False)
                }
            })
            
            # If game just started, send special notification
            if result.get("game_started", False):
                await self.broadcast_to_game(game_id, {
                    "type": "game_started",
                    "data": {
                        "message": f"Game started with {result['player_count']} players!",
                        "players": result["players"]
                    }
                })
            
            # Send updated game state to all players
            await self.broadcast_to_game(game_id, {
                "type": "game_state",
                "data": {}  # Will be personalized in broadcast_to_game
            })
        
        # Send result back to the joining player
        await websocket.send_json({
            "type": "join_result",
            "success": result["success"],
            "message": result.get("message"),
            "error": result.get("error"),
            "already_in_game": False
        })
    
    async def handle_get_valid_moves(self, websocket: WebSocket, game_id: str, data: dict):
        """Get valid moves for a specific domino"""
        game = self.active_games.get(game_id)
        if not game:
            await websocket.send_json({
                "type": "valid_moves",
                "moves": []
            })
            return
        
        player_name = self.websocket_players.get(websocket)
        if not player_name:
            await websocket.send_json({
                "type": "valid_moves",
                "moves": []
            })
            return
        
        # Get the specific domino from the request
        domino_data = data.get('domino')
        if domino_data:
            # Get valid moves for the specific domino
            from app.game.mexican_train import Domino
            specific_domino = Domino(domino_data['left'], domino_data['right'], domino_data['id'])
            valid_moves = game.get_valid_moves_for_domino(player_name, specific_domino)
        else:
            # Fallback: get valid moves for all dominos
            valid_moves = game.get_valid_moves(player_name)
        
        # Serialize the Domino objects before sending
        serialized_moves = []
        for move in valid_moves:
            serialized_move = {
                "domino": {
                    "left": move["domino"].left,
                    "right": move["domino"].right,
                    "id": move["domino"].id,
                    "isDouble": move["domino"].left == move["domino"].right
                },
                "train": move["train"],
                "train_owner": move["train_owner"]
            }
            serialized_moves.append(serialized_move)
        
        await websocket.send_json({
            "type": "valid_moves",
            "moves": serialized_moves
        })
    
    async def handle_get_all_valid_moves(self, websocket: WebSocket, game_id: str, data: dict):
        """Get all valid moves for a player (checking all their dominos)"""
        game = self.active_games.get(game_id)
        if not game:
            await websocket.send_json({
                "type": "all_valid_moves",
                "moves": [],
                "can_play": False,
                "must_draw": True
            })
            return
        
        player_id = data.get('player_id')
        if not player_id:
            await websocket.send_json({
                "type": "all_valid_moves",
                "moves": [],
                "can_play": False,
                "must_draw": True
            })
            return
        
        # Get all valid moves for this player
        all_valid_moves = game.get_valid_moves(player_id)
        
        # Serialize the moves
        serialized_moves = []
        for move in all_valid_moves:
            serialized_move = {
                "domino": {
                    "left": move["domino"].left,
                    "right": move["domino"].right,
                    "id": move["domino"].id,
                    "isDouble": move["domino"].left == move["domino"].right
                },
                "train": move["train"],
                "train_owner": move["train_owner"]
            }
            serialized_moves.append(serialized_move)
        
        can_play = len(serialized_moves) > 0
        must_draw = not can_play and game.get_current_player() == player_id
        
        await websocket.send_json({
            "type": "all_valid_moves",
            "moves": serialized_moves,
            "can_play": can_play,
            "must_draw": must_draw,
            "message": "No valid moves! You must draw from the boneyard." if must_draw else None
        })
    
    async def handle_start_game(self, websocket: WebSocket, game_id: str, data: dict):
        """Handle host starting the game manually"""
        game = self.active_games.get(game_id)
        if not game:
            await websocket.send_json({
                "type": "start_game_result",
                "success": False,
                "error": "Game not found"
            })
            return
        
        player_name = data.get("player_name")
        force_start = data.get("force", False)
        
        # Verify the requester is the host
        if player_name != game.host:
            await websocket.send_json({
                "type": "start_game_result",
                "success": False,
                "error": "Only the host can start the game"
            })
            return
        
        # Start the game
        result = game.start_game(force_start=force_start)
        
        if result["success"]:
            # Broadcast to all players that the game has started
            await self.broadcast_to_game(game_id, {
                "type": "game_started",
                "data": {
                    "message": "Host has started the game!"
                }
            })
            
            # Also send updated game state
            await self.broadcast_to_game(game_id, {
                "type": "game_state",
                "data": {}  # Will be personalized in broadcast_to_game
            })
            
            # Check if first player is AI and trigger their move
            if game.get_current_player() in game.ai_players:
                import asyncio
                await asyncio.sleep(1.5)
                await self.trigger_ai_moves(game_id)
        
        # Send result back to the host
        await websocket.send_json({
            "type": "start_game_result",
            "success": result["success"],
            "message": result.get("message"),
            "error": result.get("error")
        })
    
    async def handle_spectate_game(self, websocket: WebSocket, game_id: str, data: dict):
        """Handle a spectator joining a game"""
        game = self.active_games.get(game_id)
        if not game:
            await websocket.send_json({
                "type": "spectate_result",
                "success": False,
                "error": "Game not found"
            })
            return
        
        spectator_name = data.get("spectator_name")
        if not spectator_name:
            await websocket.send_json({
                "type": "spectate_result", 
                "success": False,
                "error": "Spectator name is required"
            })
            return
        
        # Try to add the spectator to the game
        result = game.add_spectator(spectator_name)
        
        if result["success"]:
            # Track spectator connection
            if game_id not in self.spectator_connections:
                self.spectator_connections[game_id] = set()
            self.spectator_connections[game_id].add(websocket)
            self.websocket_spectators[websocket] = (game_id, spectator_name)
            
            # Broadcast to all players that someone is spectating
            await self.broadcast_to_game(game_id, {
                "type": "spectator_joined",
                "data": {
                    "spectator_name": spectator_name,
                    "spectators": result["spectators"],
                    "spectator_count": result["spectator_count"]
                }
            })
            
            # Send spectator-safe game state to the new spectator
            spectator_game_state = game.get_spectator_game_state()
            await websocket.send_json({
                "type": "game_state",
                "data": spectator_game_state
            })
        
        # Send result back to the spectator
        await websocket.send_json({
            "type": "spectate_result",
            "success": result["success"],
            "message": result.get("message"),
            "error": result.get("error"),
            "is_spectator": True
        })
    
    async def broadcast_to_game(self, game_id: str, message: dict):
        # Send to players
        if game_id in self.game_connections:
            disconnected = set()
            for websocket in self.game_connections[game_id]:
                try:
                    # For game_state messages, personalize the content
                    if message.get("type") == "game_state":
                        game = self.active_games.get(game_id)
                        player_name = self.websocket_players.get(websocket)
                        if game and player_name:
                            personalized_message = {
                                "type": "game_state", 
                                "data": game.get_game_state(requesting_player=player_name)
                            }
                            await websocket.send_json(personalized_message)
                        else:
                            await websocket.send_json(message)
                    else:
                        await websocket.send_json(message)
                except Exception:
                    disconnected.add(websocket)
            
            # Remove disconnected websockets
            for websocket in disconnected:
                self.game_connections[game_id].discard(websocket)
        
        # Send to spectators (with spectator-safe game state if it's a game_state message)
        if game_id in self.spectator_connections:
            spectator_message = message
            if message.get("type") == "game_state":
                game = self.active_games.get(game_id)
                if game:
                    # Replace with spectator-safe game state
                    spectator_message = {
                        "type": "game_state",
                        "data": game.get_spectator_game_state()
                    }
            
            disconnected_spectators = set()
            for websocket in self.spectator_connections[game_id]:
                try:
                    await websocket.send_json(spectator_message)
                except Exception:
                    disconnected_spectators.add(websocket)
            
            # Remove disconnected spectator websockets
            for websocket in disconnected_spectators:
                self.spectator_connections[game_id].discard(websocket)
    
    def create_match_with_config(self, match_id: str, players: List[str], config: dict) -> MexicanTrainMatch:
        """Create a match with specific configuration options"""
        match = MexicanTrainMatch(match_id, players, config=config)
        self.active_matches[match_id] = match
        return match
    
    def get_match(self, match_id: str) -> MexicanTrainMatch:
        return self.active_matches.get(match_id)
    
    def get_game(self, game_id: str) -> MexicanTrainGame:
        # Everything is a match now - get the current game from the match
        if game_id in self.active_matches:
            match = self.active_matches[game_id]
            return match.current_game
        return None
    
    def get_user_games(self, user_id: str) -> List[str]:
        """Get all game IDs that a user is currently connected to"""
        game_ids = []
        if user_id in self.user_connections:
            for websocket in self.user_connections[user_id]:
                if websocket in self.player_connections:
                    game_id = self.player_connections[websocket]
                    if game_id not in game_ids:
                        game_ids.append(game_id)
        return game_ids
    
    def get_user_connection_count(self, user_id: str) -> int:
        """Get number of active connections for a user"""
        if user_id in self.user_connections:
            return len(self.user_connections[user_id])
        return 0
    
    def is_user_in_game(self, user_id: str, game_id: str) -> bool:
        """Check if user has any connection to a specific game"""
        return game_id in self.get_user_games(user_id)
    
    async def connect_lobby(self, websocket: WebSocket, user_id: str = None, display_name: str = None):
        """Connect a user to the lobby for presence tracking"""
        await websocket.accept()
        
        # Track lobby connections
        self.lobby_connections.add(websocket)
        
        # Track user connections (if user_id provided)
        if user_id:
            if user_id not in self.user_connections:
                self.user_connections[user_id] = set()
            self.user_connections[user_id].add(websocket)
            self.websocket_users[websocket] = user_id
            
            # Store user info with display name
            user_info = {"user_id": user_id, "display_name": display_name or user_id}
            self.lobby_users[websocket] = user_info
        
        # Send welcome message
        await websocket.send_json({
            "type": "lobby_connected",
            "message": "Connected to lobby",
            "user_id": user_id,
            "display_name": display_name
        })
    
    async def disconnect_lobby(self, websocket: WebSocket):
        """Disconnect a user from the lobby"""
        # Clean up lobby connections
        self.lobby_connections.discard(websocket)
        
        # Clean up lobby users
        if websocket in self.lobby_users:
            del self.lobby_users[websocket]
        
        # Clean up user connections
        if websocket in self.websocket_users:
            user_id = self.websocket_users[websocket]
            if user_id in self.user_connections:
                self.user_connections[user_id].discard(websocket)
                if not self.user_connections[user_id]:
                    del self.user_connections[user_id]
            del self.websocket_users[websocket]
    
    async def handle_lobby_message(self, websocket: WebSocket, data: dict):
        """Handle messages from lobby connections"""
        message_type = data.get("type")
        
        if message_type == "ping":
            await websocket.send_json({"type": "pong"})
        elif message_type == "update_status":
            # Handle status updates (could be used for away/busy status later)
            pass
        elif message_type == "update_display_name":
            await self.handle_display_name_update(websocket, data)
        # Add more lobby message types as needed
    
    async def _delayed_ai_move(self, game_id: str, ai_player: str, delay: float = 0.5):
        """Trigger an AI move after a short delay"""
        await asyncio.sleep(delay)
        game = self.active_games.get(game_id)
        if not game:
            return
            
        # Check if it's still this AI's turn
        if game.get_current_player() == ai_player:
            print(f"🤖 Executing delayed AI move for {ai_player}")
            try:
                ai_result = await game.make_ai_move(ai_player)
                
                # Broadcast the AI move result
                await self.broadcast_to_game(game_id, {
                    "type": "ai_move_result",
                    "data": ai_result
                })
                
                # Broadcast updated game state
                await self.broadcast_to_game(game_id, {
                    "type": "game_state", 
                    "data": {}
                })
                
                # Continue triggering AI moves if needed
                if ai_result.get("success") and ai_result.get("should_trigger_ai"):
                    await self.trigger_ai_moves(game_id)
                    
            except Exception as e:
                print(f"❌ Error in delayed AI move for {ai_player}: {e}")
    
    async def trigger_ai_moves(self, game_id: str):
        """Trigger AI players to make their moves"""
        game = self.active_games.get(game_id)
        if not game:
            return
        
        max_attempts = 10  # Prevent infinite loops
        attempts = 0
        
        # Keep making AI moves while it's an AI player's turn
        while game.get_current_player() in game.ai_players and attempts < max_attempts:
            current_ai = game.get_current_player()
            print(f"\n🤖 Triggering AI move for {current_ai} (attempt {attempts + 1})")
            
            try:
                # Make the AI move with timeout
                import asyncio
                ai_result = await asyncio.wait_for(
                    game.make_ai_move(current_ai),
                    timeout=5.0  # 5 second timeout for AI moves
                )
                
                # Broadcast AI move result
                await self.broadcast_to_game(game_id, {
                    "type": "ai_move",
                    "data": {
                        "player": current_ai,
                        "result": ai_result
                    }
                })
                
                # Broadcast updated game state
                await self.broadcast_to_game(game_id, {
                    "type": "game_state",
                    "data": {}  # Will be personalized in broadcast_to_game
                })
                
                # Add a delay between AI moves for visual effect
                await asyncio.sleep(1.5)
                
                # Check if the game ended
                if ai_result.get("game_ended"):
                    print(f"🎉 Game {game_id} ended after AI move! Winner: {ai_result.get('winner')}")
                    await self.broadcast_to_game(game_id, {
                        "type": "game_ended",
                        "data": {
                            "winner": ai_result.get("winner"),
                            "final_scores": ai_result.get("final_scores"),
                            "is_match_game": ai_result.get("is_match_game", False),
                            "match_id": ai_result.get("match_id"),
                            "game_number": ai_result.get("game_number", 1)
                        }
                    })
                    
                    # Check if this was part of a match and handle match progression
                    if ai_result.get("is_match_game") and ai_result.get("match_id"):
                        match_id = ai_result.get("match_id")
                        match = self.active_matches.get(match_id)
                        if match and match.current_game:
                            # Complete the current game in the match
                            match_result = match.complete_current_game(ai_result.get("final_scores", {}))
                            
                            if match_result.get("match_completed"):
                                print(f"🏆 Match {match_id} completed! Winner: {match_result.get('winner')}")
                                await self.broadcast_to_game(game_id, {
                                    "type": "match_ended",
                                    "data": {
                                        "winner": match_result.get("winner"),
                                        "final_scores": match_result.get("final_scores"),
                                        "game_history": match_result.get("game_history"),
                                        "total_games": len(match_result.get("game_history", []))
                                    }
                                })
                    
                    break
                    
            except asyncio.TimeoutError:
                print(f"❌ AI move timeout for {current_ai}")
                # Force pass turn if AI times out
                game.next_turn()
                await self.broadcast_to_game(game_id, {
                    "type": "ai_error",
                    "data": {
                        "player": current_ai,
                        "error": "AI move timed out, passing turn"
                    }
                })
                
                # Broadcast updated game state so players see the turn change
                await self.broadcast_to_game(game_id, {
                    "type": "game_state",
                    "data": {}  # Will be personalized in broadcast_to_game
                })
                break
                
            except Exception as e:
                print(f"❌ AI move error for {current_ai}: {e}")
                # Force pass turn if AI has an error
                game.next_turn()
                await self.broadcast_to_game(game_id, {
                    "type": "ai_error",
                    "data": {
                        "player": current_ai,
                        "error": f"AI error: {str(e)}"
                    }
                })
                
                # Broadcast updated game state so players see the turn change
                await self.broadcast_to_game(game_id, {
                    "type": "game_state",
                    "data": {}  # Will be personalized in broadcast_to_game
                })
                break
            
            attempts += 1
        
        if attempts >= max_attempts:
            print(f"❌ Max AI attempts reached for game {game_id}")
            await self.broadcast_to_game(game_id, {
                "type": "game_error",
                "data": {
                    "error": "AI players stuck in loop, game may need manual intervention"
                }
            })
    
    async def handle_display_name_update(self, websocket: WebSocket, data: dict):
        """Handle display name updates from lobby"""
        user_id = data.get("user_id")
        new_display_name = data.get("new_display_name")
        
        if not user_id or not new_display_name:
            return
        
        print(f"Updating display name for {user_id} to {new_display_name}")
        
        # Update the lobby users mapping for this websocket
        if websocket in self.lobby_users:
            self.lobby_users[websocket] = {
                "user_id": user_id,
                "display_name": new_display_name
            }
        
        # Update any active games where this user is playing
        for game_id, game in self.active_games.items():
            try:
                game_state = game.get_game_state()
                players = game_state.get("players", [])
                
                # Check if this user is in this game
                user_games = self.get_user_games(user_id)
                if game_id in user_games:
                    # Update the player name in the game
                    # This is a simplified approach - in a full implementation,
                    # you'd want to update the actual game state
                    print(f"User {user_id} ({new_display_name}) is in game {game_id}")
                    
            except Exception as e:
                print(f"Error updating game {game_id}: {e}")
        
        # Send confirmation back to the client
        await websocket.send_json({
            "type": "display_name_updated",
            "user_id": user_id,
            "new_display_name": new_display_name
        })

# Global game manager instance
game_manager = GameManager()