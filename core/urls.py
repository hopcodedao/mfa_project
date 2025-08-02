from django.urls import path
from . import views
from .views import InstructorSchedulesView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from rest_framework.routers import DefaultRouter
from rest_framework_nested import routers

from core.token_serializers import MyTokenObtainPairSerializer  
from rest_framework_simplejwt.views import TokenObtainPairView as OriginalTokenObtainPairView # Đổi tên để tránh xung đột

# Router gốc
router = DefaultRouter()
router.register(r'users', views.UserViewSet, basename='user')
router.register(r'classes', views.ClassViewSet, basename='class')
router.register(r'absence-requests', views.AbsenceRequestViewSet, basename='absence_requests')

router.register(r'notifications', views.NotificationViewSet, basename='notification')

# Nested router cho reports (theo lớp)
classes_router = routers.NestedSimpleRouter(router, r'classes', lookup='class')
classes_router.register(r'reports', views.DetailedReportViewSet, basename='class-reports')

urlpatterns = [
    # URLs xác thực
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Health check  
    path('health/', views.health_check, name='health_check'),

    # URL điểm danh
    path('attendance/check-in/', views.check_in, name='check_in'),
    
    # URL tạo QR
    path('schedules/<int:schedule_id>/generate-qr/', views.generate_qr_token, name='generate_qr'),

    # Sinh viên
    path('user/register-face/', views.FaceRegistrationView.as_view(), name='register_face'),
    path('user/my-schedules/', views.MySchedulesView.as_view(), name='my_schedules'),

    # Giảng viên
    path('user/my-classes/', views.MyClassesView.as_view(), name='my_classes'),
    path('classes/<int:class_id>/report/', views.ClassAttendanceReportView.as_view(), name='class_report'),

    # FCM
    path('user/register-fcm/', views.register_fcm_token, name='register_fcm'),

    # Thông tin chi tiết
    path('classes/<int:class_id>/details/', views.ClassDetailView.as_view(), name='class_details'),
    path('user/profile/', views.UserProfileView.as_view(), name='user_profile'),
    path('classes/<int:class_id>/my-attendance/', views.MyAttendanceHistoryView.as_view(), name='my_attendance_history'),
    path('user/my-enrollments/', views.MyEnrolledClassesView.as_view(), name='my_enrollments'),

    # Dashboard stats
    path('user/instructor-dashboard-stats/', views.InstructorDashboardStatsView.as_view(), name='instructor_dashboard_stats'),

    # Thêm vào trong list urlpatterns
    path('auth/password-reset/', views.PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('auth/password-reset/confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),

    path('auth/change-password/', views.ChangePasswordView.as_view(), name='change_password'),

    # Thêm vào trong list urlpatterns
    path('schedules/<int:schedule_id>/live-status/', views.LiveAttendanceStatusView.as_view(), name='live_attendance_status'),

    # Thêm vào trong list urlpatterns
    path('classes/<int:class_id>/send-notification/', views.SendNotificationView.as_view(), name='send_notification'),

    # Thêm vào trong list urlpatterns
    path('auth/google-login/', views.GoogleLoginView.as_view(), name='google_login'),

    path('faculties/', views.FacultyListView.as_view(), name='faculty_list'),
    
    path('admin-classes/', views.AdministrativeClassListView.as_view(), name='admin_class_list'),

    path('absence-requests/pending-count/', views.AbsenceRequestViewSet.as_view({'get': 'pending_count'}), name='absence_requests_pending_count'),

    path('token/', OriginalTokenObtainPairView.as_view(serializer_class=MyTokenObtainPairSerializer), name='token_obtain_pair'),  
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    path('user/my-schedules/', views.MySchedulesView.as_view(), name='my_schedules'),
    path('instructor/my-schedules/', InstructorSchedulesView.as_view(), name='instructor-schedules'),
]

# Gộp routes
urlpatterns += router.urls
urlpatterns += classes_router.urls
