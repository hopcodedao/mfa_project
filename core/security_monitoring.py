from django.core.mail import send_mail  
from django.conf import settings  
from django.utils import timezone  
from datetime import timedelta  
import logging  
  
logger = logging.getLogger(__name__)  
  
class SecurityMonitor:  
    """Hệ thống giám sát bảo mật"""  
      
    @staticmethod  
    def alert_suspicious_activity(user, activity_type, details):  
        """Gửi cảnh báo hoạt động đáng ngờ"""  
        subject = f"[MFA-CTUT] Cảnh báo bảo mật: {activity_type}"  
        message = f"""  
        Phát hiện hoạt động đáng ngờ:  
          
        Người dùng: {user.user_code} ({user.get_full_name()})  
        Loại hoạt động: {activity_type}  
        Thời gian: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}  
        Chi tiết: {details}  
          
        Vui lòng kiểm tra và xử lý kịp thời.  
        """  
          
        # Gửi email cho admin  
        admin_emails = ['admin@ctuet.edu.vn']  # Cấu hình email admin  
        try:  
            send_mail(  
                subject,  
                message,  
                settings.DEFAULT_FROM_EMAIL,  
                admin_emails,  
                fail_silently=False,  
            )  
            logger.info(f"Security alert sent for user {user.user_code}: {activity_type}")  
        except Exception as e:  
            logger.error(f"Failed to send security alert: {e}")  
      
    @staticmethod  
    def check_multiple_failed_attempts(user_code, threshold=5):  
        """Kiểm tra nhiều lần thử thất bại"""  
        from django.core.cache import cache  
          
        cache_key = f"failed_attempts_{user_code}"  
        attempts = cache.get(cache_key, 0)  
          
        if attempts >= threshold:  
            try:  
                from .models import User  
                user = User.objects.get(user_code=user_code)  
                SecurityMonitor.alert_suspicious_activity(  
                    user,   
                    "Multiple Failed Login Attempts",  
                    f"User has {attempts} failed login attempts in the last 15 minutes"  
                )  
            except User.DoesNotExist:  
                logger.warning(f"Failed login attempts for non-existent user: {user_code}")  
      
    @staticmethod  
    def check_unusual_location(user, latitude, longitude):  
        """Kiểm tra vị trí bất thường"""  
        from .models import AttendanceRecord  
        from geopy.distance import geodesic  
          
        # Lấy 5 vị trí điểm danh gần nhất  
        recent_records = AttendanceRecord.objects.filter(  
            student=user,  
            recorded_latitude__isnull=False,  
            recorded_longitude__isnull=False  
        ).order_by('-check_in_time')[:5]  
          
        if recent_records.count() >= 3:  
            current_location = (latitude, longitude)  
            distances = []  
              
            for record in recent_records:  
                past_location = (record.recorded_latitude, record.recorded_longitude)  
                distance = geodesic(current_location, past_location).kilometers  
                distances.append(distance)  
              
            avg_distance = sum(distances) / len(distances)  
              
            # Nếu khoảng cách trung bình > 50km, cảnh báo  
            if avg_distance > 50:  
                SecurityMonitor.alert_suspicious_activity(  
                    user,  
                    "Unusual Location Pattern",  
                    f"Average distance from recent locations: {avg_distance:.2f}km"  
                )