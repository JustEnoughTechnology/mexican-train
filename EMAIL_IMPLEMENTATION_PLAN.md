# Email Implementation Plan - Office 365 SMTP

## Overview
Replace the current mock email implementation with Office 365 SMTP using existing infrastructure.

## Benefits
- **Cost**: $0 additional (using existing O365 subscription)
- **Sending Limits**: 10,000 emails/day per mailbox
- **Professional**: Clean from/reply-to addresses
- **Reliable**: Enterprise-grade email infrastructure

## Setup Requirements

### 1. O365 Configuration
- [ ] Add `password-reset@justenoughtechnology.com` as email alias to chosen O365 account
- [ ] Generate App Password for SMTP authentication
- [ ] Verify alias is working (may take 5-15 minutes to propagate)

### 2. Environment Variables to Add
```bash
# Email Configuration
SMTP_SERVER=smtp.office365.com
SMTP_PORT=587
SMTP_USERNAME=your-main-account@yourdomain.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=password-reset@justenoughtechnology.com
SMTP_FROM_NAME=Mexican Train Support
```

### 3. Code Changes Needed

#### Update `backend/app/utils/email.py`
Replace mock implementation with real SMTP:

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

class EmailService:
    def __init__(self):
        self.smtp_server = os.getenv('SMTP_SERVER', 'smtp.office365.com')
        self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
        self.smtp_username = os.getenv('SMTP_USERNAME')
        self.smtp_password = os.getenv('SMTP_PASSWORD')
        self.from_email = os.getenv('SMTP_FROM_EMAIL', 'password-reset@justenoughtechnology.com')
        self.from_name = os.getenv('SMTP_FROM_NAME', 'Mexican Train Support')
    
    def send_email(self, to_email: str, subject: str, html_content: str, text_content: Optional[str] = None) -> bool:
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = f"{self.from_name} <{self.from_email}>"
            msg['To'] = to_email
            msg['Reply-To'] = self.from_email
            
            # Add HTML content
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Send via O365 SMTP
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_username, self.smtp_password)
                server.send_message(msg)
            
            logger.info(f"Email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return False
```

#### Add to `backend/pyproject.toml` if needed
```toml
# Email dependencies should already be available in Python stdlib
```

#### Update Docker Environment
Add email environment variables to `docker-compose.yml`:
```yaml
environment:
  - SMTP_SERVER=${SMTP_SERVER}
  - SMTP_PORT=${SMTP_PORT}
  - SMTP_USERNAME=${SMTP_USERNAME}
  - SMTP_PASSWORD=${SMTP_PASSWORD}
  - SMTP_FROM_EMAIL=${SMTP_FROM_EMAIL}
  - SMTP_FROM_NAME=${SMTP_FROM_NAME}
```

## Email Templates Current State
Already implemented with proper HTML formatting:
- ✅ Email verification with branded styling
- ✅ Magic link sign-in with security messaging  
- ✅ Password reset with clear CTAs
- ✅ Professional Mexican Train branding

## Security Considerations
- App passwords are more secure than main passwords
- Consider OAuth 2.0 for production (more complex setup)
- SMTP credentials should be in environment variables, not code
- TLS encryption enabled by default

## Testing Plan
1. Set up alias and app password
2. Update environment variables
3. Replace mock implementation
4. Test each email type:
   - Registration verification
   - Magic link sign-in
   - Password reset
5. Verify deliverability and spam folder placement

## Alternative: OAuth 2.0 (Future Enhancement)
For even better security, consider implementing OAuth 2.0 flow:
- No stored passwords
- Token-based authentication
- Automatic token refresh
- Requires Azure App Registration

## Implementation Timeline
- **Setup**: 10 minutes (add alias, generate app password)
- **Code Changes**: 15 minutes (replace mock with SMTP)
- **Testing**: 10 minutes (verify all email flows)
- **Total**: ~35 minutes

## Current Status
- ❌ **Not Implemented** - Using mock email service
- ✅ **Email Templates Ready** - Professional HTML templates created
- ✅ **Infrastructure Ready** - O365 account and domain available
- ⏳ **Pending**: Alias setup and SMTP implementation

---
*Created: 2025-08-17*  
*Status: Planning Phase*