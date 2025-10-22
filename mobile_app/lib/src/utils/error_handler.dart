import 'package:flutter/material.dart';  
  
class ErrorHandler {  
  static void showError(BuildContext context, String message, {  
    Duration duration = const Duration(seconds: 4),  
    SnackBarAction? action,  
  }) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(  
        content: Row(  
          children: [  
            const Icon(  
              Icons.error_outline,  
              color: Colors.white,  
              size: 20,  
            ),  
            const SizedBox(width: 12),  
            Expanded(  
              child: Text(  
                message,  
                style: const TextStyle(  
                  color: Colors.white,  
                  fontSize: 14,  
                ),  
              ),  
            ),  
          ],  
        ),  
        backgroundColor: const Color(0xFFE53935),  
        behavior: SnackBarBehavior.floating,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(8),  
        ),  
        duration: duration,  
        action: action,  
      ),  
    );  
  }  
  
  static void showSuccess(BuildContext context, String message, {  
    Duration duration = const Duration(seconds: 3),  
  }) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(  
        content: Row(  
          children: [  
            const Icon(  
              Icons.check_circle_outline,  
              color: Colors.white,  
              size: 20,  
            ),  
            const SizedBox(width: 12),  
            Expanded(  
              child: Text(  
                message,  
                style: const TextStyle(  
                  color: Colors.white,  
                  fontSize: 14,  
                ),  
              ),  
            ),  
          ],  
        ),  
        backgroundColor: const Color(0xFF4CAF50),  
        behavior: SnackBarBehavior.floating,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(8),  
        ),  
        duration: duration,  
      ),  
    );  
  }  
  
  static void showWarning(BuildContext context, String message, {  
    Duration duration = const Duration(seconds: 3),  
  }) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(  
        content: Row(  
          children: [  
            const Icon(  
              Icons.warning_outlined,  
              color: Colors.black87,  
              size: 20,  
            ),  
            const SizedBox(width: 12),  
            Expanded(  
              child: Text(  
                message,  
                style: const TextStyle(  
                  color: Colors.black87,  
                  fontSize: 14,  
                ),  
              ),  
            ),  
          ],  
        ),  
        backgroundColor: const Color(0xFFFFC107),  
        behavior: SnackBarBehavior.floating,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(8),  
        ),  
        duration: duration,  
      ),  
    );  
  }  
  
  static void showInfo(BuildContext context, String message, {  
    Duration duration = const Duration(seconds: 3),  
  }) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(  
        content: Row(  
          children: [  
            const Icon(  
              Icons.info_outline,  
              color: Colors.white,  
              size: 20,  
            ),  
            const SizedBox(width: 12),  
            Expanded(  
              child: Text(  
                message,  
                style: const TextStyle(  
                  color: Colors.white,  
                  fontSize: 14,  
                ),  
              ),  
            ),  
          ],  
        ),  
        backgroundColor: const Color(0xFF2196F3),  
        behavior: SnackBarBehavior.floating,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(8),  
        ),  
        duration: duration,  
      ),  
    );  
  }  
  
  static String getErrorMessage(dynamic error) {  
    if (error is String) {  
      return error;  
    }  
      
    // Handle common error types  
    String errorString = error.toString();  
      
    if (errorString.contains('SocketException') ||   
        errorString.contains('NetworkException')) {  
      return 'Không thể kết nối mạng. Vui lòng kiểm tra kết nối internet.';  
    }  
      
    if (errorString.contains('TimeoutException')) {  
      return 'Kết nối quá chậm. Vui lòng thử lại.';  
    }  
      
    if (errorString.contains('FormatException')) {  
      return 'Dữ liệu không hợp lệ. Vui lòng thử lại.';  
    }  
      
    if (errorString.contains('401')) {  
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';  
    }  
      
    if (errorString.contains('403')) {  
      return 'Bạn không có quyền thực hiện thao tác này.';  
    }  
      
    if (errorString.contains('404')) {  
      return 'Không tìm thấy dữ liệu yêu cầu.';  
    }  
      
    if (errorString.contains('500')) {  
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';  
    }  
      
    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';  
  }  
}