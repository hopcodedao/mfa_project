from django.contrib.auth.backends import BaseBackend  
from django.contrib.auth import get_user_model  
from django.core.cache import cache  
from django.utils import timezone  
from datetime import timedelta  
import logging  
  
User = get_user_model()  
logger = logging.getLogger(__name__)  
  
class SecureAuthenticationBackend(BaseBackend):  
    """  
    Custom authentication backend với security enhancements  
    """  
      
    def authenticate(self, request, user_code=None, password=None, **kwargs):  
        if user_code is None or password is None:  
            return None  
          
        # Rate limiting cho login attempts  
        cache_key = f"login_attempts_{user_code}"  
        attempts = cache.get(cache_key, 0)  
          
        if attempts >= 5:  # Tối đa 5 lần thử trong 15 phút  
            logger.warning(f"Login blocked for user {user_code} due to too many attempts")  
            return None  
          
        try:  
            user = User.objects.get(user_code=user_code)  
              
            if user.check_password(password) and user.is_active:  
                # Reset login attempts nếu thành công  
                cache.delete(cache_key)  
                  
                # Log successful login  
                logger.info(f"Successful login for user {user_code} from IP {request.META.get('REMOTE_ADDR')}")  
                  
                return user  
            else:  
                # Tăng số lần thử thất bại  
                cache.set(cache_key, attempts + 1, timeout=900)  # 15 phút  
                  
                # Log failed login  
                logger.warning(f"Failed login attempt for user {user_code} from IP {request.META.get('REMOTE_ADDR')}")  
                  
                return None  
                  
        except User.DoesNotExist:  
            # Tăng số lần thử thất bại ngay cả khi user không tồn tại  
            cache.set(cache_key, attempts + 1, timeout=900)  
              
            # Log failed login attempt  
            logger.warning(f"Failed login attempt for non-existent user {user_code} from IP {request.META.get('REMOTE_ADDR')}")  
              
            return None  
      
    def get_user(self, user_id):  
        try:  
            return User.objects.get(pk=user_id)  
        except User.DoesNotExist:  
            return None