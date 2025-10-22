import 'package:flutter/material.dart';  
import 'package:provider/provider.dart';  
import '../providers/auth_provider.dart';  
import '../api/api_client.dart';  
import 'app_utils.dart';  
  
class GlobalErrorHandler {  
  static void handleError(BuildContext context, dynamic error) {  
    String message = 'Đã xảy ra lỗi không xác định';  
    bool shouldLogout = false;  
  
    if (error is UnauthorizedException) {  
      message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';  
      shouldLogout = true;  
    } else if (error is ForbiddenException) {  
      message = 'Bạn không có quyền thực hiện thao tác này';  
    } else if (error is NotFoundException) {  
      message = 'Không tìm thấy dữ liệu yêu cầu';  
    } else if (error is ServerException) {  
      message = 'Lỗi máy chủ. Vui lòng thử lại sau.';  
    } else if (error.toString().contains('internet')) {  
      message = 'Không có kết nối internet. Vui lòng kiểm tra kết nối.';  
    } else if (error.toString().contains('timeout')) {  
      message = 'Kết nối quá chậm. Vui lòng thử lại.';  
    } else {  
      message = error.toString().replaceAll('Exception: ', '');  
    }  
  
    AppUtils.showSnackBar(context, message, isError: true);  
  
    if (shouldLogout) {  
      Future.delayed(const Duration(seconds: 2), () {  
        Provider.of<AuthProvider>(context, listen: false).logout();  
      });  
    }  
  }  
  
  static void handleAsyncError(BuildContext context, dynamic error) {  
    if (context.mounted) {  
      handleError(context, error);  
    }  
  }  
}