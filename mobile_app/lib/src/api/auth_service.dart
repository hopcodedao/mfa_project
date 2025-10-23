import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  // 1. Đăng nhập
  Future<Map<String, dynamic>> login(String userCode, String password) async {
    // API đăng nhập không cần token nên có thể gọi trực tiếp
    // Send both 'username' and 'user_code' to be compatible with server's
    // custom USERNAME_FIELD='user_code' and the default SimpleJWT serializer
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}token/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': userCode,
        'user_code': userCode,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['access'] != null) {
        await _storage.write(key: 'accessToken', value: responseData['access']);
        await _storage.write(
          key: 'refreshToken',
          value: responseData['refresh'],
        );
      }
      return responseData;
    } else {
      throw Exception('Đăng nhập thất bại.');
    }
  }

  // 2. Đăng xuất
  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  // 3. Lấy thông tin chi tiết người dùng
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _apiClient.get('user/profile/');
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải thông tin người dùng.');
    }
  }

  // 4. Gửi yêu cầu Reset Mật khẩu
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    // API này không cần token
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}auth/password-reset/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseData['error'] ?? 'Không thể gửi yêu cầu đặt lại mật khẩu');
    }
    return responseData;
  }

  // 5. Xác nhận Mật khẩu mới
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String uidb64,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Kiểm tra mật khẩu khớp nhau
    if (newPassword != confirmPassword) {
      throw Exception('Mật khẩu không khớp');
    }

    // API này không cần token
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}auth/password-reset/confirm/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'uidb64': uidb64,
        'token': token,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseData['error'] ?? 'Không thể đặt lại mật khẩu');
    }
    return responseData;
  }

  // 6. Đổi mật khẩu khi đã đăng nhập
  Future<http.Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    // Dùng apiClient đã được nâng cấp, nó sẽ tự đính kèm token
    return _apiClient.post('auth/change-password/', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // 7. Đăng ký FCM token
  Future<http.Response> registerFCMToken(String fcmToken) {
    return _apiClient.post('user/register-fcm/', {'fcm_token': fcmToken});
  }

  // Đăng nhập bằng Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // 1. Bắt đầu quá trình đăng nhập với Google
      // LƯU Ý QUAN TRỌNG: serverClientId chính là Web Client ID của bạn.
      // Điều này cần thiết để Google trả về một idToken mà backend Django có thể xác thực.
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '418800992807-0rt8e8q76t6fmj0o95cucqsalhr9cmlv.apps.googleusercontent.com',
      );

      // [SỬA LỖI] Thêm dòng này để luôn xóa phiên đăng nhập cũ của Google
      // Điều này sẽ buộc cửa sổ chọn tài khoản luôn hiện lên
      await googleSignIn.signOut();

      // Bắt đầu quá trình đăng nhập mới
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Nếu người dùng hủy bỏ, googleUser sẽ là null
      if (googleUser == null) {
        throw Exception('Đăng nhập Google đã bị người dùng hủy bỏ.');
      }

      // 2. Lấy idToken từ tài khoản Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Không lấy được ID Token từ Google. Vui lòng thử lại.');
      }

      // 3. Gửi idToken lên backend của chúng ta để xác thực và lấy token của hệ thống
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}auth/google-login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': idToken}),
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (responseData['access'] != null) {
          // 4. Lưu lại token của hệ thống chúng ta
          await _storage.write(
            key: 'accessToken',
            value: responseData['access'],
          );
          await _storage.write(
            key: 'refreshToken',
            value: responseData['refresh'],
          );
        }
        return responseData;
      } else {
        throw Exception(
          responseData['error'] ?? 'Lỗi không xác định từ server.',
        );
      }
    } catch (e) {
      print("Lỗi trong quá trình đăng nhập Google: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Không thể làm mới token.');
    }
  }
}
