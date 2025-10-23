from django.utils.deprecation import MiddlewareMixin  
from django.http import HttpResponse  
import logging  
  
logger = logging.getLogger(__name__)  
  
class SecurityHeadersMiddleware(MiddlewareMixin):  
    """Middleware để thêm các security headers"""  
      
    def process_response(self, request, response):  
        # Thêm các security headers  
        response['X-Content-Type-Options'] = 'nosniff'  
        response['X-Frame-Options'] = 'DENY'  
        response['X-XSS-Protection'] = '1; mode=block'  
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'  
        response['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'  
          
        # Content Security Policy  
        response['Content-Security-Policy'] = (  
            "default-src 'self'; "  
            "script-src 'self' 'unsafe-inline'; "  
            "style-src 'self' 'unsafe-inline'; "  
            "img-src 'self' data: https:; "  
            "font-src 'self'; "  
            "connect-src 'self'; "  
            "frame-ancestors 'none';"  
        )  
          
        return response  
  
class AttendanceAuditMiddleware(MiddlewareMixin):  
    """Middleware để log các hoạt động điểm danh"""  
      
    def process_request(self, request):  
        # Log các request quan trọng  
        if request.path.startswith('/attendance/') or request.path.startswith('/user/register-face/'):  
            logger.info(f"Security Event: {request.method} {request.path} from {request.META.get('REMOTE_ADDR')} by user {getattr(request.user, 'user_code', 'Anonymous')}")  
          
        return None