from functools import wraps  
from django.core.cache import cache  
from django.http import JsonResponse  
from rest_framework import status  
from django.utils import timezone  
from datetime import timedelta  
import hashlib  
  
def rate_limit_attendance(max_attempts=3, window_minutes=15):  
    """  
    Rate limiting decorator cho attendance check-in  
    max_attempts: Số lần thử tối đa  
    window_minutes: Thời gian window (phút)  
    """  
    def decorator(view_func):  
        @wraps(view_func)  
        def wrapper(request, *args, **kwargs):  
            # Tạo key duy nhất cho mỗi user  
            user_id = request.user.id if request.user.is_authenticated else None  
            if not user_id:  
                return JsonResponse(  
                    {'error': 'Unauthorized'},   
                    status=status.HTTP_401_UNAUTHORIZED  
                )  
              
            # Tạo cache key  
            cache_key = f"attendance_attempts_{user_id}"  
              
            # Lấy thông tin attempts từ cache  
            attempts_data = cache.get(cache_key, {'count': 0, 'first_attempt': None})  
              
            current_time = timezone.now()  
              
            # Reset counter nếu đã hết window time  
            if attempts_data['first_attempt']:  
                first_attempt_time = attempts_data['first_attempt']  
                if current_time - first_attempt_time > timedelta(minutes=window_minutes):  
                    attempts_data = {'count': 0, 'first_attempt': None}  
              
            # Kiểm tra rate limit  
            if attempts_data['count'] >= max_attempts:  
                remaining_time = (attempts_data['first_attempt'] +   
                                timedelta(minutes=window_minutes) - current_time)  
                return JsonResponse({  
                    'error': f'Quá nhiều lần thử điểm danh. Vui lòng thử lại sau {remaining_time.seconds // 60} phút.',  
                    'retry_after': remaining_time.seconds  
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)  
              
            # Thực hiện request  
            response = view_func(request, *args, **kwargs)  
              
            # Chỉ tăng counter nếu request thất bại (status >= 400)  
            if hasattr(response, 'status_code') and response.status_code >= 400:  
                attempts_data['count'] += 1  
                if attempts_data['first_attempt'] is None:  
                    attempts_data['first_attempt'] = current_time  
                  
                # Lưu vào cache với timeout  
                cache.set(cache_key, attempts_data, timeout=window_minutes * 60)  
              
            # Reset counter nếu thành công  
            elif hasattr(response, 'status_code') and response.status_code < 400:  
                cache.delete(cache_key)  
              
            return response  
        return wrapper  
    return decorator  
  
def rate_limit_face_registration(max_attempts=5, window_minutes=60):  
    """Rate limiting cho face registration"""  
    def decorator(view_func):  
        @wraps(view_func)  
        def wrapper(request, *args, **kwargs):  
            user_id = request.user.id if request.user.is_authenticated else None  
            if not user_id:  
                return JsonResponse(  
                    {'error': 'Unauthorized'},   
                    status=status.HTTP_401_UNAUTHORIZED  
                )  
              
            cache_key = f"face_reg_attempts_{user_id}"  
            attempts_data = cache.get(cache_key, {'count': 0, 'first_attempt': None})  
              
            current_time = timezone.now()  
              
            if attempts_data['first_attempt']:  
                first_attempt_time = attempts_data['first_attempt']  
                if current_time - first_attempt_time > timedelta(minutes=window_minutes):  
                    attempts_data = {'count': 0, 'first_attempt': None}  
              
            if attempts_data['count'] >= max_attempts:  
                remaining_time = (attempts_data['first_attempt'] +   
                                timedelta(minutes=window_minutes) - current_time)  
                return JsonResponse({  
                    'error': f'Quá nhiều lần thử đăng ký khuôn mặt. Vui lòng thử lại sau {remaining_time.seconds // 60} phút.',  
                    'retry_after': remaining_time.seconds  
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)  
              
            response = view_func(request, *args, **kwargs)  
              
            if hasattr(response, 'status_code') and response.status_code >= 400:  
                attempts_data['count'] += 1  
                if attempts_data['first_attempt'] is None:  
                    attempts_data['first_attempt'] = current_time  
                cache.set(cache_key, attempts_data, timeout=window_minutes * 60)  
            elif hasattr(response, 'status_code') and response.status_code < 400:  
                cache.delete(cache_key)  
              
            return response  
        return wrapper  
    return decorator