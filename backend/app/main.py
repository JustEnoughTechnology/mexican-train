from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api import auth, games, admin, ai_config
from app.websockets.game_manager import game_manager
from app.core.config import settings
from app.core.database import engine
from app.core.game_timer import timer_manager
from app.models import user, game, game_history

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await game_manager.initialize()
    await timer_manager.start()
    # Create database tables
    from app.core.database import Base
    Base.metadata.create_all(bind=engine)
    yield
    # Shutdown
    await timer_manager.stop()
    await game_manager.cleanup()

app = FastAPI(
    title="Mexican Train Domino Game",
    description="Real-time multiplayer Mexican Train domino game",
    version="0.1.1",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routes
app.include_router(auth.router, prefix="/api/auth", tags=["authentication"])
app.include_router(games.router, prefix="/api/games", tags=["games"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(ai_config.router, prefix="/api/ai", tags=["ai-config"])

@app.websocket("/ws/game/{game_id}")
async def websocket_endpoint(websocket: WebSocket, game_id: str, user_id: str = None, display_name: str = None):
    await game_manager.connect(websocket, game_id, user_id, display_name)
    try:
        while True:
            data = await websocket.receive_json()
            await game_manager.handle_message(websocket, game_id, data)
    except WebSocketDisconnect:
        await game_manager.disconnect(websocket, game_id)

@app.websocket("/ws/lobby")
async def lobby_websocket_endpoint(websocket: WebSocket, user_id: str = None, display_name: str = None):
    """WebSocket endpoint for lobby presence tracking"""
    await game_manager.connect_lobby(websocket, user_id, display_name)
    try:
        while True:
            data = await websocket.receive_json()
            # Handle lobby messages (like user status updates, chat, etc.)
            await game_manager.handle_lobby_message(websocket, data)
    except WebSocketDisconnect:
        await game_manager.disconnect_lobby(websocket)

@app.get("/")
async def root():
    return {"message": "Mexican Train Domino Game API", "version": "0.1.1"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/debug/games")
async def debug_games():
    return {
        "message": "Debug games endpoint working", 
        "status": "ok",
        "active_games": list(game_manager.active_games.keys()),
        "game_count": len(game_manager.active_games)
    }

@app.get("/api/users/online")
async def get_online_users():
    """Get all currently connected users across all games and lobby"""
    online_users = []
    processed_users = set()
    
    # Get users from WebSocket connections
    for user_id, websockets in game_manager.user_connections.items():
        if len(websockets) > 0 and user_id not in processed_users:
            processed_users.add(user_id)
            
            # Determine user status
            user_games = game_manager.get_user_games(user_id)
            if user_games:
                # Check if user is in an active game
                in_active_game = False
                for game_id in user_games:
                    game = game_manager.get_game(game_id)
                    if game and game.get_game_state().get("started", False):
                        in_active_game = True
                        break
                status = "in-game" if in_active_game else "in-lobby"
            else:
                status = "in-lobby"
            
            # Try to get display name from lobby users first
            display_name = user_id  # fallback
            user_type = "unknown"
            
            # Check if user has lobby connection with display name
            for ws, user_info in game_manager.lobby_users.items():
                if isinstance(user_info, dict) and user_info.get("user_id") == user_id:
                    display_name = user_info.get("display_name", user_id)
                    break
            
            # Determine user type and fallback display name
            if user_id.startswith("auth_"):
                user_type = "authenticated"
                if display_name == user_id:  # No display name from lobby
                    display_name = user_id.replace("auth_", "").split("@")[0]
            elif user_id.startswith("guest_"):
                user_type = "guest"
                if display_name == user_id:  # No display name from lobby
                    display_name = f"Guest {user_id.split('_')[-1]}"
            
            online_users.append({
                "id": user_id,
                "username": display_name,
                "handle": user_id,
                "user_type": user_type,
                "status": status,
                "connection_count": len(websockets),
                "active_games": len(user_games)
            })
    
    return {
        "users": online_users,
        "total_online": len(online_users),
        "total_connections": sum(len(ws) for ws in game_manager.user_connections.values())
    }