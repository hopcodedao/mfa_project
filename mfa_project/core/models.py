from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from .encryption import face_encryption  

# [TINH CHỈNH] Tạo một abstract model để tái sử dụng
class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Thời gian tạo")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Cập nhật lần cuối")

    class Meta:
        abstract = True

# [BỔ SUNG] Model mới cho Khoa
class Faculty(TimeStampedModel):
    name = models.CharField(max_length=255, unique=True, verbose_name="Tên Khoa")
    description = models.TextField(blank=True, null=True, verbose_name="Mô tả")

    class Meta:
        verbose_name = "Khoa"
        verbose_name_plural = "Các Khoa"
        ordering = ['name']

    def __str__(self):
        return self.name
    
# [BỔ SUNG] Model mới cho Lớp sinh hoạt / Chi đoàn
class AdministrativeClass(TimeStampedModel):
    class_code = models.CharField(max_length=100, unique=True, verbose_name="Mã lớp sinh hoạt") # Ví dụ: KTPM2021
    faculty = models.ForeignKey(Faculty, on_delete=models.CASCADE, verbose_name="Khoa")
    year_of_admission = models.IntegerField(verbose_name="Năm nhập học")

    class Meta:
        verbose_name = "Lớp sinh hoạt"
        verbose_name_plural = "Các lớp sinh hoạt"
        ordering = ['class_code']

    def __str__(self):
        return self.class_code
    
