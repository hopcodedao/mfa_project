import 'dart:developer' as developer;  
  
class PerformanceMonitor {  
  static final Map<String, DateTime> _startTimes = {};  
    
  static void startTimer(String operation) {  
    _startTimes[operation] = DateTime.now();  
    developer.log('Started: $operation', name: 'Performance');  
  }  
    
  static void endTimer(String operation) {  
    final startTime = _startTimes[operation];  
    if (startTime != null) {  
      final duration = DateTime.now().difference(startTime);  
      developer.log('Completed: $operation in ${duration.inMilliseconds}ms', name: 'Performance');  
      _startTimes.remove(operation);  
    }  
  }  
    
  static void logMemoryUsage() {  
    developer.log('Memory usage check', name: 'Performance');  
  }  
    
  static void logApiCall(String endpoint, int statusCode, Duration duration) {  
    developer.log(  
      'API: $endpoint - Status: $statusCode - Duration: ${duration.inMilliseconds}ms',  
      name: 'API Performance'  
    );  
  }  
}