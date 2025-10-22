import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../api/student_service.dart';
import 'package:network_info_plus/network_info_plus.dart';

class LivenessCheckScreen extends StatefulWidget {
  final int scheduleId;
  final String qrData;

  const LivenessCheckScreen({
    super.key,
    required this.scheduleId,
    required this.qrData,
  });

  @override
  _LivenessCheckScreenState createState() => _LivenessCheckScreenState();
}

enum LivenessStatus { ready, submitting, showingResult }

class _LivenessCheckScreenState extends State<LivenessCheckScreen> {
  LivenessStatus _status = LivenessStatus.ready;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _message = 'Sẵn sàng kiểm tra. Vui lòng nhìn thẳng và nháy mắt khi ghi hình.';
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _message = 'Lỗi camera: ${e.toString()}';
        _status = LivenessStatus.showingResult;
      });
    }
  }

  Future<String?> _getWifiSSID() async {
    try {
      final wifiInfo = NetworkInfo();
      final ssid = await wifiInfo.getWifiName();
      if (ssid != null && ssid.contains('<unknown ssid>')) return null;
      return ssid?.replaceAll('"', '');
    } catch (e) {
      print("Không thể lấy thông tin Wifi: $e");
      return null;
    }
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Dịch vụ vị trí đã bị tắt.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _startLivenessCheckAndSubmit() async {
    if (!_isCameraInitialized || _cameraController!.value.isRecordingVideo) return;

    setState(() {
      _status = LivenessStatus.submitting;
      _message = "Đang quay video 3 giây...";
    });

    try {
      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 3));
      final videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _message = "Đang lấy vị trí GPS và thông tin Wifi...";
      });

      final results = await Future.wait([
        _getGeoLocationPosition(),
        _getWifiSSID(),
      ]);
      final position = results[0] as Position;
      final wifiSsid = results[1] as String?;

      setState(() {
        _message = "Đang gửi dữ liệu điểm danh...";
      });

      final response = await _studentService.checkIn(
        qrToken: widget.qrData,
        livenessVideo: File(videoFile.path),
        latitude: position.latitude,
        longitude: position.longitude,
        wifiSsid: wifiSsid,
      );

      final responseBody = await response.stream.bytesToString();
      final decodedBody = json.decode(responseBody);

      if (response.statusCode == 200) {
        setState(() {
          _message = decodedBody['success'] ?? 'Điểm danh thành công!';
        });
      } else {
        throw Exception(decodedBody['error'] ?? 'Điểm danh thất bại.');
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi: ${e.toString()}';
      });
    } finally {
      setState(() {
        _status = LivenessStatus.showingResult;
      });
    }
  }

  Widget _buildBody() {
    if (_status == LivenessStatus.showingResult) {
      return _buildResultView();
    }

    if (!_isCameraInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang khởi tạo camera...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 280,
          height: 350,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: CameraPreview(_cameraController!),
          ),
        ),
        const SizedBox(height: 32),
        if (_status == LivenessStatus.ready)
          ElevatedButton.icon(
            onPressed: _startLivenessCheckAndSubmit,
            icon: const Icon(Icons.videocam),
            label: const Text("Bắt đầu Ghi hình & Điểm danh"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        if (_status == LivenessStatus.submitting)
          Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Đang xử lý...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildResultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _message.startsWith('Lỗi:') ? Icons.error : Icons.check_circle,
            color: _message.startsWith('Lỗi:') ? Colors.red : Colors.green,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Quay về Trang chủ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Xác thực khuôn mặt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(child: _buildBody()),
    );
  }
}