# [THAY ĐỔI] Tạo một trình quản lý người dùng tùy chỉnh (Custom User Manager)
class CustomUserManager(BaseUserManager):
    """
    Trình quản lý tùy chỉnh để làm việc với User model không có username.
    """
    def create_user(self, user_code, email, password=None, **extra_fields):
        if not user_code:
            raise ValueError(_('The User Code must be set'))
        if not email:
            raise ValueError(_('The Email must be set'))
        
        email = self.normalize_email(email)
        user = self.model(user_code=user_code, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, user_code, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser must have is_staff=True.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser must have is_superuser=True.'))
        
        return self.create_user(user_code, email, password, **extra_fields)

# [THAY ĐỔI] Cập nhật User model
class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    USER_ROLE_CHOICES = (
        ('student', 'Sinh viên'),
        ('instructor', 'Giảng viên'),
        ('admin', 'Quản trị viên'),
    )
    
    user_code = models.CharField(max_length=20, unique=True, verbose_name="Mã người dùng (MSSV/MSGV)")
    email = models.EmailField(_('email address'), unique=True)
    first_name = models.CharField(_('first name'), max_length=150, blank=True)
    last_name = models.CharField(_('last name'), max_length=150, blank=True)
    
    role = models.CharField(max_length=20, choices=USER_ROLE_CHOICES, default='student', verbose_name="Vai trò")
    face_embedding = models.TextField(blank=True, null=True, verbose_name="Vector đặc trưng khuôn mặt (đã mã hóa)")

    faculty = models.ForeignKey(Faculty, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Khoa")

    administrative_class = models.ForeignKey(
        AdministrativeClass, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        verbose_name="Lớp sinh hoạt"
    )

    fcm_token = models.CharField(max_length=255, blank=True, null=True, verbose_name="Firebase Cloud Messaging Token")

    is_staff = models.BooleanField(default=False, verbose_name="Là nhân viên")
    is_active = models.BooleanField(default=True, verbose_name="Đang hoạt động")
    date_joined = models.DateTimeField(auto_now_add=True)

    # Gán trình quản lý tùy chỉnh
    objects = CustomUserManager()

    # Khai báo trường đăng nhập chính
    USERNAME_FIELD = 'user_code'
    # Các trường bắt buộc khi tạo user
    REQUIRED_FIELDS = ['email']

    class Meta:
        verbose_name = "Người dùng"
        verbose_name_plural = "Người dùng"

    def __str__(self):
        return self.user_code

    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()

    def get_short_name(self):
        return self.first_name
    
    def set_face_embedding(self, embedding_str):  
        """Lưu face embedding đã mã hóa"""  
        if embedding_str:  
            self.face_embedding = face_encryption.encrypt_embedding(embedding_str)  
        else:  
            self.face_embedding = None  
      
    def get_face_embedding(self):  
        """Lấy face embedding đã giải mã"""  
        if self.face_embedding:  
            return face_encryption.decrypt_embedding(self.face_embedding)  
        return None  
      
    def has_face_embedding(self):  
        """Kiểm tra user có face embedding hay không"""  
        return bool(self.face_embedding)

# --- Các model còn lại giữ nguyên như cũ ---
# (Bạn có thể copy-paste phần còn lại của file models.py cũ vào đây,
# hoặc copy toàn bộ code bên dưới vì nó không thay đổi)

class Course(TimeStampedModel):
    course_code = models.CharField(max_length=20, unique=True, verbose_name="Mã học phần")
    course_name = models.CharField(max_length=255, verbose_name="Tên học phần")
    credits = models.IntegerField(verbose_name="Số tín chỉ")
    faculty = models.ForeignKey(Faculty, on_delete=models.SET_NULL, null=True, blank=True, verbose_name="Khoa")

    class Meta:
        verbose_name = "Học phần"
        verbose_name_plural = "Các học phần"

    def __str__(self):
        return f"{self.course_code} - {self.course_name}"

class Class(TimeStampedModel):
    class_code = models.CharField(max_length=50, unique=True, verbose_name="Mã lớp học phần")
    course = models.ForeignKey(Course, on_delete=models.PROTECT, verbose_name="Học phần")
    instructor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, limit_choices_to={'role': 'instructor'}, related_name='main_classes', verbose_name="Giảng viên chính")
    academic_year = models.CharField(max_length=20, verbose_name="Năm học")
    semester = models.CharField(max_length=20, verbose_name="Học kỳ")

    class Meta:
        verbose_name = "Lớp học phần"
        verbose_name_plural = "Các lớp học phần"

    def __str__(self):
        return self.class_code

class Enrollment(TimeStampedModel):
    student = models.ForeignKey(User, on_delete=models.CASCADE, limit_choices_to={'role': 'student'}, verbose_name="Sinh viên")
    class_instance = models.ForeignKey(Class, on_delete=models.CASCADE, verbose_name="Lớp học phần")
    status = models.CharField(max_length=20, default='Enrolled', verbose_name="Trạng thái")

    class Meta:
        unique_together = ('student', 'class_instance')
        verbose_name = "Sinh viên ghi danh"
        verbose_name_plural = "Danh sách sinh viên ghi danh"

    def __str__(self):
        return f"{self.student.user_code} enrolled in {self.class_instance.class_code}"

class Room(TimeStampedModel):
    room_code = models.CharField(max_length=50, unique=True, verbose_name="Mã phòng")
    building = models.CharField(max_length=50, verbose_name="Tòa nhà")
    geo_latitude = models.DecimalField(max_digits=10, decimal_places=7, verbose_name="Vĩ độ")
    geo_longitude = models.DecimalField(max_digits=10, decimal_places=7, verbose_name="Kinh độ")
    wifi_ssid = models.CharField(max_length=100, blank=True, null=True, verbose_name="Tên Wifi")
    
    class Meta:
        verbose_name = "Phòng học"
        verbose_name_plural = "Các phòng học"

    def __str__(self):
        return f"Phòng {self.room_code} - Tòa nhà {self.building}"

class Schedule(TimeStampedModel):
    SCHEDULE_TYPE_CHOICES = (('RECURRING', 'Lịch cố định'), ('ONE_TIME', 'Lịch một lần (học bù)'))
    DAY_CHOICES = ((2, 'Thứ Hai'), (3, 'Thứ Ba'), (4, 'Thứ Tư'), (5, 'Thứ Năm'), (6, 'Thứ Sáu'), (7, 'Thứ Bảy'), (8, 'Chủ Nhật'))
    
    class_instance = models.ForeignKey(Class, on_delete=models.CASCADE, verbose_name="Lớp học phần")
    instructor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, limit_choices_to={'role': 'instructor'}, related_name='schedules_in_charge', verbose_name="Người phụ trách")
    room = models.ForeignKey(Room, on_delete=models.SET_NULL, null=True, verbose_name="Phòng học")
    group_code = models.CharField(max_length=50, default='Lý thuyết', verbose_name="Nhóm (LT/TH)")
    schedule_type = models.CharField(max_length=20, choices=SCHEDULE_TYPE_CHOICES, default='RECURRING')
    schedule_date = models.DateField(null=True, blank=True, verbose_name="Ngày học (cho lịch 1 lần)")
    day_of_week = models.IntegerField(choices=DAY_CHOICES, null=True, blank=True, verbose_name="Thứ trong tuần")
    start_time = models.TimeField(verbose_name="Giờ bắt đầu")
    end_time = models.TimeField(verbose_name="Giờ kết thúc")

    def clean(self):
        if self.start_time and self.end_time and self.end_time <= self.start_time:
            raise ValidationError(_('Giờ kết thúc phải sau giờ bắt đầu.'))
        if self.schedule_type == 'RECURRING' and self.day_of_week is None:
            raise ValidationError(_('Lịch cố định phải có Thứ trong tuần.'))
        if self.schedule_type == 'ONE_TIME' and self.schedule_date is None:
            raise ValidationError(_('Lịch một lần phải có Ngày học cụ thể.'))

    class Meta:
        verbose_name = "Lịch học"
        verbose_name_plural = "Các lịch học"

    def __str__(self):
        return f"{self.class_instance.class_code} - {self.group_code} - {self.room.room_code}"

