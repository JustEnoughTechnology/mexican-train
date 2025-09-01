from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.game import Game, GamePlayer, GameStatus, GameVisibility
from app.models.user import User
from app.schemas.game import CreateGameRequest, JoinGameRequest, GameInfo, PlayerInfo
from app.websockets.game_manager import game_manager
import uuid
import math
import random
from typing import List

router = APIRouter()

@router.get("/info")
async def get_api_info():
    """Get API information including version"""
    return {
        "message": "Mexican Train Domino Game API",
        "version": "0.1.1",
        "status": "running"
    }

@router.get("/list")
async def list_games():
    """Get all available games waiting for players or in progress"""
    
    try:
        # Get active matches and games from game manager
        from app.websockets.game_manager import game_manager
        active_games = []
        
        # First, check for matches (which may contain active games)
        for match_id, match in game_manager.active_matches.items():
            try:
                match_state = match.get_match_state()
                players = match_state.get("players", [])
                
                # Generate a nice match name
                if match_id.isdigit():
                    game_name = f"Match #{match_id}"
                else:
                    game_name = match_state.get("name", f"Match {match_id[:8]}...")
                
                # Convert match to API format
                active_games.append({
                    "id": match_id,
                    "name": game_name,
                    "host": players[0] if players else "Unknown", 
                    "players": len(players),
                    "maxPlayers": match_state.get("max_players", 4),
                    "status": "in-progress" if match_state.get("match_started", False) else "waiting",
                    "type": "match",
                    "current_game": match_state.get("current_game_number", 1),
                    "total_games": match_state.get("games_to_play", 13)
                })
            except Exception as e:
                print(f"Error processing match {match_id}: {e}")
                continue
        
        # No standalone games - everything is a match
        
        return {
            "games": active_games,
            "total": len(active_games),
            "waiting": len([g for g in active_games if g["status"] == "waiting"]),
            "in_progress": len([g for g in active_games if g["status"] == "in-progress"])
        }
        
    except Exception as e:
        print(f"Error in list_games: {e}")
        return {
            "games": [],
            "total": 0,
            "waiting": 0,
            "in_progress": 0,
            "error": str(e)
        }

@router.post("/")
async def create_game(request: CreateGameRequest, db: Session = Depends(get_db)):
    try:
        # Generate a shorter match ID (6 digits should be plenty)
        match_id = str(math.floor(100000 + random.random() * 900000))
        
        # Create the match in the game manager with proper configuration
        host_name = request.host
        players = [host_name] if host_name else []
        
        # Create the match with configuration options
        match = game_manager.create_match_with_config(
            match_id=match_id,
            players=players,
            config={
                "name": request.name,
                "description": request.description or "",
                "host": host_name,
                "max_players": request.max_players,
                "min_players": request.min_players,
                "allow_spectators": request.allow_spectators,
                "visibility": request.visibility,
                "password": request.password if request.password else None,
                "ai_enabled": request.ai_enabled,
                "ai_skill_level": request.ai_skill_level,
                "ai_fill_to_max": request.ai_fill_to_max,
                "countdown_minutes": request.countdown_minutes,
                "games_to_play": request.games_to_play
            }
        )
        
        # Start countdown timer  
        # match.start_countdown()  # TODO: Implement countdown for matches
        
        print(f"Created configured match {match_id}: {request.name} ({request.games_to_play} games)")
        
        return {
            "match_id": match_id,
            "name": request.name,
            "status": "created",
            "host": host_name,
            "max_players": request.max_players,
            "min_players": request.min_players,
            "allow_spectators": request.allow_spectators,
            "ai_enabled": request.ai_enabled,
            "ai_skill_level": request.ai_skill_level,
            "ai_players": match.ai_players,
            "countdown_minutes": request.countdown_minutes,
            "games_to_play": request.games_to_play
        }
        
    except Exception as e:
        print(f"Error creating match: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create match: {str(e)}")

@router.get("/{game_id}")
async def get_match(game_id: str, player_name: str = None):
    match = game_manager.get_match(game_id)
    if not match:
        return {"error": "Match not found"}
    return match.get_match_state(requesting_player=player_name)

@router.post("/{game_id}/start")
async def start_match(game_id: str, host_name: str = None, force: bool = False):
    """Start a match manually as the host
    
    Args:
        game_id: The match ID to start
        host_name: The name of the requesting user (to verify they are the host)
        force: Whether to force start even without minimum players
    """
    match = game_manager.get_match(game_id)
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Verify the requester is the host
    if host_name and match.host != host_name:
        raise HTTPException(status_code=403, detail="Only the host can start the match")
    
    # Start the match
    result = match.start_match()
    
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["error"])
    
    # Broadcast to all players that the match has started
    import asyncio
    asyncio.create_task(game_manager.broadcast_to_game(game_id, {
        "type": "match_started",
        "data": {
            "message": "Host has started the match!",
            "match_state": match.get_match_state()
        }
    }))
    
    return result

@router.post("/{game_id}/join")
async def join_game(game_id: str):
    return {"message": f"Join game {game_id} endpoint - TODO"}

@router.get("/user/{user_id}/active")
async def get_user_active_matches(user_id: str):
    """Get all matches a user is currently connected to"""
    active_match_ids = game_manager.get_user_games(user_id)
    
    # Get detailed match info for each active match
    active_matches = []
    for match_id in active_match_ids:
        match = game_manager.get_match(match_id)
        if match:
            active_matches.append({
                "match_id": match_id,
                "match_state": match.get_match_state(),
                "connection_count": game_manager.get_user_connection_count(user_id)
            })
    
    return {
        "user_id": user_id,
        "active_matches": active_matches,
        "total_connections": game_manager.get_user_connection_count(user_id)
    }