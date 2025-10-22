class ValidationUtils {  
  static String? validateEmail(String? email) {  
    if (email == null || email.isEmpty) {  
      return 'Email không được để trống';  
    }  
      
    final emailRegex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$');  
    if (!emailRegex.hasMatch(email)) {  
      return 'Email không hợp lệ';  
    }  
      
    return null;  
  }  
    
  static String? validatePassword(String? password) {  
    if (password == null || password.isEmpty) {  
      return 'Mật khẩu không được để trống';  
    }  
      
    if (password.length < 6) {  
      return 'Mật khẩu phải có ít nhất 6 ký tự';  
    }  
      
    return null;  
  }  
    
  static String? validateUserCode(String? userCode) {  
    if (userCode == null || userCode.isEmpty) {  
      return 'Mã sinh viên không được để trống';  
    }  
      
    if (userCode.length < 5) {  
      return 'Mã sinh viên không hợp lệ';  
    }  
      
    return null;  
  }  
    
  static String? validateRequired(String? value, String fieldName) {  
    if (value == null || value.trim().isEmpty) {  
      return '$fieldName không được để trống';  
    }  
    return null;  
  }  
    
  static String? validatePhoneNumber(String? phone) {  
    if (phone == null || phone.isEmpty) {  
      return 'Số điện thoại không được để trống';  
    }  
      
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');  
    if (!phoneRegex.hasMatch(phone)) {  
      return 'Số điện thoại không hợp lệ';  
    }  
      
    return null;  
  }  
}