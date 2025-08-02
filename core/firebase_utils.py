# core/firebase_utils.py

from core.models import Notification, User
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings

if not firebase_admin._apps:
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred)

def send_push_notification(user_id, title, body, data=None):
    try:
        user = User.objects.get(id=user_id)
        token = user.fcm_token

        if not token:
            print(f"[FCM] User {user_id} không có FCM token.")
            return False

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
            data=data or {}
        )
        response = messaging.send(message)

        # ✅ Lưu lại thông báo nếu gửi thành công
        Notification.objects.create(
            user=user,
            title=title,
            body=body
        )

        print(f"[FCM] Sent to {user.email}: {response}")
        return True
    except User.DoesNotExist:
        print(f"[FCM] User {user_id} không tồn tại.")
        return False
    except Exception as e:
        print(f"[FCM] Lỗi gửi push: {e}")
        return False
