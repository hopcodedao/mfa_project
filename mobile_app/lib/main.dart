import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './src/providers/auth_provider.dart';
import './src/screens/splash_screen.dart';
import './src/screens/login_screen.dart';
import './src/screens/class_list_screen.dart';
import './src/screens/qr_scan_screen.dart';
import './src/screens/liveness_check_screen.dart';
import './src/screens/attendance_history_screen.dart';
import './src/screens/absence_request_form_screen.dart';
import './src/screens/face_registration_screen.dart';
import './src/screens/change_password_screen.dart';
import './src/screens/forgot_password_screen.dart';
import './src/screens/reset_password_screen.dart';
import './src/screens/notification_screen.dart';
import './src/screens/main_navigation_screen.dart';
import './src/screens/profile_screen.dart';
import './src/screens/settings_screen.dart';
import './src/screens/help_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('vi', null);
  ConnectivityService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = ConnectivityService().connectionStream.listen((
      isConnected,
    ) {
      setState(() {
        _isConnected = isConnected;
      });

      if (!isConnected) {
        _showOfflineSnackBar();
      }
    });
  }

  void _showOfflineSnackBar() {
    if (_navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Không có kết nối internet'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _connectivitySubscription?.cancel();
    ConnectivityService().dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Xử lý link đã khởi động app (khi app bị kill hoàn toàn)
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        print('--- DEEP LINK (Initial): $initialUri');
        _navigateToDeepLink(initialUri);
      }
    } catch (e) {
      print('--- DEEP LINK (Initial Error): $e');
    }

    // Lắng nghe link khi app đang chạy
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (!mounted) return;
        print('--- DEEP LINK (Stream): $uri');
        _navigateToDeepLink(uri);
      },
      onError: (err) {
        print('--- DEEP LINK (Stream Error): $err');
      },
    );

    // Thêm đoạn này: xử lý "link mới nhất" sau resume
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final latestUri = await _appLinks.getLatestAppLink();
        if (latestUri != null) {
          print('--- DEEP LINK (Latest): $latestUri');
          _navigateToDeepLink(latestUri);
        }
      } catch (e) {
        print('--- DEEP LINK (Latest Error): $e');
      }
    });
  }

  void _navigateToDeepLink(Uri uri) {
    if (_navigatorKey.currentState == null) return;

    if (uri.host == 'reset-password' && uri.pathSegments.length == 2) {
      final uidb64 = uri.pathSegments[0];
      final token = uri.pathSegments[1];

      print('--- Đang điều hướng đến Reset Password Screen...');

      // ⚠️ Ngăn push lại nếu đang ở màn reset-password rồi
      bool alreadyOnResetPassword = false;
      _navigatorKey.currentState!.popUntil((route) {
        if (route.settings.name == '/reset-password') {
          alreadyOnResetPassword = true;
        }
        return true;
      });

      if (!alreadyOnResetPassword) {
        _navigatorKey.currentState!.pushNamed(
          '/reset-password',
          arguments: {'uidb64': uidb64, 'token': token},
        );
      } else {
        print('--- Bỏ qua vì đã ở màn hình reset-password.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'CTUT Smart Attendance', // Đổi tên app
          theme: AppTheme.lightTheme, // Sử dụng theme mới
          home: auth.isAuthenticated
              ? const MainNavigationScreen()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                          ConnectionState.waiting
                      ? const SplashScreen()
                      : const LoginScreen(),
                ),
          onGenerateRoute: (settings) {
            if (settings.name == '/main') {
              return MaterialPageRoute(
                builder: (ctx) => const MainNavigationScreen(),
              );
            }

            if (settings.name == '/absence-request-form') {
              final scheduleId = settings.arguments as int;
              return MaterialPageRoute(
                builder: (ctx) =>
                    AbsenceRequestFormScreen(scheduleId: scheduleId),
              );
            }

            if (settings.name == '/help') {
              return MaterialPageRoute(builder: (ctx) => const HelpScreen());
            }

            if (settings.name == '/profile') {
              return MaterialPageRoute(builder: (ctx) => const ProfileScreen());
            }

            if (settings.name == '/qr-scan') {
              final scheduleId = settings.arguments as int?;
              if (scheduleId == null) {
                // Fallback về màn hình chính nếu không có scheduleId
                return MaterialPageRoute(
                  builder: (ctx) => const MainNavigationScreen(),
                );
              }
              return MaterialPageRoute(
                builder: (ctx) => QrScanScreen(scheduleId: scheduleId),
              );
            }

            if (settings.name == '/liveness-check') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (ctx) => LivenessCheckScreen(
                  scheduleId: args['scheduleId'],
                  qrData: args['qrData'],
                ),
              );
            }

            if (settings.name == '/attendance-history') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (ctx) => AttendanceHistoryScreen(
                  classId: args['classId'],
                  className: args['className'],
                ),
              );
            }

            if (settings.name == '/face-registration') {
              return MaterialPageRoute(
                builder: (ctx) => const FaceRegistrationScreen(),
              );
            }

            if (settings.name == '/change-password') {
              return MaterialPageRoute(
                builder: (ctx) => const ChangePasswordScreen(),
              );
            }

            if (settings.name == '/forgot-password') {
              return MaterialPageRoute(
                builder: (ctx) => const ForgotPasswordScreen(),
              );
            }

            if (settings.name == '/reset-password') {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (ctx) => ResetPasswordScreen(
                  uidb64: args['uidb64']!,
                  token: args['token']!,
                ),
                settings: RouteSettings(name: '/reset-password'),
              );
            }

            if (settings.name == '/notifications') {
              return MaterialPageRoute(
                builder: (ctx) => const NotificationScreen(),
              );
            }

            if (settings.name == '/settings') {
              return MaterialPageRoute(
                builder: (ctx) => const SettingsScreen(),
              );
            }

            if (settings.name == '/absence-request') {
              final scheduleId = settings.arguments as int?;
              if (scheduleId != null) {
                return MaterialPageRoute(
                  builder: (ctx) =>
                      AbsenceRequestFormScreen(scheduleId: scheduleId),
                );
              }
              // Fallback nếu không có scheduleId
              return MaterialPageRoute(
                builder: (ctx) => const ClassListScreen(),
              );
            }

            return null;
          },
        ),
      ),
    );
  }
}
