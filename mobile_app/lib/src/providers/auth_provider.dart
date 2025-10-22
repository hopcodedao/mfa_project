import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../api/auth_service.dart';
import '../constants/app_constants.dart';
import '../services/cache_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  String? _token;
  Map<String, dynamic>? _user;
  Timer? _tokenRefreshTimer;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;

  // Login bằng username + password
  Future<void> login(String userCode, String password) async {
    try {
      await _authService.login(userCode, password);
      await fetchUserProfile();

      if (isAuthenticated) {
        await _registerDeviceToken(); // nếu có push notification
        _startTokenRefreshTimer(); // 🔁 Tự động làm mới token
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Login bằng Google
  Future<void> loginWithGoogle() async {
    try {
      await _authService.loginWithGoogle();
      await fetchUserProfile();
      _startTokenRefreshTimer();
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Cập nhật method fetchUserProfile
  Future<void> fetchUserProfile() async {
    try {
      final userProfile = await _authService.getUserProfile();
      _user = userProfile;
      _token = await _storage.read(key: 'accessToken');

      // Cache user profile
      await CacheService.cacheUserProfile(userProfile);

      notifyListeners();
    } catch (e) {
      // Nếu có lỗi, thử load từ cache
      final cachedProfile = await CacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        _user = cachedProfile;
        _token = await _storage.read(key: 'accessToken');
        notifyListeners();
      } else {
        throw Exception('Không thể tải thông tin người dùng: ${e.toString()}');
      }
    }
  }

  // Logout
  Future<void> logout() async {  
    _tokenRefreshTimer?.cancel(); // Hủy timer refresh token  
    await _storage.deleteAll(); // Xóa tất cả dữ liệu lưu trữ an toàn  
    await CacheService.clearAllCache(); // Xóa cache  
    _token = null;  
    _user = null;  
    notifyListeners();  
  }

  // Cập nhật method tryAutoLogin
  Future<bool> tryAutoLogin() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      return false;
    }

    _token = token;

    try {
      await fetchUserProfile();
      if (isAuthenticated) {
        await _registerDeviceToken();
        _startTokenRefreshTimer();
      }
      return true;
    } catch (e) {
      // Nếu auto login thất bại, clear storage
      await logout();
      return false;
    }
  }

  // Đăng ký device token nếu dùng push notification (có thể bỏ nếu không dùng)
  Future<void> _registerDeviceToken() async {
    // TODO: đăng ký FCM token nếu có
  }

  // ✅ Refresh token định kỳ mỗi 50 phút
  Future<void> _startTokenRefreshTimer() async {
    _tokenRefreshTimer?.cancel();

    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 50), (
      timer,
    ) async {
      try {
        await _refreshToken();
      } catch (e) {
        await logout(); // nếu lỗi, buộc logout
      }
    });
  }

  // ✅ Gọi API để làm mới access token từ refresh token
  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) throw Exception('No refresh token');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await _storage.write(key: 'accessToken', value: responseData['access']);
        _token = responseData['access'];
        notifyListeners();
      } else {
        throw Exception('Token refresh failed');
      }
    } catch (e) {
      throw Exception('Failed to refresh token');
    }
  }

  // ✅ Hủy timer khi Provider bị huỷ
  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}
