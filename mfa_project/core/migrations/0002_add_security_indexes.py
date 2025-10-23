from django.db import migrations  
  
class Migration(migrations.Migration):  
    dependencies = [  
        ('core', '0001_initial'),  
    ]  
  
    operations = [  
        # Index cho User model  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_user_code ON core_user(user_code);",  
            reverse_sql="DROP INDEX IF EXISTS idx_user_code;"  
        ),  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_user_email ON core_user(email);",  
            reverse_sql="DROP INDEX IF EXISTS idx_user_email;"  
        ),  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_user_role ON core_user(role);",  
            reverse_sql="DROP INDEX IF EXISTS idx_user_role;"  
        ),  
          
        # Index cho AttendanceRecord model  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_attendance_student_schedule ON core_attendancerecord(student_id, schedule_id);",  
            reverse_sql="DROP INDEX IF EXISTS idx_attendance_student_schedule;"  
        ),  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_attendance_check_in_time ON core_attendancerecord(check_in_time);",  
            reverse_sql="DROP INDEX IF EXISTS idx_attendance_check_in_time;"  
        ),  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_attendance_status ON core_attendancerecord(status);",  
            reverse_sql="DROP INDEX IF EXISTS idx_attendance_status;"  
        ),  
          
        # Index cho Schedule model  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_schedule_class_instance ON core_schedule(class_instance_id);",  
            reverse_sql="DROP INDEX IF EXISTS idx_schedule_class_instance;"  
        ),  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_schedule_date_time ON core_schedule(schedule_date, start_time);",  
            reverse_sql="DROP INDEX IF EXISTS idx_schedule_date_time;"  
        ),  
          
        # Index cho Enrollment model  
        migrations.RunSQL(  
            "CREATE INDEX IF NOT EXISTS idx_enrollment_student_class ON core_enrollment(student_id, class_instance_id);",  
            reverse_sql="DROP INDEX IF EXISTS idx_enrollment_student_class;"  
        ),  
    ]