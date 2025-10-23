import re  
import hashlib  
from django.core.exceptions import ValidationError  
from django.utils.translation import gettext as _  
  
class SecurityValidator:  
    """Các hàm validation bảo mật"""  
      
    @staticmethod  
    def validate_gps_coordinates(latitude, longitude):  
        """Validate GPS coordinates"""  
        try:  
            lat = float(latitude)  
            lng = float(longitude)  
              
            # Kiểm tra phạm vi hợp lệ  
            if not (-90 <= lat <= 90):  
                raise ValidationError(_('Vĩ độ phải trong khoảng -90 đến 90'))  
              
            if not (-180 <= lng <= 180):  
                raise ValidationError(_('Kinh độ phải trong khoảng -180 đến 180'))  
              
            # Kiểm tra tọa độ có hợp lý không (không phải 0,0)  
            if lat == 0 and lng == 0:  
                raise ValidationError(_('Tọa độ GPS không hợp lệ'))  
              
            return lat, lng  
              
        except (ValueError, TypeError):  
            raise ValidationError(_('Định dạng tọa độ GPS không hợp lệ'))  
      
    @staticmethod  
    def validate_file_upload(file, allowed_types, max_size_mb=5):  
        """Validate file upload"""  
        if not file:  
            raise ValidationError(_('File không được để trống'))  
          
        # Kiểm tra kích thước  
        max_size_bytes = max_size_mb * 1024 * 1024  
        if file.size > max_size_bytes:  
            raise ValidationError(_(f'Kích thước file quá lớn. Tối đa {max_size_mb}MB'))  
          
        # Kiểm tra content type  
        if file.content_type not in allowed_types:  
            raise ValidationError(_(f'Định dạng file không được hỗ trợ. Chỉ chấp nhận: {", ".join(allowed_types)}'))  
          
        # Kiểm tra tên file  
        if not re.match(r'^[a-zA-Z0-9._-]+$', file.name):  
            raise ValidationError(_('Tên file chứa ký tự không hợp lệ'))  
          
        return True  
      
    @staticmethod  
    def generate_secure_hash(data):  
        """Tạo hash bảo mật cho dữ liệu"""  
        return hashlib.sha256(str(data).encode()).hexdigest()  
      
    @staticmethod  
    def validate_wifi_ssid(ssid):  
        """Validate WiFi SSID"""  
        if not ssid:  
            return True  # SSID có thể để trống  
          
        # Kiểm tra độ dài  
        if len(ssid) > 32:  
            raise ValidationError(_('Tên WiFi quá dài (tối đa 32 ký tự)'))  
          
        # Kiểm tra ký tự hợp lệ  
        if not re.match(r'^[a-zA-Z0-9._-\\s]+$', ssid):  
            raise ValidationError(_('Tên WiFi chứa ký tự không hợp lệ'))  
          
        return True  
  
class AttendanceSecurityChecker:  
    """Kiểm tra bảo mật cho quá trình điểm danh"""  
      
    @staticmethod  
    def check_time_window(schedule, current_time, window_minutes=30):  
        """Kiểm tra thời gian điểm danh có hợp lệ không"""  
        from datetime import datetime, timedelta  
          
        # Tính toán thời gian bắt đầu và kết thúc cho phép điểm danh  
        start_time = datetime.combine(current_time.date(), schedule.start_time)  
        end_time = datetime.combine(current_time.date(), schedule.end_time)  
          
        # Cho phép điểm danh từ 15 phút trước đến 15 phút sau giờ bắt đầu  
        allowed_start = start_time - timedelta(minutes=15)  
        allowed_end = start_time + timedelta(minutes=window_minutes)  
          
        if not (allowed_start <= current_time <= allowed_end):  
            raise ValidationError(_(f'Chỉ có thể điểm danh từ {allowed_start.strftime("%H:%M")} đến {allowed_end.strftime("%H:%M")}'))  
          
        return True  
      
    @staticmethod  
    def check_duplicate_attendance(student, schedule):  
        """Kiểm tra điểm danh trùng lặp"""  
        from .models import AttendanceRecord  
          
        existing_record = AttendanceRecord.objects.filter(  
            student=student,  
            schedule=schedule,  
            status='PRESENT'  
        ).first()  
          
        if existing_record:  
            raise ValidationError(_('Bạn đã điểm danh cho buổi học này rồi'))  
          
        return True  
      
    @staticmethod  
    def check_enrollment(student, schedule):  
        """Kiểm tra sinh viên có đăng ký lớp này không"""  
        from .models import Enrollment  
          
        enrollment = Enrollment.objects.filter(  
            student=student,  
            class_instance=schedule.class_instance,  
            status='Enrolled'  
        ).first()  
          
        if not enrollment:  
            raise ValidationError(_('Bạn không có quyền điểm danh cho lớp học này'))  
          
        return True