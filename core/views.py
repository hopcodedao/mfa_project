import face_recognition
import numpy as np
import jwt
from datetime import date, datetime, timedelta

from django.db.models import Q
from django.conf import settings
from geopy.distance import geodesic

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from rest_framework import serializers

from .models import User, Schedule, AttendanceRecord, Enrollment, Class
from .serializers import (
    ScheduleSerializer, ClassSerializer, 
    ScheduleWithAttendanceSerializer
)

import cv2
import os
import tempfile
from django.core.exceptions import ValidationError

from .firebase_utils import send_push_notification

from .serializers import ClassDetailSerializer

from .serializers import UserProfileSerializer

from PIL import Image, ImageOps

from rest_framework import viewsets, permissions
from rest_framework.decorators import action

from .models import AbsenceRequest
from .serializers import AbsenceRequestSerializer, AbsenceRequestCreateSerializer

from .serializers import AttendanceRecordSerializer
from .serializers import EnrolledClassSerializer

from django.utils import timezone
from django.db.models import Count, Avg
from django.db.models.functions import Coalesce
from datetime import timedelta

from django_filters.rest_framework import DjangoFilterBackend
from .filters import AttendanceRecordFilter

from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from .serializers import PasswordResetRequestSerializer, PasswordResetConfirmSerializer

from .serializers import ChangePasswordSerializer

from .models import Notification
from .serializers import NotificationSerializer

from .serializers import LiveAttendanceRecordSerializer

from .tasks import send_notification_to_class_task

from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from rest_framework_simplejwt.tokens import RefreshToken
from django.conf import settings

from .models import Faculty, AdministrativeClass
from .serializers import FacultySerializer, AdministrativeClassSerializer

from .decorators import rate_limit_attendance, rate_limit_face_registration  
from .encryption import face_encryption

from .security_utils import SecurityValidator, AttendanceSecurityChecker  
from django.utils import timezone

from django.db import connection  
from django.core.cache import cache  
import redis 

from .models import Schedule  
from .serializers import ScheduleSerializer

from .models import User  
from .serializers import UserProfileSerializer

@api_view(['POST'])  
@permission_classes([IsAuthenticated])  
@rate_limit_attendance(max_attempts=3, window_minutes=15)  
def check_in(request):  
    student = request.user  
    if student.role != 'student':  
        return Response({'error': 'Chỉ sinh viên mới có thể điểm danh.'}, status=status.HTTP_403_FORBIDDEN)  
  
    qr_token = request.data.get('qr_token')  
    latitude_str = request.data.get('latitude')  
    longitude_str = request.data.get('longitude')  
    submitted_ssid = request.data.get('wifi_ssid')  
      
    # Hỗ trợ cả hai loại input: ảnh tĩnh hoặc video liveness  
    face_image = request.FILES.get('face_image')  
    liveness_video = request.FILES.get('liveness_video')  
      
    # Kiểm tra input - phải có ít nhất một trong hai  
    if not all([qr_token, latitude_str, longitude_str]):  
        return Response({'error': 'Thiếu dữ liệu điểm danh (QR, GPS).'}, status=status.HTTP_400_BAD_REQUEST)  
      
    if not face_image and not liveness_video:  
        return Response({'error': 'Vui lòng cung cấp ảnh khuôn mặt hoặc video liveness.'}, status=status.HTTP_400_BAD_REQUEST)  
      
    if face_image and liveness_video:  
        return Response({'error': 'Chỉ được cung cấp một trong hai: ảnh khuôn mặt hoặc video liveness.'}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === SECURITY VALIDATIONS ===  
    try:  
        from .security_utils import SecurityValidator, AttendanceSecurityChecker  
          
        # Validate GPS coordinates  
        latitude, longitude = SecurityValidator.validate_gps_coordinates(latitude_str, longitude_str)  
          
        # Validate file upload  
        if face_image:  
            SecurityValidator.validate_file_upload(  
                face_image,   
                ['image/jpeg', 'image/jpg', 'image/png'],   
                max_size_mb=5  
            )  
        elif liveness_video:  
            SecurityValidator.validate_file_upload(  
                liveness_video,   
                ['video/mp4', 'video/avi', 'video/mov'],   
                max_size_mb=10  
            )  
          
        # Validate WiFi SSID if provided  
        if submitted_ssid:  
            SecurityValidator.validate_wifi_ssid(submitted_ssid)  
              
    except ValidationError as e:  
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === BƯỚC 1: Xác thực QR ===  
    try:  
        qr_payload = jwt.decode(qr_token, settings.SECRET_KEY, algorithms=["HS256"])  
        schedule_id = qr_payload.get('schedule_id')  
        schedule = Schedule.objects.select_related('room', 'class_instance').get(id=schedule_id)  
    except jwt.ExpiredSignatureError:  
        return Response({'error': 'Mã QR đã hết hạn.'}, status=status.HTTP_400_BAD_REQUEST)  
    except (jwt.InvalidTokenError, Schedule.DoesNotExist):  
        return Response({'error': 'Mã QR không hợp lệ.'}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === SECURITY CHECKS ===  
    try:  
        current_time = timezone.now()  
        AttendanceSecurityChecker.check_time_window(schedule, current_time)  
        AttendanceSecurityChecker.check_duplicate_attendance(student, schedule)  
        AttendanceSecurityChecker.check_enrollment(student, schedule)  
    except ValidationError as e:  
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === BƯỚC 2: GPS ===  
    try:  
        class_location = (schedule.room.geo_latitude, schedule.room.geo_longitude)  
        student_location = (latitude, longitude)  
        allowed_distance = settings.ATTENDANCE_SETTINGS['GPS_DISTANCE_TOLERANCE_METERS']  
        distance = geodesic(class_location, student_location).meters  
        if distance > allowed_distance:  
            return Response({'error': f'Vị trí quá xa lớp học ({int(distance)}m).'}, status=status.HTTP_400_BAD_REQUEST)  
    except (ValueError, TypeError, AttributeError):  
        return Response({'error': 'Tọa độ GPS không hợp lệ hoặc phòng học chưa có vị trí.'}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === BƯỚC 2.5: WiFi SSID ===  
    expected_ssid = schedule.room.wifi_ssid  
    if expected_ssid:  
        if not submitted_ssid or (submitted_ssid.lower() != expected_ssid.lower()):  
            return Response({'error': f'Bạn không kết nối đúng mạng Wifi của phòng học. Yêu cầu: "{expected_ssid}".'}, status=status.HTTP_400_BAD_REQUEST)  
  
    # === BƯỚC 3: Face Recognition ===  
    stored_embedding_str = student.get_face_embedding()  
    if not stored_embedding_str:  
        return Response({'error': 'Sinh viên chưa đăng ký khuôn mặt.'}, status=status.HTTP_400_BAD_REQUEST)  
  
    try:  
        # Xử lý theo loại input  
        if face_image:  
            # Xử lý ảnh tĩnh  
            uploaded_encoding = process_static_face_image(face_image)  
            auth_methods = "QR,FACE,GPS"  
            is_live = False  # Ảnh tĩnh không có liveness  
              
        elif liveness_video:  
            # Xử lý video liveness  
            uploaded_encoding, is_live = perform_liveness_check(liveness_video)  
            if not is_live:  
                return Response({'error': 'Không phát hiện được hành động của người thật (ví dụ: nháy mắt).'}, status=status.HTTP_400_BAD_REQUEST)  
            auth_methods = "QR,FACE,GPS,LIVENESS"  
          
        if uploaded_encoding is None:  
            return Response({'error': 'Không nhận diện được khuôn mặt hợp lệ.'}, status=status.HTTP_400_BAD_REQUEST)  
  
        # So sánh face encoding  
        stored_embedding = np.fromstring(stored_embedding_str, sep=',')  
        tolerance = settings.ATTENDANCE_SETTINGS['FACE_RECOGNITION_TOLERANCE']  
        matches = face_recognition.compare_faces([stored_embedding], uploaded_encoding, tolerance=tolerance)  
          
        if not matches[0]:  
            return Response({'error': 'Khuôn mặt không khớp.'}, status=status.HTTP_400_BAD_REQUEST)  
  
    except Exception as e:  
        logger.error(f"Lỗi xử lý khuôn mặt cho user {student.user_code}: {e}")  
        return Response({'error': 'Lỗi hệ thống trong quá trình xử lý.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)  
  
    # === Lưu kết quả ===  
    attendance_record, _ = AttendanceRecord.objects.get_or_create(  
        schedule=schedule, student=student,  
        defaults={'status': 'PRESENT', 'check_in_time': timezone.now()}  
    )  
    if attendance_record.status != 'PRESENT':  
        attendance_record.status = 'PRESENT'  
        attendance_record.check_in_time = timezone.now()  
  
    attendance_record.recorded_latitude = latitude  
    attendance_record.recorded_longitude = longitude  
  
    if expected_ssid:  
        auth_methods += ",WIFI"  
    attendance_record.auth_methods = auth_methods  
    attendance_record.save()  
  
    # Log successful attendance  
    logger.info(f"Successful attendance for user {student.user_code} in class {schedule.class_instance.class_code}")  
  
    title = "Điểm danh thành công!"  
    body = f"Bạn đã điểm danh thành công cho lớp {schedule.class_instance.class_code}."  
    send_push_notification(student.id, title, body)  
  
    return Response({  
        'success': 'Điểm danh thành công!',  
        'student': student.get_full_name(),  
        'class': schedule.class_instance.class_code,  
        'time': attendance_record.check_in_time.strftime('%H:%M:%S %d-%m-%Y'),  
        'liveness_detected': is_live  
    }, status=status.HTTP_200_OK)  
  
  
# Hàm helper để xử lý ảnh tĩnh  
def process_static_face_image(face_image):  
    """Xử lý ảnh khuôn mặt tĩnh và trả về face encoding"""  
    try:  
        # Sử dụng Pillow để xử lý ảnh  
        image = Image.open(face_image)  
        image = ImageOps.exif_transpose(image)  
          
        if image.mode != 'RGB':  
            image = image.convert('RGB')  
  
        image_np = np.array(image)  
        encodings = face_recognition.face_encodings(image_np)  
  
        if len(encodings) == 0:  
            raise ValueError('Không tìm thấy khuôn mặt nào trong ảnh.')  
        if len(encodings) > 1:  
            raise ValueError('Phát hiện nhiều hơn một khuôn mặt. Vui lòng chỉ chụp ảnh một mình.')  
          
        return encodings[0]  
          
    except Exception as e:  
        print(f"Lỗi xử lý ảnh tĩnh: {e}")  
        return None

# --- HÀM HELPER ĐỂ GIẢNG VIÊN TẠO QR TOKEN ---
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_qr_token(request, schedule_id):
    user = request.user
    if user.role != 'instructor':
         return Response({'error': 'Chỉ giảng viên mới có quyền tạo mã QR.'}, status=status.HTTP_403_FORBIDDEN)
    
    try:
        # [TINH CHỈNH #2] Cho phép GV chính hoặc người phụ trách buổi học tạo mã
        schedule = Schedule.objects.select_related('class_instance').get(
            Q(id=schedule_id),
            Q(instructor=user) | Q(class_instance__instructor=user)
        )
    except Schedule.DoesNotExist:
        return Response({'error': 'Lịch học không tồn tại hoặc bạn không có quyền tạo mã cho buổi học này.'}, status=status.HTTP_404_NOT_FOUND)

    # [TINH CHỈNH #3] Lấy tham số từ settings.py
    lifetime_minutes = settings.ATTENDANCE_SETTINGS['QR_TOKEN_LIFETIME_MINUTES']
    payload = {
        'schedule_id': schedule.id,
        'exp': datetime.utcnow() + timedelta(minutes=lifetime_minutes),
        'iat': datetime.utcnow()
    }
    qr_token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")

    return Response({'qr_token': qr_token}, status=status.HTTP_200_OK)


# --- CÁC API DÀNH CHO SINH VIÊN ---

# API 1: Đăng ký khuôn mặt (PHIÊN BẢN CUỐI CÙNG - XỬ LÝ XOAY ẢNH)
class FaceRegistrationView(APIView):  
    permission_classes = [IsAuthenticated]  
  
    @rate_limit_face_registration(max_attempts=5, window_minutes=60)  
    def post(self, request, *args, **kwargs):  
        student = request.user  
        face_image_file = request.FILES.get('face_image')  
        overwrite = request.query_params.get('overwrite', 'false').lower() == 'true'  
  
        # Kiểm tra xem user đã có face embedding chưa  
        if student.has_face_embedding() and not overwrite:  
            return Response(  
                {'error': 'Khuôn mặt đã được đăng ký. Để cập nhật, vui lòng thêm tham số ?overwrite=true vào URL.'},   
                status=status.HTTP_409_CONFLICT  
            )  
  
        if not face_image_file:  
            return Response({'error': 'Vui lòng tải lên một ảnh.'}, status=status.HTTP_400_BAD_REQUEST)  
  
        # Kiểm tra kích thước file (tối đa 5MB)  
        if face_image_file.size > 5 * 1024 * 1024:  
            return Response({'error': 'Kích thước ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 5MB.'}, status=status.HTTP_400_BAD_REQUEST)  
  
        # Kiểm tra định dạng file  
        allowed_formats = ['image/jpeg', 'image/jpg', 'image/png']  
        if face_image_file.content_type not in allowed_formats:  
            return Response({'error': 'Định dạng ảnh không được hỗ trợ. Vui lòng sử dụng JPEG hoặc PNG.'}, status=status.HTTP_400_BAD_REQUEST)  
  
        try:  
            # 1. Dùng Pillow để mở file ảnh từ đối tượng trong bộ nhớ của Django  
            image = Image.open(face_image_file)  
  
            # 2. Xử lý vấn đề xoay ảnh từ EXIF data của điện thoại  
            image = ImageOps.exif_transpose(image)  
              
            # 3. Chuyển ảnh sang định dạng RGB  
            if image.mode != 'RGB':  
                image = image.convert('RGB')  
  
            # 4. Chuyển ảnh Pillow thành một mảng NumPy  
            image_np = np.array(image)  
              
            # 5. Đưa mảng NumPy vào face_recognition  
            encodings = face_recognition.face_encodings(image_np)  
  
            if len(encodings) == 0:  
                return Response({'error': 'Không tìm thấy khuôn mặt nào trong ảnh. Vui lòng thử lại với ảnh rõ nét và đủ sáng.'}, status=status.HTTP_400_BAD_REQUEST)  
            if len(encodings) > 1:  
                return Response({'error': 'Phát hiện nhiều hơn một khuôn mặt. Vui lòng chỉ chụp ảnh một mình.'}, status=status.HTTP_400_BAD_REQUEST)  
              
            # Sử dụng method mới để lưu face embedding đã mã hóa  
            embedding_str = ','.join(map(str, encodings[0]))  
            student.set_face_embedding(embedding_str)  
            student.save(update_fields=['face_embedding'])  
  
            return Response({'success': 'Đăng ký/Cập nhật khuôn mặt thành công!'}, status=status.HTTP_200_OK)  
  
        except Exception as e:  
            print(f"Lỗi đăng ký khuôn mặt: {e}")  
            return Response({'error': f'Lỗi hệ thống trong quá trình xử lý ảnh: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class MySchedulesView(APIView):  
    permission_classes = [IsAuthenticated]  
  
    def get(self, request, *args, **kwargs):  
        user = request.user  
        print(f"🔍 [BACKEND] User: {user.user_code} (ID: {user.id})")  
          
        if user.role != 'student':  
            return Response({'error': 'Chỉ sinh viên mới có lịch học.'}, status=status.HTTP_403_FORBIDDEN)  
          
        # Kiểm tra enrollment trước  
        enrollments = Enrollment.objects.filter(student=user)  
        print(f"📋 [BACKEND] Found {enrollments.count()} enrollments for user")  
        for enrollment in enrollments:  
            print(f"  - Class: {enrollment.class_instance.class_code}")  
          
        today = date.today()  
        filter_option = request.query_params.get('filter', None)  
        print(f"🔍 [BACKEND] Filter: {filter_option}, Today: {today}, Weekday: {today.isoweekday()}")  
  
        # Query với debug  
        schedules = Schedule.objects.filter(  
            class_instance__enrollment__student=user  
        ).select_related(  
            'room', 'instructor', 'class_instance__course', 'class_instance__instructor'  
        ).distinct()  
          
        print(f"📊 [BACKEND] Base query found {schedules.count()} schedules")  
          
        # Debug từng schedule  
        for schedule in schedules:  
            print(f"  - Schedule ID: {schedule.id}, Class: {schedule.class_instance.class_code}")  
            print(f"    Day: {schedule.day_of_week}, Type: {schedule.schedule_type}")  
  
        if filter_option == 'today':  
            day_of_week = today.isoweekday() + 1  
            print(f"📅 [BACKEND] Filtering for day_of_week: {day_of_week}")  
            schedules = schedules.filter(  
                Q(schedule_type='RECURRING', day_of_week=day_of_week) |   
                Q(schedule_type='ONE_TIME', schedule_date=today)  
            )  
        elif filter_option == 'this_week':  
            start_of_week = today - timedelta(days=today.weekday())  
            end_of_week = start_of_week + timedelta(days=6)  
            schedules = schedules.filter(  
                Q(schedule_type='RECURRING') |   
                Q(schedule_type='ONE_TIME', schedule_date__range=[start_of_week, end_of_week])  
            )  
          
        print(f"📊 [BACKEND] After filter: {schedules.count()} schedules")  
        schedules = schedules.order_by('day_of_week', 'start_time')  
        serializer = ScheduleSerializer(schedules, many=True)  
        return Response(serializer.data, status=status.HTTP_200_OK)

# API 3: Lấy danh sách các lớp giảng viên dạy
class MyClassesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        if user.role != 'instructor':
            return Response({'error': 'Chỉ giảng viên mới có lớp học.'}, status=status.HTTP_403_FORBIDDEN)
        
        # Lấy các lớp mà giảng viên này là giảng viên chính HOẶC có phụ trách ít nhất 1 buổi học
        classes = Class.objects.filter(
            Q(instructor=user) | Q(schedule__instructor=user)
        ).select_related('course', 'instructor').distinct()

        serializer = ClassSerializer(classes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

# API 4: Lấy báo cáo điểm danh của một lớp
class ClassAttendanceReportView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, class_id, *args, **kwargs):
        user = request.user
        
        # [NÂNG CẤP] Logic kiểm tra quyền đã được tích hợp vào truy vấn ở dưới
        # để cho phép cả GV chính và Trợ giảng xem báo cáo
        schedules = Schedule.objects.filter(
            Q(class_instance_id=class_id),
            Q(class_instance__instructor=user) | Q(instructor=user)
        ).prefetch_related(
            'attendancerecord_set__student' # Tối ưu truy vấn lồng nhau
        ).distinct().order_by('schedule_date', 'start_time')

        if not schedules.exists():
             return Response({'error': 'Lớp học không tồn tại hoặc bạn không có quyền xem báo cáo này.'}, status=status.HTTP_404_NOT_FOUND)

        # [NÂNG CẤP #3] Sử dụng serializer mới để có cấu trúc JSON chuẩn
        serializer = ScheduleWithAttendanceSerializer(schedules, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
# --- HÀM HELPER ĐỂ KIỂM TRA LIVENESS TỪ VIDEO (PHIÊN BẢN NÂNG CẤP) ---
def perform_liveness_check(video_file):  
    eye_cascade_path = os.path.join(settings.BASE_DIR, 'cascades', 'haarcascade_eye.xml')  
    if not os.path.exists(eye_cascade_path):  
        print(f"Lỗi: Không tìm thấy file haarcascade_eye.xml tại {eye_cascade_path}")  
        return None, False  
  
    eye_cascade = cv2.CascadeClassifier(eye_cascade_path)  
      
    # Sử dụng tempfile để tạo file tạm an toàn  
    with tempfile.NamedTemporaryFile(suffix=".mp4", delete=True) as temp_video_file:  
        for chunk in video_file.chunks():  
            temp_video_file.write(chunk)  
        temp_video_file.flush()  
  
        cap = cv2.VideoCapture(temp_video_file.name)  
          
        # Các biến theo dõi trạng thái mắt  
        eyes_detected_frames = 0  
        no_eyes_detected_frames = 0  
        blink_sequences = 0  # Đếm số lần nháy mắt hoàn chỉnh  
        face_encoding_from_video = None  
          
        # Trạng thái để theo dõi chu kỳ nháy mắt  
        eyes_open = False  
        eyes_closed = False  
        min_blink_frames = 2  # Tối thiểu 2 frame mắt đóng để tính là nháy  
        min_open_frames = 3   # Tối thiểu 3 frame mắt mở để reset trạng thái  
          
        FRAME_LIMIT = 90  # Xử lý tối đa 90 frames (khoảng 3 giây)  
        frame_count = 0  
  
        while cap.isOpened() and frame_count < FRAME_LIMIT:  
            ret, frame = cap.read()  
            if not ret:  
                break  
              
            frame_count += 1  
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)  
            eyes = eye_cascade.detectMultiScale(gray, 1.1, 4)  
  
            # Logic cải thiện để phát hiện nháy mắt  
            if len(eyes) > 0:  
                # Mắt được phát hiện (mắt mở)  
                eyes_detected_frames += 1  
                no_eyes_detected_frames = 0  
                  
                # Nếu trước đó mắt đóng đủ lâu, đây là kết thúc một chu kỳ nháy  
                if eyes_closed and no_eyes_detected_frames >= min_blink_frames:  
                    blink_sequences += 1  
                    print(f"Frame {frame_count}: Phát hiện nháy mắt #{blink_sequences}")  
                    eyes_closed = False  
                  
                # Đánh dấu mắt đang mở nếu đủ frame liên tiếp  
                if eyes_detected_frames >= min_open_frames:  
                    eyes_open = True  
                      
            else:  
                # Không phát hiện mắt (mắt đóng hoặc không nhìn thấy)  
                no_eyes_detected_frames += 1  
                eyes_detected_frames = 0  
                  
                # Nếu trước đó mắt mở và giờ đóng đủ lâu  
                if eyes_open and no_eyes_detected_frames >= min_blink_frames:  
                    eyes_closed = True  
                    eyes_open = False  
  
            print(f"Frame {frame_count}: eyes={len(eyes)}, blink_sequences={blink_sequences}, eyes_open={eyes_open}, eyes_closed={eyes_closed}")  
  
            # Trích xuất face encoding (chỉ xử lý một số frame để tiết kiệm thời gian)  
            if face_encoding_from_video is None and frame_count % 5 == 0:  
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)  
                face_locations = face_recognition.face_locations(rgb_frame, model="hog")  
                if face_locations:  
                    face_encodings = face_recognition.face_encodings(rgb_frame, face_locations)  
                    if len(face_encodings) == 1:  
                        face_encoding_from_video = face_encodings[0]  
          
        cap.release()  
      
    # Logic liveness cải thiện: cần có ít nhất 1 lần nháy mắt VÀ có face encoding  
    is_live = blink_sequences >= 1 and face_encoding_from_video is not None  
      
    print(f"Kết quả liveness check: blink_sequences={blink_sequences}, has_face_encoding={face_encoding_from_video is not None}, is_live={is_live}")  
      
    return face_encoding_from_video, is_live

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_fcm_token(request):
    user = request.user
    token = request.data.get('fcm_token')

    if not token:
        return Response({'error': 'FCM token is required.'}, status=status.HTTP_400_BAD_REQUEST)

    user.fcm_token = token
    user.save(update_fields=['fcm_token'])
    return Response({'success': 'FCM token registered successfully.'}, status=status.HTTP_200_OK)

# API để lấy thông tin chi tiết của một lớp học, bao gồm cả lịch học
class ClassDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, class_id, *args, **kwargs):
        try:
            # Tương tự các API khác, đảm bảo giảng viên có quyền xem lớp này
            class_instance = Class.objects.prefetch_related(
                'schedule_set__room', 'schedule_set__instructor'
            ).filter(
                Q(id=class_id),
                Q(instructor=request.user) | Q(schedule__instructor=request.user)
            ).first()
            if not class_instance:
                return Response({'error': 'Lớp học không tồn tại hoặc bạn không có quyền xem.'}, status=status.HTTP_404_NOT_FOUND)

        except Class.DoesNotExist:
            return Response({'error': 'Lớp học không tồn tại hoặc bạn không có quyền xem.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = ClassDetailSerializer(class_instance)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        serializer = UserProfileSerializer(user)
        return Response(serializer.data)
    
class AbsenceRequestViewSet(viewsets.ModelViewSet):  
    queryset = AbsenceRequest.objects.all().order_by('-created_at')  
    permission_classes = [IsAuthenticated]  
  
    def get_serializer_class(self):  
        if self.action == 'create':  
            return AbsenceRequestCreateSerializer  
        return AbsenceRequestSerializer  
  
    def list(self, request, *args, **kwargs):  
        user = request.user  
        queryset = self.get_queryset()  
  
        if user.role == 'student':  
            queryset = queryset.filter(student=user)  
        elif user.role == 'instructor':  
            class_id = request.query_params.get('class_id')  
            if class_id:  
                try:  
                    # Chuyển đổi class_id sang số nguyên và kiểm tra  
                    class_id = int(class_id)  
                    queryset = queryset.filter(schedule__class_instance_id=class_id)  
                except ValueError:  
                    # Trả về lỗi nếu class_id không phải là số hợp lệ  
                    return Response(  
                        {'error': 'class_id không hợp lệ. Phải là một số nguyên.'},  
                        status=status.HTTP_400_BAD_REQUEST  
                    )  
            else:  
                # Nếu không có class_id, lấy tất cả các đơn thuộc các lớp GV dạy  
                class_ids_taught = Class.objects.filter(  
                    Q(instructor=user) | Q(schedule__instructor=user)  
                ).values_list('id', flat=True).distinct()  
                queryset = queryset.filter(schedule__class_instance__id__in=class_ids_taught)  
        elif user.role == 'admin':  
            # Admin có thể lọc theo class_id nếu muốn  
            class_id = request.query_params.get('class_id')  
            if class_id:  
                try:  
                    class_id = int(class_id)  
                    queryset = queryset.filter(schedule__class_instance_id=class_id)  
                except ValueError:  
                    return Response(  
                        {'error': 'class_id không hợp lệ. Phải là một số nguyên.'},  
                        status=status.HTTP_400_BAD_REQUEST  
                    )  
          
        # Thêm prefetch_related để tối ưu truy vấn, tránh N+1 query  
        queryset = queryset.select_related('student', 'schedule__class_instance__course', 'schedule__room')  
        serializer = self.get_serializer(queryset, many=True)  
        return Response(serializer.data)  

    # Ghi đè hàm create để tự động gán sinh viên
    def perform_create(self, serializer):
        # Chỉ sinh viên mới được tạo đơn
        if self.request.user.role != 'student':
            raise permissions.PermissionDenied("Chỉ sinh viên mới có thể tạo đơn xin phép.")

        # Kiểm tra xem sinh viên có thực sự vắng buổi học này không
        schedule = serializer.validated_data['schedule']
        try:
            record = AttendanceRecord.objects.get(student=self.request.user, schedule=schedule, status='ABSENT')
        except AttendanceRecord.DoesNotExist:
            raise serializers.ValidationError("Bạn không thể xin phép cho một buổi học mà bạn không vắng mặt.")

        serializer.save(student=self.request.user)

    # Thêm action tùy chỉnh để lấy số lượng đơn chờ duyệt  
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])  
    def pending_count(self, request):  
        user = request.user  
        if user.role == 'student':  
            # Sinh viên chỉ xem đơn của mình  
            count = AbsenceRequest.objects.filter(student=user, status='PENDING').count()  
        elif user.role == 'instructor':  
            # Giảng viên xem đơn của các lớp mình dạy  
            class_ids_taught = Class.objects.filter(  
                Q(instructor=user) | Q(schedule__instructor=user)  
            ).values_list('id', flat=True).distinct()  
            count = AbsenceRequest.objects.filter(  
                schedule__class_instance__id__in=class_ids_taught,  
                status='PENDING'  
            ).count()  
        else: # Admin có thể xem tất cả  
            count = AbsenceRequest.objects.filter(status='PENDING').count()  
          
        return Response({'count': count}, status=status.HTTP_200_OK)

    # Tạo một action tùy chỉnh để duyệt đơn
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def approve(self, request, pk=None):
        absence_request = self.get_object()
        user = request.user

        # Kiểm tra quyền duyệt
        is_class_instructor = absence_request.schedule.class_instance.instructor == user
        is_schedule_instructor = absence_request.schedule.instructor == user
        if not (is_class_instructor or is_schedule_instructor):
            return Response({'error': 'Bạn không có quyền duyệt đơn này.'}, status=status.HTTP_403_FORBIDDEN)

        absence_request.status = 'APPROVED'
        absence_request.save()

        # Cập nhật bản ghi điểm danh tương ứng
        AttendanceRecord.objects.filter(
            student=absence_request.student,
            schedule=absence_request.schedule
        ).update(status='EXCUSED')

        return Response({'status': 'Đơn đã được duyệt.'})

    # Tạo một action tùy chỉnh để từ chối đơn
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        # ... (Tương tự hàm approve, nhưng set status='REJECTED')
        absence_request = self.get_object()
        user = request.user

        is_class_instructor = absence_request.schedule.class_instance.instructor == user
        is_schedule_instructor = absence_request.schedule.instructor == user
        if not (is_class_instructor or is_schedule_instructor):
            return Response({'error': 'Bạn không có quyền từ chối đơn này.'}, status=status.HTTP_403_FORBIDDEN)

        absence_request.status = 'REJECTED'
        absence_request.save()
        return Response({'status': 'Đơn đã bị từ chối.'})
    
class MyAttendanceHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, class_id, *args, **kwargs):
        user = request.user
        if user.role != 'student':
            return Response({'error': 'Chỉ sinh viên mới có lịch sử điểm danh.'}, status=status.HTTP_403_FORBIDDEN)

        # Đảm bảo sinh viên này thực sự có trong lớp học
        is_enrolled = Enrollment.objects.filter(student=user, class_instance_id=class_id).exists()
        if not is_enrolled:
            return Response({'error': 'Bạn không có trong lớp học này.'}, status=status.HTTP_404_NOT_FOUND)

        records = AttendanceRecord.objects.filter(
            student=user,
            schedule__class_instance_id=class_id
        ).select_related('schedule', 'schedule__room').order_by('-schedule__schedule_date', '-schedule__start_time')

        # Chúng ta cần thêm trạng thái của đơn xin phép vào dữ liệu trả về
        # Thay vì dùng serializer, chúng ta sẽ tự xây dựng response để linh hoạt hơn
        data = []
        for record in records:
            absence_request = AbsenceRequest.objects.filter(student=user, schedule=record.schedule).first()
            data.append({
                'id': record.id,
                'status': record.status,
                'schedule': {
                    'id': record.schedule.id,
                    'date': record.schedule.schedule_date,
                    'day_of_week': record.schedule.day_of_week,
                    'start_time': record.schedule.start_time,
                    'group_code': record.schedule.group_code,
                },
                'absence_request_status': absence_request.status if absence_request else None
            })

        return Response(data)
    
class MyEnrolledClassesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        if user.role != 'student':
            return Response({'error': 'Chỉ sinh viên mới có lớp học đăng ký.'}, status=status.HTTP_403_FORBIDDEN)

        enrollments = Enrollment.objects.filter(student=user).select_related(
            'class_instance__course', 'class_instance__instructor'
        )
        serializer = EnrolledClassSerializer(enrollments, many=True)
        return Response(serializer.data)
    
class InstructorDashboardStatsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        if user.role != 'instructor':
            return Response({'error': 'Chỉ giảng viên mới có dashboard.'}, status=status.HTTP_403_FORBIDDEN)

        # Lấy các lớp giảng viên dạy trong học kỳ này (giả định)
        classes_taught = Class.objects.filter(
            Q(instructor=user) | Q(schedule__instructor=user)
        ).distinct()

        class_ids = classes_taught.values_list('id', flat=True)

        # 1. Tổng số sinh viên
        total_students = Enrollment.objects.filter(class_instance_id__in=class_ids).values('student').distinct().count()

        # 2. Tỷ lệ chuyên cần trong 30 ngày qua
        thirty_days_ago = timezone.now() - timedelta(days=30)
        recent_records = AttendanceRecord.objects.filter(
            schedule__class_instance_id__in=class_ids,
            schedule__created_at__gte=thirty_days_ago
        )

        total_present = recent_records.filter(status__in=['PRESENT', 'LATE', 'EXCUSED']).count()
        total_records = recent_records.count()
        attendance_rate = (total_present / total_records * 100) if total_records > 0 else 100

        # 3. Số đơn xin phép đang chờ duyệt
        pending_requests = AbsenceRequest.objects.filter(
            schedule__class_instance_id__in=class_ids,
            status='PENDING'
        ).count()

        # 4. Dữ liệu cho biểu đồ: Tỷ lệ chuyên cần 7 ngày gần nhất
        chart_data = {
            'labels': [],
            'data': []
        }
        for i in range(6, -1, -1):
            day = timezone.now().date() - timedelta(days=i)
            daily_records = AttendanceRecord.objects.filter(
                schedule__class_instance_id__in=class_ids,
                schedule__schedule_date=day # Giả định lịch học có ngày cụ thể
            )
            daily_total = daily_records.count()
            daily_present = daily_records.filter(status__in=['PRESENT', 'LATE', 'EXCUSED']).count()
            daily_rate = (daily_present / daily_total * 100) if daily_total > 0 else 0

            chart_data['labels'].append(day.strftime('%d/%m'))
            chart_data['data'].append(round(daily_rate, 1))

        return Response({
            'total_classes': classes_taught.count(),
            'total_students': total_students,
            'recent_attendance_rate': round(attendance_rate, 1),
            'pending_requests': pending_requests,
            'chart_data': chart_data
        })
    
class DetailedReportViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AttendanceRecordSerializer # Dùng lại serializer đã có
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend]
    filterset_class = AttendanceRecordFilter

    def get_queryset(self):
        # Lấy class_id từ URL
        class_id = self.kwargs.get('class_pk')
        # Kiểm tra quyền
        if not class_id or not Class.objects.filter(Q(id=class_id), Q(instructor=self.request.user) | Q(schedule__instructor=self.request.user)).exists():
             raise permissions.PermissionDenied("Lớp học không tồn tại hoặc bạn không có quyền xem báo cáo này.")

        return AttendanceRecord.objects.filter(
            schedule__class_instance_id=class_id
        ).select_related('student', 'schedule').order_by('-schedule__schedule_date')

    @action(detail=False, methods=['get'])
    def export(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        # Trả về dữ liệu đã được làm phẳng để frontend dễ dàng tạo file Excel
        data_to_export = []
        for record in queryset:
            data_to_export.append({
                'MSSV': record.student.user_code,
                'Họ và tên': record.student.get_full_name(),
                'Ngày': record.schedule.schedule_date,
                'Buổi học': record.schedule.group_code,
                'Trạng thái': record.get_status_display(),
                'Giờ điểm danh': record.check_in_time.strftime('%H:%M:%S') if record.check_in_time else '',
                'Ghi chú': record.notes
            })
        return Response(data_to_export)

class ClassViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Class.objects.all()
    serializer_class = ClassSerializer


class PasswordResetRequestView(APIView):
    permission_classes = [permissions.AllowAny]  # Ai cũng có thể truy cập

    def post(self, request, *args, **kwargs):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            try:
                user = User.objects.get(email=email)

                # Tạo token reset
                token = default_token_generator.make_token(user)
                uidb64 = urlsafe_base64_encode(force_bytes(user.pk))

                # [CẬP NHẬT] Tạo link reset cho web và mobile
                web_reset_link = f"http://localhost:3000/reset-password/{uidb64}/{token}/"
                mobile_deep_link = f"mfa-ctut://reset-password/{uidb64}/{token}/"

                # [CẬP NHẬT] Soạn nội dung email gửi cả hai link
                email_body = f"""\
Chào {user.get_full_name()},

Bạn hoặc ai đó vừa yêu cầu đặt lại mật khẩu cho tài khoản CTUT của bạn.

👉 Nếu bạn đang dùng trình duyệt web, hãy bấm vào link sau:
{web_reset_link}

📱 Nếu bạn đang dùng ứng dụng di động, hãy mở link này trên điện thoại:
{mobile_deep_link}

Nếu bạn không yêu cầu việc này, hãy bỏ qua email này.
"""

                send_mail(
                    'Yêu cầu Đặt lại Mật khẩu',
                    email_body,
                    'noreply@ctut.edu.vn',
                    [user.email],
                    fail_silently=False,
                )

            except User.DoesNotExist:
                # Không tiết lộ người dùng có tồn tại hay không
                pass

            return Response(
                {'success': 'Nếu email của bạn tồn tại trong hệ thống, một link đặt lại mật khẩu đã được gửi.'},
                status=status.HTTP_200_OK
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetConfirmView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.user
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({'success': 'Mật khẩu đã được đặt lại thành công.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            user = request.user
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({'success': 'Đổi mật khẩu thành công.'}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
# Thêm ViewSet này vào cuối file
class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet để xem danh sách thông báo và đánh dấu đã đọc.
    ReadOnlyModelViewSet chỉ cho phép các hành động GET (list, retrieve).
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Mỗi user chỉ được xem thông báo của chính mình
        return Notification.objects.filter(user=self.request.user)

    # Action để đánh dấu một thông báo là đã đọc
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'Đã đánh dấu là đã đọc'})
    
class LiveAttendanceStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, schedule_id, *args, **kwargs):
        user = request.user
        
        # Kiểm tra xem giảng viên có quyền xem buổi học này không
        try:
            schedule = Schedule.objects.get(
                Q(id=schedule_id),
                Q(instructor=user) | Q(class_instance__instructor=user)
            )
        except Schedule.DoesNotExist:
            return Response({'error': 'Buổi học không tồn tại hoặc bạn không có quyền xem.'}, status=status.HTTP_404_NOT_FOUND)

        # Lấy các bản ghi điểm danh thành công (có mặt hoặc đi trễ)
        records = AttendanceRecord.objects.filter(
            schedule=schedule,
            status__in=['PRESENT', 'LATE']
        ).select_related('student').order_by('check_in_time')
        
        serializer = LiveAttendanceRecordSerializer(records, many=True)
        return Response(serializer.data)
    
class SendNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, class_id, *args, **kwargs):
        user = request.user
        title = request.data.get('title')
        body = request.data.get('body')

        if not title or not body:
            return Response({'error': 'Tiêu đề và nội dung không được để trống.'}, status=status.HTTP_400_BAD_REQUEST)

        # Kiểm tra quyền
        if not Class.objects.filter(Q(id=class_id), Q(instructor=user) | Q(schedule__instructor=user)).exists():
            return Response({'error': 'Lớp học không tồn tại hoặc bạn không có quyền gửi thông báo.'}, status=status.HTTP_403_FORBIDDEN)

        # [QUAN TRỌNG] Gọi task để chạy ở chế độ nền
        # .delay() sẽ gửi công việc vào hàng đợi và trả về kết quả ngay lập tức
        send_notification_to_class_task.delay(class_id, title, body)

        # Phản hồi ngay cho giảng viên, không cần chờ gửi xong
        return Response({'success': 'Yêu cầu gửi thông báo đã được tiếp nhận và đang được xử lý.'}, status=status.HTTP_202_ACCEPTED)
    
class GoogleLoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        token = request.data.get('token')
        if not token:
            return Response({'error': 'Không có token nào được cung cấp.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Xác thực token với Google
            idinfo = id_token.verify_oauth2_token(token, google_requests.Request(), settings.GOOGLE_OAUTH2_CLIENT_ID)

            email = idinfo['email']
            email_domain = email.split('@')[1]

            # Kiểm tra domain email
            if email_domain not in settings.ALLOWED_EMAIL_DOMAINS:
                return Response({'error': f'Tài khoản với domain @{email_domain} không được phép truy cập.'}, status=status.HTTP_403_FORBIDDEN)

            # Tìm hoặc tạo người dùng mới
            try:
                user = User.objects.get(email=email)
                # Đây là luồng đăng nhập
            except User.DoesNotExist:
                # Đây là luồng đăng ký
                user_code_from_email = email.split('@')[0]
                role = 'student' if 'student' in email_domain else 'instructor'

                user = User.objects.create(
                    user_code=user_code_from_email,
                    email=email,
                    first_name=idinfo.get('given_name', ''),
                    last_name=idinfo.get('family_name', ''),
                    role=role,
                    is_active=True
                )
                # Chúng ta không cần set password vì họ sẽ luôn đăng nhập qua Google
                user.set_unusable_password()
                user.save()

            # Tạo token của hệ thống chúng ta và trả về cho frontend
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            })

        except ValueError as e:
            # Token không hợp lệ
            print(f"Lỗi xác thực Google Token: {e}")
            return Response({'error': 'Google token không hợp lệ.'}, status=status.HTTP_400_BAD_REQUEST)
        
class FacultyListView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request, *args, **kwargs):
        faculties = Faculty.objects.all()
        serializer = FacultySerializer(faculties, many=True)
        return Response(serializer.data)

class AdministrativeClassListView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request, *args, **kwargs):
        # Cho phép lọc lớp theo khoa, ví dụ: /api/v1/admin-classes/?faculty_id=1
        faculty_id = request.query_params.get('faculty_id')
        classes = AdministrativeClass.objects.all()
        if faculty_id:
            classes = classes.filter(faculty_id=faculty_id)
        serializer = AdministrativeClassSerializer(classes, many=True)
        return Response(serializer.data)
    
@api_view(['GET'])  
def health_check(request):  
    """Health check endpoint cho monitoring"""  
    health_status = {  
        'status': 'healthy',  
        'timestamp': timezone.now().isoformat(),  
        'services': {}  
    }  
      
    # Kiểm tra database  
    try:  
        with connection.cursor() as cursor:  
            cursor.execute("SELECT 1")  
        health_status['services']['database'] = 'healthy'  
    except Exception as e:  
        health_status['services']['database'] = f'unhealthy: {str(e)}'  
        health_status['status'] = 'unhealthy'  
      
    # Kiểm tra Redis cache  
    try:  
        cache.set('health_check', 'test', 10)  
        cache.get('health_check')  
        health_status['services']['cache'] = 'healthy'  
    except Exception as e:  
        health_status['services']['cache'] = f'unhealthy: {str(e)}'  
        health_status['status'] = 'unhealthy'  
      
    # Kiểm tra face encryption  
    try:  
        from .encryption import face_encryption  
        test_data = "test_embedding_data"  
        encrypted = face_encryption.encrypt_embedding(test_data)  
        decrypted = face_encryption.decrypt_embedding(encrypted)  
        if decrypted == test_data:  
            health_status['services']['encryption'] = 'healthy'  
        else:  
            health_status['services']['encryption'] = 'unhealthy: encryption/decryption mismatch'  
            health_status['status'] = 'unhealthy'  
    except Exception as e:  
        health_status['services']['encryption'] = f'unhealthy: {str(e)}'  
        health_status['status'] = 'unhealthy'  
      
    status_code = 200 if health_status['status'] == 'healthy' else 503  
    return Response(health_status, status=status_code)

# Class cho giảng viên  
class InstructorSchedulesView(APIView):    
    permission_classes = [IsAuthenticated]    
  
    def get(self, request, *args, **kwargs):    
        user = request.user    
        if user.role != 'instructor':  
            return Response({'error': 'Chỉ giảng viên mới có quyền xem lịch phụ trách.'}, status=status.HTTP_403_FORBIDDEN)  
              
        # Lấy tất cả lịch học mà giảng viên này phụ trách    
        schedules = Schedule.objects.filter(instructor=user).select_related('class_instance', 'room').order_by('day_of_week', 'start_time')    
        serializer = ScheduleSerializer(schedules, many=True)    
        return Response(serializer.data, status=status.HTTP_200_OK) 
    
class UserViewSet(viewsets.ReadOnlyModelViewSet): # ReadOnlyModelViewSet để chỉ cho phép GET  
    queryset = User.objects.all().order_by('user_code')  
    permission_classes = [IsAuthenticated] # Chỉ người dùng đã xác thực mới được truy cập  
    serializer_class = UserProfileSerializer  

    def get_queryset(self):  
        queryset = super().get_queryset()  
        # Cho phép lọc theo vai trò  
        role = self.request.query_params.get('role', None)  
        if role is not None:  
            queryset = queryset.filter(role=role)  
        return queryset