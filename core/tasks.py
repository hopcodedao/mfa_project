from celery import shared_task
from .models import Enrollment, Class
from .firebase_utils import send_push_notification

@shared_task
def send_notification_to_class_task(class_id, title, body):
    try:
        # Lấy danh sách ID của tất cả sinh viên trong lớp
        student_ids = Enrollment.objects.filter(class_instance_id=class_id).values_list('student_id', flat=True)

        # Lặp qua và gửi thông báo cho từng sinh viên
        for student_id in student_ids:
            print(f"Sending notification to student {student_id}...")
            send_push_notification(user_id=student_id, title=title, body=body)

        return f"Successfully sent notifications to {len(student_ids)} students in class {class_id}."
    except Class.DoesNotExist:
        return f"Error: Class with id {class_id} does not exist."
    except Exception as e:
        return f"An error occurred: {str(e)}"