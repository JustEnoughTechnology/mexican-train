from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import re
from datetime import datetime, timezone
from app.utils.content_filter import content_filter
from app.utils.auth import auth_utils
from app.utils.email import email_service
from app.core.database import get_db
from app.models.user import User
from pydantic import BaseModel, EmailStr

router = APIRouter()

# Pydantic models for request/response
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    username: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class MagicLinkRequest(BaseModel):
    email: EmailStr

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str

@router.post("/register")
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Register a new user with email verification"""
    
    # Validate email format
    if not auth_utils.validate_email(user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email format"
        )
    
    # Validate password strength
    password_validation = auth_utils.validate_password_strength(user_data.password)
    if not password_validation["valid"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"message": "Password does not meet requirements", "errors": password_validation["errors"]}
        )
    
    # Validate username
    if not content_filter.contains_inappropriate_content(user_data.username):
        username_validation = await check_username_availability(user_data.username)
        if not username_validation["available"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=username_validation["reason"]
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username contains inappropriate content"
        )
    
    # Check if user already exists
    existing_user = db.query(User).filter(
        (User.email == user_data.email) | (User.username == user_data.username)
    ).first()
    
    if existing_user:
        if existing_user.email == user_data.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
    
    # Create new user
    hashed_password = auth_utils.hash_password(user_data.password)
    email_verify_token = auth_utils.generate_email_verification_token()
    
    new_user = User(
        email=user_data.email.lower(),
        username=user_data.username,
        hashed_password=hashed_password,
        email_verify_token=email_verify_token,
        token_expires_at=auth_utils.get_token_expiry(24),  # 24 hours
        is_email_verified=False
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Send verification email
    email_sent = email_service.send_verification_email(user_data.email, email_verify_token)
    
    return {
        "message": "User registered successfully",
        "email": user_data.email,
        "username": user_data.username,
        "email_sent": email_sent,
        "next_step": "Check your email for verification link"
    }

@router.post("/login") 
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """Login with email and password"""
    
    # Find user by email
    user = db.query(User).filter(User.email == user_data.email.lower()).first()
    
    if not user or not auth_utils.verify_password(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    if not user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email not verified. Please check your email for verification link."
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account is disabled"
        )
    
    # Update last seen
    user.last_seen = datetime.now(timezone.utc)
    db.commit()
    
    return {
        "message": "Login successful",
        "user": {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "is_verified": user.is_email_verified
        }
    }

@router.get("/me")
async def get_current_user():
    return {"message": "Current user endpoint - TODO"}

@router.get("/session")
async def get_session():
    return {"authenticated": False, "user": None}

@router.post("/_log")
async def log_event():
    return {"status": "logged"}

@router.get("/check-username/{username}")
async def check_username_availability(username: str):
    # TODO: Check against database of registered users
    # For now, we'll check against a basic list and online users
    
    # Reserved/system usernames
    reserved_names = [
        "admin", "administrator", "moderator", "system", "bot", "guest", 
        "user", "player", "mexican-train", "support", "help", "api", "www"
    ]
    
    # Normalize username for comparison
    username_lower = username.lower().strip()
    
    # Check if it's a reserved name
    if username_lower in reserved_names:
        return {"available": False, "reason": "Username is reserved"}
    
    # Check if it's too short or has invalid characters
    if len(username) < 2 or len(username) > 20:
        return {"available": False, "reason": "Username must be 2-20 characters"}
    
    # Basic character validation (alphanumeric, underscore, dash)
    if not re.match("^[a-zA-Z0-9_-]+$", username):
        return {"available": False, "reason": "Username can only contain letters, numbers, underscores, and dashes"}
    
    # Check for inappropriate content
    if content_filter.contains_inappropriate_content(username):
        return {"available": False, "reason": "Username contains inappropriate content"}
    
    # TODO: Add database check for registered users
    # registered_user = db.query(User).filter(User.username.ilike(username)).first()
    # if registered_user:
    #     return {"available": False, "reason": "Username is already registered"}
    
    return {"available": True}

@router.post("/magic-link")
async def request_magic_link(request: MagicLinkRequest, db: Session = Depends(get_db)):
    """Request a magic link for passwordless sign-in"""
    
    # Find user by email
    user = db.query(User).filter(User.email == request.email.lower()).first()
    
    if not user:
        # Don't reveal if email exists for security
        return {"message": "If this email is registered, you'll receive a sign-in link"}
    
    if not user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email not verified. Please verify your email first."
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account is disabled"
        )
    
    # Generate magic link token
    magic_token = auth_utils.generate_magic_link_token()
    user.magic_link_token = magic_token
    user.token_expires_at = auth_utils.get_token_expiry(1)  # 1 hour
    
    db.commit()
    
    # Send magic link email
    email_sent = email_service.send_magic_link_email(request.email, magic_token)
    
    return {
        "message": "If this email is registered, you'll receive a sign-in link",
        "email_sent": email_sent
    }

@router.get("/magic-signin/{token}")
async def magic_signin(token: str, db: Session = Depends(get_db)):
    """Sign in using magic link token"""
    
    # Find user with this magic link token
    user = db.query(User).filter(User.magic_link_token == token).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired magic link"
        )
    
    # Check if token is expired
    if auth_utils.is_token_expired(user.token_expires_at):
        user.magic_link_token = None
        user.token_expires_at = None
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Magic link has expired"
        )
    
    # Clear the token (one-time use)
    user.magic_link_token = None
    user.token_expires_at = None
    user.last_seen = datetime.now(timezone.utc)
    db.commit()
    
    return {
        "message": "Magic link sign-in successful",
        "user": {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "is_verified": user.is_email_verified
        }
    }

@router.post("/password-reset")
async def request_password_reset(request: PasswordResetRequest, db: Session = Depends(get_db)):
    """Request password reset email"""
    
    # Find user by email
    user = db.query(User).filter(User.email == request.email.lower()).first()
    
    if not user:
        # Don't reveal if email exists for security
        return {"message": "If this email is registered, you'll receive a password reset link"}
    
    # Generate password reset token
    reset_token = auth_utils.generate_password_reset_token()
    user.password_reset_token = reset_token
    user.token_expires_at = auth_utils.get_token_expiry(24)  # 24 hours
    
    db.commit()
    
    # Send password reset email
    email_sent = email_service.send_password_reset_email(request.email, reset_token)
    
    return {
        "message": "If this email is registered, you'll receive a password reset link",
        "email_sent": email_sent
    }

@router.post("/password-reset-confirm")
async def confirm_password_reset(request: PasswordResetConfirm, db: Session = Depends(get_db)):
    """Confirm password reset with new password"""
    
    # Find user with this reset token
    user = db.query(User).filter(User.password_reset_token == request.token).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )
    
    # Check if token is expired
    if auth_utils.is_token_expired(user.token_expires_at):
        user.password_reset_token = None
        user.token_expires_at = None
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset token has expired"
        )
    
    # Validate new password strength
    password_validation = auth_utils.validate_password_strength(request.new_password)
    if not password_validation["valid"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"message": "Password does not meet requirements", "errors": password_validation["errors"]}
        )
    
    # Update password
    user.hashed_password = auth_utils.hash_password(request.new_password)
    user.password_reset_token = None
    user.token_expires_at = None
    
    db.commit()
    
    return {"message": "Password reset successful"}

@router.get("/verify-email/{token}")
async def verify_email(token: str, db: Session = Depends(get_db)):
    """Verify email address using token"""
    
    # Find user with this verification token
    user = db.query(User).filter(User.email_verify_token == token).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification token"
        )
    
    # Check if token is expired
    if auth_utils.is_token_expired(user.token_expires_at):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification token has expired"
        )
    
    # Mark email as verified
    user.is_email_verified = True
    user.email_verify_token = None
    user.token_expires_at = None
    
    db.commit()
    
    return {"message": "Email verified successfully"}

@router.get("/filter-info")
async def get_filter_info():
    """Get information about content filtering"""
    return content_filter.get_word_lists_info()