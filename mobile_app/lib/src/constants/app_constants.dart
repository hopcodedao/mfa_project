class AppConstants {  
  // App Info  
  static const String appName = 'CTUT Smart Attendance';  
  static const String appVersion = '1.0.0';  
  static const String universityName = 'Trường ĐH Kỹ thuật - Công nghệ Cần Thơ';  
    
  // API  
  static const String baseUrl = 'http://10.10.3.219:8000/api/v1/';  
  static const int requestTimeout = 30; // seconds  
    
  // Storage Keys  
  static const String accessTokenKey = 'accessToken';  
  static const String refreshTokenKey = 'refreshToken';  
  static const String userDataKey = 'userData';  
    
  // Attendance Status  
  static const String statusPresent = 'PRESENT';  
  static const String statusAbsent = 'ABSENT';  
  static const String statusLate = 'LATE';  
    
  // Request Status  
  static const String requestPending = 'PENDING';  
  static const String requestApproved = 'APPROVED';  
  static const String requestRejected = 'REJECTED';  
    
  // Validation  
  static const int minPasswordLength = 8;  
  static const int maxReasonLength = 500;  
  static const int minReasonLength = 10;  
}