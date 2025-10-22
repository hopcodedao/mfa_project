import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'package:http_parser/http_parser.dart';
import '../services/cache_service.dart';

class StudentService {
  final _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getMySchedules(String filter) async {
    print('🔍 [DEBUG] Đang tải lịch học với filter: $filter');  
    print('📅 [DEBUG] Current DateTime: ${DateTime.now()}');  
    print('📅 [DEBUG] Current weekday: ${DateTime.now().weekday}'); // Monday=1  
    print('📅 [DEBUG] Current isoWeekday: ${DateTime.now().weekday}');

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final url = Uri.parse('${BASE_URL}user/my-schedules/?filter=$filter');
      print('📡 Gọi API: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Kết nối quá chậm, vui lòng thử lại');
            },
          );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Tải thành công ${data.length} lịch học');

        // Cache data for offline use
        await CacheService.cacheSchedules(data);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else if (response.statusCode == 404) {
        print('ℹ️ Không có lịch học nào');
        return [];
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');

      // Nếu có lỗi, thử load từ cache
      print('🔄 Đang thử tải từ cache...');
      final cachedData = await CacheService.getCachedSchedules();
      if (cachedData != null) {
        print('✅ Tải thành công từ cache: ${cachedData.length} lịch học');
        return cachedData;
      }

      // Nếu không có cache, ném lỗi chi tiết
      if (e is SocketException) {
        throw Exception('Không có kết nối internet');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Kết nối quá chậm, vui lòng thử lại');
      } else {
        throw Exception('Không thể tải lịch học: ${e.toString()}');
      }
    }
  }

  Future<http.StreamedResponse> registerFace(File imageFile) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}user/register-face/');

    final request = http.MultipartRequest('POST', url);
    final filename = imageFile.path.split('/').last;

    request.files.add(
      http.MultipartFile(
        'face_image',
        imageFile.readAsBytes().asStream(),
        imageFile.lengthSync(),
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';
    return request.send();
  }

  // Trong class StudentService
  Future<http.StreamedResponse> checkIn({
    required String qrToken,
    required File livenessVideo,
    required double latitude,
    required double longitude,
    String? wifiSsid, // [THÊM] Tham số mới, có thể null
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}attendance/check-in/');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';

    // Thêm các trường dữ liệu
    request.fields['qr_token'] = qrToken;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    // [THÊM] Gửi SSID lên server, nếu là null thì gửi chuỗi rỗng
    request.fields['wifi_ssid'] = wifiSsid ?? '';

    // Thêm file video
    request.files.add(
      http.MultipartFile(
        'liveness_video',
        livenessVideo.readAsBytes().asStream(),
        livenessVideo.lengthSync(),
        filename: livenessVideo.path.split('/').last,
        contentType: MediaType('video', 'mp4'),
      ),
    );

    return request.send();
  }

  // Lấy lịch sử điểm danh của sinh viên cho một lớp
  Future<List<dynamic>> getMyAttendanceHistory(int classId) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}classes/$classId/my-attendance/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải lịch sử điểm danh.');
    }
  }

  // Nộp đơn xin phép
  Future<http.StreamedResponse> submitAbsenceRequest({
    required int scheduleId,
    required String reason,
    required File proofImage,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}absence-requests/');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['schedule'] = scheduleId.toString();
    request.fields['reason'] = reason;
    request.files.add(
      await http.MultipartFile.fromPath('proof', proofImage.path),
    );

    return request.send();
  }

  Future<List<dynamic>> getEnrolledClasses() async {
    print('🔍 Đang tải danh sách lớp học');

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }

      final url = Uri.parse('${BASE_URL}user/my-enrollments/');
      print('📡 Gọi API: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Kết nối quá chậm, vui lòng thử lại');
            },
          );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('✅ Tải thành công ${data.length} lớp học');

        // Cache data for offline use
        await CacheService.cacheClasses(data);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn');
      } else if (response.statusCode == 404) {
        print('ℹ️ Không có lớp học nào');
        return [];
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');

      // Nếu có lỗi, thử load từ cache
      print('🔄 Đang thử tải từ cache...');
      final cachedData = await CacheService.getCachedClasses();
      if (cachedData != null) {
        print('✅ Tải thành công từ cache: ${cachedData.length} lớp học');
        return cachedData;
      }

      // Nếu không có cache, ném lỗi chi tiết
      if (e is SocketException) {
        throw Exception('Không có kết nối internet');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Kết nối quá chậm, vui lòng thử lại');
      } else {
        throw Exception('Không thể tải danh sách lớp học: ${e.toString()}');
      }
    }
  }

  Future<http.Response> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}auth/change-password/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    return response;
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}user/attendance-stats/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải thống kê điểm danh');
    }
  }

  Future<List<dynamic>> getUpcomingSchedules() async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}user/upcoming-schedules/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải lịch sắp tới');
    }
  }

  Future<http.Response> updateProfile(Map<String, dynamic> profileData) async {
    final token = await _storage.read(key: 'accessToken');
    final url = Uri.parse('${BASE_URL}user/profile/');
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(profileData),
    );
  }
}
