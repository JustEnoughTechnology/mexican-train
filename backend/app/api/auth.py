from fastapi import APIRouter

router = APIRouter()

@router.post("/register")
async def register():
    return {"message": "User registration endpoint - TODO"}

@router.post("/login") 
async def login():
    return {"message": "User login endpoint - TODO"}

@router.get("/me")
async def get_current_user():
    return {"message": "Current user endpoint - TODO"}