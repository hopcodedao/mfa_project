import 'dart:async';  
import 'package:connectivity_plus/connectivity_plus.dart';  
  
class ConnectivityService {  
  static final ConnectivityService _instance = ConnectivityService._internal();  
  factory ConnectivityService() => _instance;  
  ConnectivityService._internal();  
  
  final Connectivity _connectivity = Connectivity();  
  StreamController<bool> connectionStatusController = StreamController<bool>.broadcast();  
  
  Stream<bool> get connectionStream => connectionStatusController.stream;  
  bool _isConnected = true;  
  bool get isConnected => _isConnected;  
  
  void initialize() {  
    // Sửa: callback nhận List<ConnectivityResult>  
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {  
      _updateConnectionStatus(results);  
    });  
      
    // Check initial connectivity  
    _checkInitialConnectivity();  
  }  
  
  Future<void> _checkInitialConnectivity() async {  
    try {  
      // Sửa: checkConnectivity() trả về List<ConnectivityResult>  
      final results = await _connectivity.checkConnectivity();  
      _updateConnectionStatus(results);  
    } catch (e) {  
      _updateConnectionStatus([ConnectivityResult.none]);  
    }  
  }  
  
  // Sửa: method nhận List<ConnectivityResult>  
  void _updateConnectionStatus(List<ConnectivityResult> results) {  
    final wasConnected = _isConnected;  
    // Kiểm tra xem có kết nối nào khác none không  
    _isConnected = results.any((result) => result != ConnectivityResult.none);  
      
    if (wasConnected != _isConnected) {  
      connectionStatusController.add(_isConnected);  
    }  
  }  
  
  void dispose() {  
    connectionStatusController.close();  
  }  
}