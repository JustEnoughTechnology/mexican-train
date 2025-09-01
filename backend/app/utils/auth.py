"""
Authentication utilities for secure password handling and token generation
"""
import hashlib
import secrets
import hmac
from datetime import datetime, timedelta
from typing import Optional
import bcrypt

class AuthUtils:
    @staticmethod
    def hash_password(password: str) -> str:
        """Securely hash a password using bcrypt"""
        # Generate salt and hash password
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')
    
    @staticmethod
    def verify_password(password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        try:
            return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))
        except Exception:
            return False
    
    @staticmethod
    def generate_secure_token(length: int = 32) -> str:
        """Generate a cryptographically secure random token"""
        return secrets.token_urlsafe(length)
    
    @staticmethod
    def generate_email_verification_token() -> str:
        """Generate token for email verification"""
        return AuthUtils.generate_secure_token(32)
    
    @staticmethod
    def generate_magic_link_token() -> str:
        """Generate token for magic link authentication"""
        return AuthUtils.generate_secure_token(48)
    
    @staticmethod
    def generate_password_reset_token() -> str:
        """Generate token for password reset"""
        return AuthUtils.generate_secure_token(32)
    
    @staticmethod
    def get_token_expiry(hours: int = 24) -> datetime:
        """Get expiry time for tokens (default 24 hours)"""
        from datetime import timezone
        return datetime.now(timezone.utc) + timedelta(hours=hours)
    
    @staticmethod
    def is_token_expired(expires_at: Optional[datetime]) -> bool:
        """Check if a token has expired"""
        if not expires_at:
            return True
        from datetime import timezone
        current_time = datetime.now(timezone.utc)
        # Handle both timezone-aware and naive datetimes
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        return current_time > expires_at
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """Basic email validation"""
        import re
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def validate_password_strength(password: str) -> dict:
        """Validate password strength"""
        errors = []
        
        if len(password) < 8:
            errors.append("Password must be at least 8 characters long")
        
        if not any(c.isupper() for c in password):
            errors.append("Password must contain at least one uppercase letter")
        
        if not any(c.islower() for c in password):
            errors.append("Password must contain at least one lowercase letter")
        
        if not any(c.isdigit() for c in password):
            errors.append("Password must contain at least one number")
        
        # Check for common weak passwords
        weak_passwords = ['password', '12345678', 'qwerty', 'abc123']
        if password.lower() in weak_passwords:
            errors.append("Password is too common")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors
        }

# Global auth utils instance
auth_utils = AuthUtils()