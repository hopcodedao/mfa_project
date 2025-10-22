import 'dart:convert';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';  
import 'api_client.dart';  
  
class NotificationService {  
  final _storage = const FlutterSecureStorage();  
  final ApiClient _apiClient = ApiClient();  
  
  Future<List<dynamic>> getNotifications() async {  
    try {  
      final response = await _apiClient.get('user/notifications/');  
      if (response.statusCode == 200) {  
        return json.decode(utf8.decode(response.bodyBytes));  
      } else {  
        throw Exception('Không thể tải thông báo');  
      }  
    } catch (e) {  
      throw Exception('Lỗi kết nối: ${e.toString()}');  
    }  
  }  
  
  Future<void> markAsRead(int notificationId) async {  
    try {  
      final response = await _apiClient.post(  
        'user/notifications/$notificationId/mark-read/',  
        {},  
      );  
      if (response.statusCode != 200) {  
        throw Exception('Không thể đánh dấu đã đọc');  
      }  
    } catch (e) {  
      throw Exception('Lỗi kết nối: ${e.toString()}');  
    }  
  }  
  
  Future<void> markAllAsRead() async {  
    try {  
      final response = await _apiClient.post('user/notifications/mark-all-read/', {});  
      if (response.statusCode != 200) {  
        throw Exception('Không thể đánh dấu tất cả đã đọc');  
      }  
    } catch (e) {  
      throw Exception('Lỗi kết nối: ${e.toString()}');  
    }  
  }  
}