class AttendanceRecord(TimeStampedModel):
    STATUS_CHOICES = (('PRESENT', 'Có mặt'), ('ABSENT', 'Vắng'), ('LATE', 'Đi trễ'), ('EXCUSED', 'Vắng có phép'))
    schedule = models.ForeignKey(Schedule, on_delete=models.CASCADE, verbose_name="Buổi học")
    student = models.ForeignKey(User, on_delete=models.CASCADE, limit_choices_to={'role': 'student'}, verbose_name="Sinh viên")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ABSENT', verbose_name="Trạng thái")
    check_in_time = models.DateTimeField(null=True, blank=True, verbose_name="Thời gian điểm danh")
    recorded_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    recorded_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    auth_methods = models.CharField(max_length=100, blank=True, null=True, verbose_name="Phương thức xác thực")
    notes = models.TextField(blank=True, null=True, verbose_name="Ghi chú")

    class Meta:
        verbose_name = "Bản ghi điểm danh"
        verbose_name_plural = "Các bản ghi điểm danh"

    def __str__(self):
        return f"{self.student.user_code} - {self.schedule} - {self.status}"

class AbsenceRequest(TimeStampedModel):
    STATUS_CHOICES = (('PENDING', 'Chờ duyệt'), ('APPROVED', 'Đã duyệt'), ('REJECTED', 'Từ chối'))
    student = models.ForeignKey(User, on_delete=models.CASCADE, limit_choices_to={'role': 'student'})
    schedule = models.ForeignKey(Schedule, on_delete=models.CASCADE)
    reason = models.TextField(verbose_name="Lý do")
    proof = models.FileField(upload_to='absence_proofs/', blank=True, null=True, verbose_name="File minh chứng")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    
    class Meta:
        verbose_name = "Đơn xin phép vắng"
        verbose_name_plural = "Các đơn xin phép vắng"

    def __str__(self):
        return f"Đơn xin phép của {self.student.user_code} cho buổi học {self.schedule.id}"
    
# Model để lưu trữ thông báo
class Notification(TimeStampedModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="Người nhận")
    title = models.CharField(max_length=255, verbose_name="Tiêu đề")
    body = models.TextField(verbose_name="Nội dung")
    is_read = models.BooleanField(default=False, verbose_name="Đã đọc")

    class Meta:
        verbose_name = "Thông báo"
        verbose_name_plural = "Các thông báo"
        ordering = ['-created_at']

    def __str__(self):
        return f"Thông báo cho {self.user.user_code}: {self.title}"