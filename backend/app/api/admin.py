from fastapi import APIRouter, HTTPException
from typing import Dict, List
import time
from app.websockets.game_manager import game_manager

import psutil

router = APIRouter()

@router.get("/dashboard")
async def get_admin_dashboard():
    """Get comprehensive server statistics for admin dashboard"""
    
    # Game statistics
    active_games = len(game_manager.active_games)
    games_in_progress = 0
    games_waiting = 0
    total_players = 0
    total_spectators = 0
    ai_players = 0
    
    games_list = []
    for game_id, game in game_manager.active_games.items():
        game_info = {
            "game_id": game_id,
            "player_count": len(game.players),
            "spectator_count": len(game.spectators),
            "started": game.game_started,
            "current_player": game.get_current_player() if game.game_started else None,
            "host": game.host,
            "ai_players": len(game.ai_players),
            "created_at": getattr(game, 'created_at', None),
            "current_round": game.current_round,
            "connections": len(game_manager.game_connections.get(game_id, set()))
        }
        games_list.append(game_info)
        
        total_players += len(game.players)
        total_spectators += len(game.spectators)
        ai_players += len(game.ai_players)
        
        if game.game_started:
            games_in_progress += 1
        else:
            games_waiting += 1
    
    # WebSocket connection statistics
    total_game_connections = sum(len(connections) for connections in game_manager.game_connections.values())
    total_lobby_connections = len(game_manager.lobby_connections)
    total_spectator_connections = sum(len(connections) for connections in game_manager.spectator_connections.values())
    
    # System resource statistics
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        memory_used_mb = memory.used // (1024 * 1024)
        memory_total_mb = memory.total // (1024 * 1024)
    except Exception as e:
        cpu_percent = None
        memory_percent = None
        memory_used_mb = None
        memory_total_mb = None
    
    return {
        "timestamp": int(time.time()),
        "games": {
            "total_active": active_games,
            "in_progress": games_in_progress,
            "waiting_for_players": games_waiting,
            "games_list": games_list
        },
        "players": {
            "total_players": total_players,
            "total_spectators": total_spectators,
            "ai_players": ai_players,
            "human_players": total_players - ai_players
        },
        "connections": {
            "total_game_connections": total_game_connections,
            "total_lobby_connections": total_lobby_connections,
            "total_spectator_connections": total_spectator_connections,
            "total_websockets": total_game_connections + total_lobby_connections + total_spectator_connections
        },
        "resources": {
            "cpu_percent": cpu_percent,
            "memory_percent": memory_percent,
            "memory_used_mb": memory_used_mb,
            "memory_total_mb": memory_total_mb
        }
    }

@router.get("/games")
async def get_games_list():
    """Get detailed list of all active games"""
    games = []
    
    for game_id, game in game_manager.active_games.items():
        # Get connection info
        connections = game_manager.game_connections.get(game_id, set())
        spectator_connections = game_manager.spectator_connections.get(game_id, set())
        
        game_details = {
            "game_id": game_id,
            "name": game.name,
            "host": game.host,
            "players": game.players,
            "spectators": game.spectators,
            "ai_players": game.ai_players,
            "player_count": len(game.players),
            "spectator_count": len(game.spectators),
            "max_players": game.max_players,
            "min_players": game.min_players,
            "started": game.game_started,
            "current_player": game.get_current_player() if game.game_started else None,
            "current_round": game.current_round,
            "boneyard_count": len(game.boneyard) if hasattr(game, 'boneyard') else 0,
            "connections": len(connections),
            "spectator_connections": len(spectator_connections),
            "created_at": getattr(game, 'created_at', None),
            "countdown_remaining": game.get_countdown_remaining(),
            "ai_enabled": game.ai_enabled,
            "ai_skill_level": game.ai_skill_level
        }
        
        # Check if AI might be stuck (current player is AI for too long)
        if game.game_started and game.get_current_player() in game.ai_players:
            game_details["potential_ai_stuck"] = True
        else:
            game_details["potential_ai_stuck"] = False
        
        games.append(game_details)
    
    return {"games": games}

