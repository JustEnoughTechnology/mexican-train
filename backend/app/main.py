from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api import auth, games, admin
from app.websockets.game_manager import game_manager
from app.core.config import settings
# TODO: Re-enable database when Docker is running
# from app.core.database import engine
# from app.models import Base

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await game_manager.initialize()
    # TODO: Re-enable database initialization when Docker is running
    # Base.metadata.create_all(bind=engine)
    yield
    # Shutdown
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

@app.websocket("/ws/game/{game_id}")
async def websocket_endpoint(websocket: WebSocket, game_id: str):
    await game_manager.connect(websocket, game_id)
    try:
        while True:
            data = await websocket.receive_json()
            await game_manager.handle_message(websocket, game_id, data)
    except WebSocketDisconnect:
        await game_manager.disconnect(websocket, game_id)

@app.get("/")
async def root():
    return {"message": "Mexican Train Domino Game API", "version": "0.1.1"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/api/users/online")
async def get_online_users():
    online_users = []
    
    # Get users from active WebSocket connections
    for game_id, game in game_manager.active_games.items():
        game_state = game.get_game_state()
        players = game_state.get("players", [])
        for player in players:
            if player not in [u["username"] for u in online_users]:
                online_users.append({
                    "id": f"user_{len(online_users) + 1}",
                    "username": player,
                    "status": "in-game" if game_state.get("started", False) else "lobby"
                })
    
    return {"users": online_users}