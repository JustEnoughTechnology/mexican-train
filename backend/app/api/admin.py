from fastapi import APIRouter

router = APIRouter()

@router.get("/games")
async def admin_list_games():
    return {"message": "Admin list games endpoint - TODO"}

@router.get("/users")
async def admin_list_users():
    return {"message": "Admin list users endpoint - TODO"}

@router.post("/games/{game_id}/end")
async def admin_end_game(game_id: str):
    return {"message": f"Admin end game {game_id} endpoint - TODO"}