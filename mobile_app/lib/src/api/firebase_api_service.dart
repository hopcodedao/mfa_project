import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';

class FirebaseApiService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  // Hàm để lấy FCM token từ Firebase
  Future<String?> getFCMToken() async {
    try {
      // Yêu cầu quyền gửi thông báo từ người dùng (cho iOS & Android 13+)
      await _firebaseMessaging.requestPermission();
      final fcmToken = await _firebaseMessaging.getToken();
      print('--- FCM Token: $fcmToken');
      return fcmToken;
    } catch (e) {
      print('Lỗi khi lấy FCM token: $e');
      return null;
    }
  }

  // [NÂNG CAO] Lắng nghe sự kiện token được làm mới
  // và tự động cập nhật lên server
  void initTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      print('--- FCM Token được làm mới: $fcmToken');
      // Gửi token mới lên server
      _authService.registerFCMToken(fcmToken);
    }).onError((err) {
      print("Lỗi khi lắng nghe token refresh: $err");
    });
  }
}