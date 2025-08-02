from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import (
    User, Course, Class, Enrollment, Room, Schedule, 
    AttendanceRecord, AbsenceRequest
)

from .models import Notification
# [SỬA LỖI] Import các form tùy chỉnh mà chúng ta vừa tạo
from .forms import CustomUserCreationForm, CustomUserChangeForm
from .models import Faculty, AdministrativeClass

# Tùy chỉnh tiêu đề trang Admin
admin.site.site_header = "Hệ thống Điểm danh Thông minh CTUT"
admin.site.site_title = "Trang quản trị CTUT"
admin.site.index_title = "Chào mừng tới trang quản trị Hệ thống Điểm danh"


class CustomUserAdmin(UserAdmin):
    # [SỬA LỖI] Yêu cầu admin sử dụng các form tùy chỉnh của chúng ta
    add_form = CustomUserCreationForm
    form = CustomUserChangeForm
    
    # [SỬA LỖI] Chỉ định model của chúng ta
    model = User

    # Tùy chỉnh hiển thị danh sách
    list_display = ('user_code', 'get_full_name', 'email', 'role', 'faculty', 'is_staff', 'administrative_class')
    list_filter = ('role', 'is_staff', 'is_superuser', 'groups', 'faculty', 'administrative_class')
    search_fields = ('user_code', 'first_name', 'last_name', 'email')
    ordering = ('user_code',)

    readonly_fields = ('last_login', 'date_joined')

    # [SỬA LỖI] Định nghĩa lại hoàn toàn `fieldsets` và `add_fieldsets` 
    # để không còn chứa trường 'username' không tồn tại
    fieldsets = (
        (None, {'fields': ('user_code', 'password')}),
        ('Thông tin cá nhân', {'fields': ('first_name', 'last_name', 'email')}),
        ('Phân quyền & Tổ chức', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'role', 'faculty', 'administrative_class')
        }),
        ('Quyền hạn chi tiết', {'fields': ('groups', 'user_permissions')}),
        ('Thời gian quan trọng', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('user_code', 'email', 'password1', 'password2', 'first_name', 'last_name', 'role'),
        }),
    )

# --- Các class Admin khác giữ nguyên như cũ ---

class EnrollmentInline(admin.TabularInline):
    model = Enrollment
    extra = 1
    autocomplete_fields = ['student']
    verbose_name = "Sinh viên ghi danh"
    verbose_name_plural = "Sinh viên ghi danh trong lớp"


class ScheduleInline(admin.TabularInline):
    model = Schedule
    extra = 1
    autocomplete_fields = ['room', 'instructor']
    verbose_name = "Lịch học của lớp"
    verbose_name_plural = "Các lịch học của lớp"


class ClassAdmin(admin.ModelAdmin):
    list_display = ('class_code', 'course', 'instructor', 'academic_year', 'semester', 'get_student_count')
    list_filter = ('academic_year', 'semester', 'instructor')
    search_fields = ('class_code', 'course__course_name', 'instructor__user_code')
    inlines = [EnrollmentInline, ScheduleInline]

    def get_student_count(self, obj):
        return obj.enrollment_set.count()
    get_student_count.short_description = 'Sĩ số'


class ScheduleAdmin(admin.ModelAdmin):
    list_display = ('class_instance', 'group_code', 'room', 'instructor', 'schedule_type', 'day_of_week', 'start_time', 'end_time')
    list_filter = ('schedule_type', 'day_of_week', 'class_instance__academic_year', 'instructor', 'room')
    search_fields = ('class_instance__class_code', 'group_code', 'room__room_code')
    autocomplete_fields = ['class_instance', 'instructor', 'room']


class AttendanceRecordAdmin(admin.ModelAdmin):
    list_display = ('student', 'schedule', 'status', 'check_in_time')
    list_filter = ('status', 'schedule__class_instance__academic_year', 'schedule__schedule_date')
    search_fields = ('student__user_code', 'student__first_name', 'schedule__class_instance__class_code')
    autocomplete_fields = ['schedule', 'student']
    readonly_fields = ('schedule', 'student', 'check_in_time', 'recorded_latitude', 'recorded_longitude', 'auth_methods')

    def get_fields(self, request, obj=None):
        if obj:
            return ('schedule', 'student', 'status', 'notes', 'check_in_time', 'recorded_latitude', 'recorded_longitude', 'auth_methods')
        return super().get_fields(request, obj)


class CourseAdmin(admin.ModelAdmin):
    list_display = ('course_code', 'course_name', 'credits')
    search_fields = ('course_code', 'course_name')
    list_filter = ('faculty',)

@admin.register(Faculty)
class FacultyAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_at')
    search_fields = ('name',)


class RoomAdmin(admin.ModelAdmin):
    list_display = ('room_code', 'building', 'geo_latitude', 'geo_longitude', 'wifi_ssid')
    search_fields = ('room_code', 'building')


class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ('student', 'class_instance', 'status', 'created_at')
    search_fields = ('student__user_code', 'class_instance__class_code')
    autocomplete_fields = ['student', 'class_instance']
    list_filter = ('status', 'class_instance__academic_year')


class AbsenceRequestAdmin(admin.ModelAdmin):
    list_display = ('student', 'schedule', 'status', 'created_at')
    list_filter = ('status',)
    autocomplete_fields = ['student', 'schedule']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'body', 'created_at', 'is_read')
    list_filter = ('is_read', 'created_at')
    search_fields = ('title', 'body', 'user__user_code', 'user__first_name', 'user__last_name')
    readonly_fields = ('user', 'title', 'body', 'created_at')

# [BỔ SUNG] Đăng ký model AdministrativeClass mới
@admin.register(AdministrativeClass)
class AdministrativeClassAdmin(admin.ModelAdmin):
    list_display = ('class_code', 'faculty', 'year_of_admission')
    list_filter = ('faculty', 'year_of_admission')
    search_fields = ('class_code',)

# Đăng ký lại tất cả các model
admin.site.register(User, CustomUserAdmin)
admin.site.register(Course, CourseAdmin)
admin.site.register(Class, ClassAdmin)
admin.site.register(Enrollment, EnrollmentAdmin)
admin.site.register(Room, RoomAdmin)
admin.site.register(Schedule, ScheduleAdmin)
admin.site.register(AttendanceRecord, AttendanceRecordAdmin)
admin.site.register(AbsenceRequest, AbsenceRequestAdmin)