@router.get("/games/{game_id}")
async def get_game_details(game_id: str):
    """Get detailed information about a specific game"""
    game = game_manager.active_games.get(game_id)
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    # Get WebSocket connections for this game
    connections = game_manager.game_connections.get(game_id, set())
    spectator_connections = game_manager.spectator_connections.get(game_id, set())
    
    # Get player connection mapping
    player_connections = {}
    for ws, player_name in game_manager.websocket_players.items():
        if ws in connections:
            player_connections[player_name] = True
    
    game_state = game.get_game_state()
    
    return {
        "game_details": game_state,
        "connections": {
            "total_connections": len(connections),
            "spectator_connections": len(spectator_connections),
            "player_connections": player_connections
        },
        "potential_issues": {
            "ai_stuck": game.game_started and game.get_current_player() in game.ai_players,
            "no_connections": len(connections) == 0 and game.game_started,
            "boneyard_empty": len(game.boneyard) == 0 if hasattr(game, 'boneyard') else False
        }
    }

@router.post("/games/{game_id}/kill")
async def kill_game(game_id: str, reason: str = "Admin intervention"):
    """Force kill a stuck or problematic game"""
    game = game_manager.active_games.get(game_id)
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    # Notify all connected players about the game being killed
    if game_id in game_manager.game_connections:
        await game_manager.broadcast_to_game(game_id, {
            "type": "game_killed",
            "data": {
                "reason": reason,
                "message": f"Game has been terminated by admin: {reason}"
            }
        })
    
    # Clean up all connections
    if game_id in game_manager.game_connections:
        connections_to_close = list(game_manager.game_connections[game_id])
        for ws in connections_to_close:
            await game_manager.disconnect(ws, game_id)
    
    # Remove game from active games
    del game_manager.active_games[game_id]
    
    # Clean up any remaining references
    if game_id in game_manager.game_connections:
        del game_manager.game_connections[game_id]
    if game_id in game_manager.spectator_connections:
        del game_manager.spectator_connections[game_id]
    
    return {
        "success": True,
        "message": f"Game {game_id} has been terminated",
        "reason": reason
    }

@router.post("/games/{game_id}/force-next-turn")
async def force_next_turn(game_id: str):
    """Force the game to move to the next player's turn (useful for stuck AI)"""
    game = game_manager.active_games.get(game_id)
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    
    if not game.game_started:
        raise HTTPException(status_code=400, detail="Game has not started")
    
    current_player = game.get_current_player()
    game.next_turn()
    new_player = game.get_current_player()
    
    # Broadcast the forced turn change
    await game_manager.broadcast_to_game(game_id, {
        "type": "admin_action",
        "data": {
            "action": "force_next_turn",
            "message": f"Admin forced turn to pass from {current_player} to {new_player}",
            "current_player": new_player
        }
    })
    
    # Broadcast updated game state
    await game_manager.broadcast_to_game(game_id, {
        "type": "game_state",
        "data": {}  # Will be personalized in broadcast_to_game
    })
    
    # If new player is AI, trigger their move
    if new_player in game.ai_players:
        import asyncio
        asyncio.create_task(game_manager.trigger_ai_moves(game_id))
    
    return {
        "success": True,
        "message": f"Forced turn from {current_player} to {new_player}",
        "current_player": new_player
    }

@router.get("/system/health")
async def system_health():
    """Get system health information"""
    try:
        # System info
        boot_time = psutil.boot_time()
        uptime_seconds = time.time() - boot_time
        
        # CPU info
        cpu_count = psutil.cpu_count()
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory info
        memory = psutil.virtual_memory()
        
        # Disk info
        disk = psutil.disk_usage('/')
        
        return {
            "status": "healthy",
            "uptime_seconds": int(uptime_seconds),
            "cpu": {
                "count": cpu_count,
                "percent": cpu_percent
            },
            "memory": {
                "total_mb": memory.total // (1024 * 1024),
                "used_mb": memory.used // (1024 * 1024),
                "available_mb": memory.available // (1024 * 1024),
                "percent": memory.percent
            },
            "disk": {
                "total_gb": disk.total // (1024 * 1024 * 1024),
                "used_gb": disk.used // (1024 * 1024 * 1024),
                "free_gb": disk.free // (1024 * 1024 * 1024),
                "percent": (disk.used / disk.total) * 100
            }
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }