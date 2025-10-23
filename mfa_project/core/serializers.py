from rest_framework import serializers
from .models import AbsenceRequest, User, Course, Class, Enrollment, Room, Schedule, AttendanceRecord, Faculty, AdministrativeClass

from django.contrib.auth.tokens import PasswordResetTokenGenerator
from django.utils.http import urlsafe_base64_decode
from django.utils.encoding import smart_str

from .models import Notification

# 1. Tạo một serializer đơn giản cho Faculty
class FacultySerializer(serializers.ModelSerializer):
    class Meta:
        model = Faculty
        fields = ['id', 'name']

# 1. Tạo một serializer đơn giản cho AdministrativeClass
class AdministrativeClassSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdministrativeClass
        fields = ['id', 'class_code']

# Serializer để hiển thị thông tin người dùng cơ bản
# 2. Cập nhật UserSimpleSerializer
class UserSimpleSerializer(serializers.ModelSerializer):
    faculty = FacultySerializer(read_only=True) # Thêm dòng này
    administrative_class = AdministrativeClassSerializer(read_only=True)
    class Meta:
        model = User
        fields = ['user_code', 'first_name', 'last_name', 'email', 'faculty', 'administrative_class']

# Serializer cho Phòng học
class RoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = '__all__'

# Serializer cho Học phần
class CourseSerializer(serializers.ModelSerializer):
    faculty = FacultySerializer(read_only=True)
    class Meta:
        model = Course
        fields = '__all__'

# Serializer cho Lớp học phần, có lồng thông tin Giảng viên và Học phần
class ClassSerializer(serializers.ModelSerializer):
    instructor = UserSimpleSerializer(read_only=True)
    course = CourseSerializer(read_only=True)
    class Meta:
        model = Class
        fields = ['id', 'class_code', 'academic_year', 'semester', 'instructor', 'course']

# Serializer cho Lịch học, lồng các thông tin liên quan
class ScheduleSerializer(serializers.ModelSerializer):
    room = RoomSerializer(read_only=True)
    instructor = UserSimpleSerializer(read_only=True)
    class_instance = ClassSerializer(read_only=True)

    class Meta:
        model = Schedule
        fields = ['id', 'group_code', 'day_of_week', 'start_time', 'end_time', 'schedule_type', 'schedule_date', 'room', 'instructor', 'class_instance']

class AttendanceRecordSerializer(serializers.ModelSerializer):
    student = UserSimpleSerializer(read_only=True)
    # [BỔ SUNG] Thêm dòng này để lồng thông tin của schedule vào
    schedule = ScheduleSerializer(read_only=True) 

    class Meta:
        model = AttendanceRecord
        # [BỔ SUNG] Thêm 'schedule' vào danh sách các trường
        fields = ['id', 'status', 'check_in_time', 'notes', 'student', 'schedule']

# [NÂNG CẤP #3] Serializer cho báo cáo, lồng các bản ghi điểm danh vào trong lịch học
class AttendanceRecordReportSerializer(serializers.ModelSerializer):
    student = UserSimpleSerializer(read_only=True)
    class Meta:
        model = AttendanceRecord
        fields = ['id', 'status', 'check_in_time', 'notes', 'student']

class ScheduleWithAttendanceSerializer(serializers.ModelSerializer):
    attendancerecord_set = AttendanceRecordReportSerializer(many=True, read_only=True)
    room = RoomSerializer(read_only=True)
    
    class Meta:
        model = Schedule
        fields = ['id', 'group_code', 'day_of_week', 'start_time', 'schedule_date', 'room', 'attendancerecord_set']

# Thêm vào cuối file serializers.py
class ClassDetailSerializer(serializers.ModelSerializer):
    instructor = UserSimpleSerializer(read_only=True)
    course = CourseSerializer(read_only=True)
    # Lồng danh sách lịch học vào trong thông tin của lớp
    schedule_set = ScheduleSerializer(many=True, read_only=True)

    class Meta:
        model = Class
        fields = ['id', 'class_code', 'academic_year', 'semester', 'instructor', 'course', 'schedule_set']

# 3. Cập nhật UserProfileSerializer
class UserProfileSerializer(serializers.ModelSerializer):
    faculty = FacultySerializer(read_only=True) # Thêm dòng này
    administrative_class = AdministrativeClassSerializer(read_only=True)
    class Meta:
        model = User
        fields = ['id', 'user_code', 'email', 'first_name', 'last_name', 'role', 'fcm_token', 'face_embedding', 'faculty', 'administrative_class']
        read_only_fields = ['face_embedding'] # Chỉ trả về có hay không, không trả về chuỗi vector

    # Ghi đè để chỉ trả về True/False cho face_embedding
    def to_representation(self, instance):
        representation = super().to_representation(instance)
        representation['face_embedding'] = bool(instance.face_embedding)
        return representation
    
# Serializer để hiển thị chi tiết một đơn xin phép
class AbsenceRequestSerializer(serializers.ModelSerializer):
    student = UserSimpleSerializer(read_only=True)
    schedule = ScheduleSerializer(read_only=True)

    class Meta:
        model = AbsenceRequest
        fields = '__all__'

# Serializer dùng riêng cho việc tạo mới đơn xin phép
class AbsenceRequestCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = AbsenceRequest
        fields = ['schedule', 'reason', 'proof']

# Thêm vào cuối file
class EnrolledClassSerializer(serializers.ModelSerializer):
    # Lồng thông tin chi tiết của Lớp học phần vào
    class_instance = ClassSerializer(read_only=True)
    class Meta:
        model = Enrollment
        fields = ['id', 'class_instance']


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            # Không tiết lộ thông tin tài khoản tồn tại hay không
            # Vẫn trả về thành công nhưng không gửi email
            pass
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    uidb64 = serializers.CharField(required=True)
    token = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, write_only=True, min_length=8)
    confirm_password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        # Kiểm tra xác nhận mật khẩu
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError('Mật khẩu không khớp.')

        try:
            uid = smart_str(urlsafe_base64_decode(attrs['uidb64']))
            self.user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            raise serializers.ValidationError('Link không hợp lệ.')

        if not PasswordResetTokenGenerator().check_token(self.user, attrs['token']):
            raise serializers.ValidationError('Link không hợp lệ hoặc đã hết hạn.')

        return attrs
    
class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)

    def validate_old_password(self, value):
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError("Mật khẩu cũ không chính xác.")
        return value
    
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'is_read', 'created_at']


# Serializer siêu nhẹ chỉ dành cho việc báo cáo live status
class LiveAttendanceRecordSerializer(serializers.ModelSerializer):
    # Lồng thông tin đơn giản của sinh viên
    student = UserSimpleSerializer(read_only=True)
    
    class Meta:
        model = AttendanceRecord
        fields = ['id', 'student', 'check_in_time']

# 1. Tạo một serializer đơn giản cho AdministrativeClass
class AdministrativeClassSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdministrativeClass
        fields = ['id', 'class_code']

class CourseSerializer(serializers.ModelSerializer):  
    class Meta:  
        model = Course  
        fields = '__all__'  

class ClassSerializer(serializers.ModelSerializer):  
    course = CourseSerializer(read_only=True)  
    class Meta:  
        model = Class  
        fields = '__all__'  

class RoomSerializer(serializers.ModelSerializer):  
    class Meta:  
        model = Room  
        fields = '__all__'  

class ScheduleSerializer(serializers.ModelSerializer):  
    class_instance = ClassSerializer(read_only=True)  
    room = RoomSerializer(read_only=True)  
    class Meta:  
        model = Schedule  
        fields = '__all__'  