import django_filters
from .models import AttendanceRecord

class AttendanceRecordFilter(django_filters.FilterSet):
    start_date = django_filters.DateFilter(field_name="schedule__schedule_date", lookup_expr='gte')
    end_date = django_filters.DateFilter(field_name="schedule__schedule_date", lookup_expr='lte')
    student = django_filters.NumberFilter(field_name="student_id")

    # [BỔ SUNG] Filter theo Khoa
    # Lọc các bản ghi điểm danh mà buổi học (schedule) của nó thuộc về một lớp học phần (class_instance)
    # có môn học (course) thuộc về một khoa (faculty) có ID nhất định.
    faculty = django_filters.NumberFilter(field_name='schedule__class_instance__course__faculty_id')
    
    # [BỔ SUNG] Filter theo Lớp sinh hoạt
    # Lọc các bản ghi điểm danh mà sinh viên (student) của nó thuộc về một lớp sinh hoạt (administrative_class)
    # có ID nhất định.
    administrative_class = django_filters.NumberFilter(field_name='student__administrative_class_id')

    class Meta:
        model = AttendanceRecord
        fields = ['status', 'student', 'start_date', 'end_date','faculty', 'administrative_class']