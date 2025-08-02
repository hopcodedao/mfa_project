import os
from celery import Celery

# Đặt biến môi trường mặc định cho Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'mfa_attendance_project.settings')

app = Celery('mfa_attendance_project')

# Dùng chuỗi cấu hình từ Django settings, với tiền tố 'CELERY_'
app.config_from_object('django.conf:settings', namespace='CELERY')

# Tự động tìm tất cả các file tasks.py trong các app của bạn
app.autodiscover_tasks()