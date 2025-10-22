import 'dart:convert';  
import 'package:shared_preferences/shared_preferences.dart';  
  
class CacheService {  
  static const String _schedulesCacheKey = 'cached_schedules';  
  static const String _classesCacheKey = 'cached_classes';  
  static const String _userProfileCacheKey = 'cached_user_profile';  
  static const Duration _cacheExpiry = Duration(hours: 1);  
  
  static Future<void> cacheSchedules(List<dynamic> schedules) async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheData = {  
      'data': schedules,  
      'timestamp': DateTime.now().millisecondsSinceEpoch,  
    };  
    await prefs.setString(_schedulesCacheKey, json.encode(cacheData));  
  }  
  
  static Future<List<dynamic>?> getCachedSchedules() async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheString = prefs.getString(_schedulesCacheKey);  
      
    if (cacheString == null) return null;  
      
    final cacheData = json.decode(cacheString);  
    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);  
      
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {  
      await prefs.remove(_schedulesCacheKey);  
      return null;  
    }  
      
    return List<dynamic>.from(cacheData['data']);  
  }  
  
  static Future<void> cacheClasses(List<dynamic> classes) async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheData = {  
      'data': classes,  
      'timestamp': DateTime.now().millisecondsSinceEpoch,  
    };  
    await prefs.setString(_classesCacheKey, json.encode(cacheData));  
  }  
  
  static Future<List<dynamic>?> getCachedClasses() async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheString = prefs.getString(_classesCacheKey);  
      
    if (cacheString == null) return null;  
      
    final cacheData = json.decode(cacheString);  
    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);  
      
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {  
      await prefs.remove(_classesCacheKey);  
      return null;  
    }  
      
    return List<dynamic>.from(cacheData['data']);  
  }  
  
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheData = {  
      'data': profile,  
      'timestamp': DateTime.now().millisecondsSinceEpoch,  
    };  
    await prefs.setString(_userProfileCacheKey, json.encode(cacheData));  
  }  
  
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {  
    final prefs = await SharedPreferences.getInstance();  
    final cacheString = prefs.getString(_userProfileCacheKey);  
      
    if (cacheString == null) return null;  
      
    final cacheData = json.decode(cacheString);  
    final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);  
      
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {  
      await prefs.remove(_userProfileCacheKey);  
      return null;  
    }  
      
    return Map<String, dynamic>.from(cacheData['data']);  
  }  
  
  static Future<void> clearAllCache() async {  
    final prefs = await SharedPreferences.getInstance();  
    await prefs.remove(_schedulesCacheKey);  
    await prefs.remove(_classesCacheKey);  
    await prefs.remove(_userProfileCacheKey);  
  }  
}