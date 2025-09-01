"""
Email sending utilities for authentication emails
"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class EmailService:
    def __init__(self):
        # For development, we'll use a mock email service
        # In production, configure with real SMTP settings
        self.smtp_server = None
        self.smtp_port = None
        self.smtp_username = None
        self.smtp_password = None
        self.from_email = "noreply@mexicantrain.local"
        
    def send_email(self, to_email: str, subject: str, html_content: str, text_content: Optional[str] = None) -> bool:
        """Send an email (mock implementation for development)"""
        try:
            # For development, just log the email content
            logger.info(f"📧 MOCK EMAIL SENT:")
            logger.info(f"To: {to_email}")
            logger.info(f"Subject: {subject}")
            logger.info(f"Content: {html_content}")
            print(f"📧 MOCK EMAIL TO {to_email}: {subject}")
            print(f"Content: {html_content}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False
    
    def send_verification_email(self, to_email: str, token: str, base_url: str = "http://localhost:8082") -> bool:
        """Send email verification email"""
        verify_url = f"{base_url}/verify-email?token={token}"
        
        subject = "Verify your Mexican Train account"
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #2d5a27;">🚂 Welcome to Mexican Train!</h1>
                <p>Thanks for creating an account! Please verify your email address to get started.</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{verify_url}" 
                       style="background-color: #4CAF50; color: white; padding: 12px 24px; 
                              text-decoration: none; border-radius: 4px; display: inline-block;">
                        Verify Email Address
                    </a>
                </div>
                
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; background-color: #f5f5f5; padding: 10px; border-radius: 4px;">
                    {verify_url}
                </p>
                
                <p style="color: #666; font-size: 0.9em;">
                    This link will expire in 24 hours. If you didn't create this account, you can safely ignore this email.
                </p>
            </div>
        </body>
        </html>
        """
        
        return self.send_email(to_email, subject, html_content)
    
    def send_magic_link_email(self, to_email: str, token: str, base_url: str = "http://localhost:8082") -> bool:
        """Send magic link sign-in email"""
        magic_url = f"{base_url}/magic-signin?token={token}"
        
        subject = "Your Mexican Train sign-in link"
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #2d5a27;">🚂 Sign in to Mexican Train</h1>
                <p>Click the button below to sign in to your account (no password needed!):</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{magic_url}" 
                       style="background-color: #2196F3; color: white; padding: 12px 24px; 
                              text-decoration: none; border-radius: 4px; display: inline-block;">
                        Sign In Now
                    </a>
                </div>
                
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; background-color: #f5f5f5; padding: 10px; border-radius: 4px;">
                    {magic_url}
                </p>
                
                <p style="color: #666; font-size: 0.9em;">
                    This link will expire in 1 hour. If you didn't request this, you can safely ignore this email.
                </p>
            </div>
        </body>
        </html>
        """
        
        return self.send_email(to_email, subject, html_content)
    
    def send_password_reset_email(self, to_email: str, token: str, base_url: str = "http://localhost:8082") -> bool:
        """Send password reset email"""
        reset_url = f"{base_url}/reset-password?token={token}"
        
        subject = "Reset your Mexican Train password"
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #2d5a27;">🚂 Reset Your Password</h1>
                <p>You requested to reset your password. Click the button below to create a new password:</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{reset_url}" 
                       style="background-color: #FF9800; color: white; padding: 12px 24px; 
                              text-decoration: none; border-radius: 4px; display: inline-block;">
                        Reset Password
                    </a>
                </div>
                
                <p>Or copy and paste this link into your browser:</p>
                <p style="word-break: break-all; background-color: #f5f5f5; padding: 10px; border-radius: 4px;">
                    {reset_url}
                </p>
                
                <p style="color: #666; font-size: 0.9em;">
                    This link will expire in 24 hours. If you didn't request this, you can safely ignore this email.
                </p>
            </div>
        </body>
        </html>
        """
        
        return self.send_email(to_email, subject, html_content)

# Global email service instance
email_service = EmailService()