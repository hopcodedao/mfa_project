import 'package:intl/intl.dart';  
  
class AppDateUtils {  
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');  
  static final DateFormat _timeFormat = DateFormat('HH:mm');  
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');  
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');  
    
  static String formatDate(DateTime date) {  
    return _dateFormat.format(date);  
  }  
    
  static String formatTime(DateTime time) {  
    return _timeFormat.format(time);  
  }  
    
  static String formatDateTime(DateTime dateTime) {  
    return _dateTimeFormat.format(dateTime);  
  }  
    
  static String formatForApi(DateTime date) {  
    return _apiDateFormat.format(date);  
  }  
    
  static DateTime? parseApiDate(String? dateString) {  
    if (dateString == null || dateString.isEmpty) return null;  
    try {  
      return DateTime.parse(dateString);  
    } catch (e) {  
      return null;  
    }  
  }  
    
  static bool isToday(DateTime date) {  
    final now = DateTime.now();  
    return date.year == now.year &&   
           date.month == now.month &&   
           date.day == now.day;  
  }  
    
  static bool isThisWeek(DateTime date) {  
    final now = DateTime.now();  
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));  
    final endOfWeek = startOfWeek.add(const Duration(days: 6));  
      
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&  
           date.isBefore(endOfWeek.add(const Duration(days: 1)));  
  }  
    
  static String getRelativeTime(DateTime dateTime) {  
    final now = DateTime.now();  
    final difference = now.difference(dateTime);  
      
    if (difference.inDays > 0) {  
      return '${difference.inDays} ngày trước';  
    } else if (difference.inHours > 0) {  
      return '${difference.inHours} giờ trước';  
    } else if (difference.inMinutes > 0) {  
      return '${difference.inMinutes} phút trước';  
    } else {  
      return 'Vừa xong';  
    }  
  }  
}