from fastapi import APIRouter
from app.websockets.game_manager import game_manager
import uuid

router = APIRouter()

@router.get("/")
async def list_games():
    games = []
    for game_id, game in game_manager.active_games.items():
        game_state = game.get_game_state()
        games.append({
            "id": game_id,
            "name": f"Game {game_id[:8]}",  # Short ID for display
            "host": game_state.get("players", ["Unknown"])[0] if game_state.get("players") else "Unknown",
            "players": len(game_state.get("players", [])),
            "maxPlayers": 4,  # TODO: Make configurable
            "status": "waiting" if not game_state.get("started", False) else "in-progress"
        })
    return {"games": games}

@router.post("/")
async def create_game():
    game_id = str(uuid.uuid4())
    players = ["Alice", "Bob"]  # TODO: Get from request body
    game = game_manager.create_game(game_id, players)
    return {
        "game_id": game_id,
        "players": players,
        "status": "created"
    }

@router.get("/{game_id}")
async def get_game(game_id: str):
    game = game_manager.get_game(game_id)
    if not game:
        return {"error": "Game not found"}
    return game.get_game_state()

@router.post("/{game_id}/join")
async def join_game(game_id: str):
    return {"message": f"Join game {game_id} endpoint - TODO"}