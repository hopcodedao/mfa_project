import 'package:flutter/material.dart';  
import 'package:provider/provider.dart';  
import '../providers/auth_provider.dart';  
import '../utils/app_utils.dart';  
  
class SettingsScreen extends StatefulWidget {  
  const SettingsScreen({super.key});  
  
  @override  
  State<SettingsScreen> createState() => _SettingsScreenState();  
}  
  
class _SettingsScreenState extends State<SettingsScreen> {  
  bool _notificationsEnabled = true;  
  bool _biometricEnabled = false;  
  String _selectedLanguage = 'vi';  
  
  @override  
  Widget build(BuildContext context) {  
    final authProvider = Provider.of<AuthProvider>(context);  
  
    return Scaffold(  
      backgroundColor: Theme.of(context).colorScheme.surface,  
      appBar: AppBar(  
        title: const Text('Cài đặt'),  
        elevation: 0,  
      ),  
      body: SingleChildScrollView(  
        child: Column(  
          children: [  
            // Header  
            _buildHeader(),  
              
            // Notification Settings  
            _buildNotificationSettings(),  
              
            // Security Settings  
            _buildSecuritySettings(),  
              
            // App Settings  
            _buildAppSettings(),  
              
            // Account Actions  
            _buildAccountActions(authProvider),  
              
            // App Info  
            _buildAppInfo(),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildHeader() {  
    return Container(  
      padding: const EdgeInsets.all(20),  
      decoration: BoxDecoration(  
        gradient: LinearGradient(  
          begin: Alignment.topLeft,  
          end: Alignment.bottomRight,  
          colors: [  
            Theme.of(context).colorScheme.primary,  
            Theme.of(context).colorScheme.secondary,  
          ],  
        ),  
      ),  
      child: Row(  
        children: [  
          Container(  
            padding: const EdgeInsets.all(8),  
            decoration: BoxDecoration(  
              color: Colors.white.withOpacity(0.2),  
              borderRadius: BorderRadius.circular(8),  
            ),  
            child: const Icon(  
              Icons.settings,  
              color: Colors.white,  
              size: 24,  
            ),  
          ),  
          const SizedBox(width: 16),  
          Expanded(  
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,  
              children: [  
                Text(  
                  'Cài đặt ứng dụng',  
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
                    color: Colors.white,  
                    fontWeight: FontWeight.bold,  
                  ),  
                ),  
                Text(  
                  'Tùy chỉnh trải nghiệm của bạn',  
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
                    color: Colors.white70,  
                  ),  
                ),  
              ],  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildNotificationSettings() {  
    return _buildSettingsSection(  
      title: 'Thông báo',  
      icon: Icons.notifications_outlined,  
      children: [  
        _buildSwitchTile(  
          title: 'Thông báo push',  
          subtitle: 'Nhận thông báo về lịch học và điểm danh',  
          value: _notificationsEnabled,  
          onChanged: (value) {  
            setState(() {  
              _notificationsEnabled = value;  
            });  
          },  
        ),  
      ],  
    );  
  }  
  
  Widget _buildSecuritySettings() {  
    return _buildSettingsSection(  
      title: 'Bảo mật',  
      icon: Icons.security,  
      children: [  
        _buildSwitchTile(  
          title: 'Xác thực sinh học',  
          subtitle: 'Sử dụng vân tay hoặc Face ID để đăng nhập',  
          value: _biometricEnabled,  
          onChanged: (value) {  
            setState(() {  
              _biometricEnabled = value;  
            });  
          },  
        ),  
        _buildSettingsTile(  
          title: 'Đổi mật khẩu',  
          subtitle: 'Cập nhật mật khẩu bảo mật',  
          icon: Icons.lock_outline,  
          onTap: () => Navigator.of(context).pushNamed('/change-password'),  
        ),  
        _buildSettingsTile(  
          title: 'Đăng ký khuôn mặt',  
          subtitle: 'Cập nhật ảnh khuôn mặt cho điểm danh',  
          icon: Icons.face_retouching_natural,  
          onTap: () => Navigator.of(context).pushNamed('/face-registration'),  
        ),  
      ],  
    );  
  }  
  
  Widget _buildAppSettings() {  
    return _buildSettingsSection(  
      title: 'Ứng dụng',  
      icon: Icons.app_settings_alt,  
      children: [  
        _buildSettingsTile(  
          title: 'Ngôn ngữ',  
          subtitle: _selectedLanguage == 'vi' ? 'Tiếng Việt' : 'English',  
          icon: Icons.language,  
          onTap: () => _showLanguageDialog(),  
        ),  
        _buildSettingsTile(  
          title: 'Về ứng dụng',  
          subtitle: 'Phiên bản 1.0.0',  
          icon: Icons.info_outline,  
          onTap: () => _showAboutDialog(),  
        ),
        _buildSettingsTile(
          title: 'Trợ giúp',
          subtitle: 'Hướng dẫn sử dụng ứng dụng',
          icon: Icons.help_outline,
          onTap: () => Navigator.of(context).pushNamed('/help'),
        ),
      ],  
    );  
  }  
  
  Widget _buildAccountActions(AuthProvider authProvider) {  
    return _buildSettingsSection(  
      title: 'Tài khoản',  
      icon: Icons.account_circle_outlined,  
      children: [  
        _buildSettingsTile(  
          title: 'Đăng xuất',  
          subtitle: 'Thoát khỏi tài khoản hiện tại',  
          icon: Icons.logout,  
          onTap: () => _showLogoutDialog(authProvider),  
          isDestructive: true,  
        ),  
      ],  
    );  
  }  
  
  Widget _buildAppInfo() {  
    return Container(  
      margin: const EdgeInsets.all(16),  
      padding: const EdgeInsets.all(16),  
      decoration: BoxDecoration(  
        color: Theme.of(context).colorScheme.surface,  
        borderRadius: BorderRadius.circular(12),  
        boxShadow: [  
          BoxShadow(  
            color: Colors.black.withOpacity(0.05),  
            blurRadius: 8,  
            offset: const Offset(0, 2),  
          ),  
        ],  
      ),  
      child: Column(  
        children: [  
          Text(  
            'CTUT Smart Attendance',  
            style: Theme.of(context).textTheme.titleLarge?.copyWith(  
              fontWeight: FontWeight.bold,  
            ),  
          ),  
          const SizedBox(height: 8),  
          Text(  
            'Phiên bản 1.0.0',  
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
              color: Theme.of(context).colorScheme.outline,  
            ),  
          ),  
          const SizedBox(height: 8),  
          Text(  
            '© 2024 Trường ĐH Kỹ thuật - Công nghệ Cần Thơ',  
            style: Theme.of(context).textTheme.bodySmall?.copyWith(  
              color: Theme.of(context).colorScheme.outline,  
            ),  
            textAlign: TextAlign.center,  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildSettingsSection({  
    required String title,  
    required IconData icon,  
    required List<Widget> children,  
  }) {  
    return Container(  
      margin: const EdgeInsets.all(16),  
      decoration: BoxDecoration(  
        color: Theme.of(context).colorScheme.surface,  
        borderRadius: BorderRadius.circular(12),  
        boxShadow: [  
          BoxShadow(  
            color: Colors.black.withOpacity(0.05),  
            blurRadius: 8,  
            offset: const Offset(0, 2),  
          ),  
        ],  
      ),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          Padding(  
            padding: const EdgeInsets.all(16),  
            child: Row(  
              children: [  
                Icon(  
                  icon,  
                  color: Theme.of(context).colorScheme.primary,  
                  size: 20,  
                ),  
                const SizedBox(width: 8),  
                Text(  
                  title,  
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                    fontWeight: FontWeight.w600,  
                  ),  
                ),  
              ],  
            ),  
          ),  
          ...children,  
        ],  
      ),  
    );  
  }  
  
  Widget _buildSettingsTile({  
    required String title,  
    required String subtitle,  
    required IconData icon,  
    required VoidCallback onTap,  
    bool isDestructive = false,  
  }) {  
    return InkWell(  
      onTap: onTap,  
      child: Padding(  
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
        child: Row(  
          children: [  
            Container(  
              width: 40,  
              height: 40,  
              decoration: BoxDecoration(  
                color: (isDestructive   
                    ? Theme.of(context).colorScheme.error   
                    : Theme.of(context).colorScheme.primary).withOpacity(0.1),  
                borderRadius: BorderRadius.circular(20),  
              ),  
              child: Icon(  
                icon,  
                color: isDestructive   
                    ? Theme.of(context).colorScheme.error  
                    : Theme.of(context).colorScheme.primary,  
                size: 20,  
              ),  
            ),  
            const SizedBox(width: 16),  
            Expanded(  
              child: Column(  
                crossAxisAlignment: CrossAxisAlignment.start,  
                children: [  
                  Text(  
                    title,  
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                      fontWeight: FontWeight.w500,  
                      color: isDestructive ? Theme.of(context).colorScheme.error : null,  
                    ),  
                  ),  
                  Text(  
                    subtitle,  
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(  
                      color: Theme.of(context).colorScheme.outline,  
                    ),  
                  ),  
                ],  
              ),  
            ),  
            Icon(  
              Icons.arrow_forward_ios,  
              size: 16,  
              color: Theme.of(context).colorScheme.outline,  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildSwitchTile({  
    required String title,  
    required String subtitle,  
    required bool value,
    required ValueChanged<bool> onChanged,  
  }) {  
    return Padding(  
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
      child: Row(  
        children: [  
          Container(  
            width: 40,  
            height: 40,  
            decoration: BoxDecoration(  
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  
              borderRadius: BorderRadius.circular(20),  
            ),  
            child: Icon(  
              Icons.notifications,  
              color: Theme.of(context).colorScheme.primary,  
              size: 20,  
            ),  
          ),  
          const SizedBox(width: 16),  
          Expanded(  
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,  
              children: [  
                Text(  
                  title,  
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                    fontWeight: FontWeight.w500,  
                  ),  
                ),  
                Text(  
                  subtitle,  
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(  
                    color: Theme.of(context).colorScheme.outline,  
                  ),  
                ),  
              ],  
            ),  
          ),  
          Switch(  
            value: value,  
            onChanged: onChanged,  
            activeColor: Theme.of(context).colorScheme.primary,  
          ),  
        ],  
      ),  
    );  
  }  
  
  void _showLanguageDialog() {  
    showDialog(  
      context: context,  
      builder: (context) => AlertDialog(  
        title: const Text('Chọn ngôn ngữ'),  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(12),  
        ),  
        content: Column(  
          mainAxisSize: MainAxisSize.min,  
          children: [  
            RadioListTile<String>(  
              title: const Text('Tiếng Việt'),  
              value: 'vi',  
              groupValue: _selectedLanguage,  
              onChanged: (value) {  
                setState(() {  
                  _selectedLanguage = value!;  
                });  
                Navigator.of(context).pop();  
              },  
            ),  
            RadioListTile<String>(  
              title: const Text('English'),  
              value: 'en',  
              groupValue: _selectedLanguage,  
              onChanged: (value) {  
                setState(() {  
                  _selectedLanguage = value!;  
                });  
                Navigator.of(context).pop();  
              },  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
  
  void _showAboutDialog() {  
    showAboutDialog(  
      context: context,  
      applicationName: 'CTUT Smart Attendance',  
      applicationVersion: '1.0.0',  
      applicationIcon: Container(  
        width: 64,  
        height: 64,  
        decoration: BoxDecoration(  
          color: Theme.of(context).colorScheme.primary,  
          borderRadius: BorderRadius.circular(12),  
        ),  
        child: const Icon(  
          Icons.school,  
          color: Colors.white,  
          size: 32,  
        ),  
      ),  
      children: [  
        const Text('Hệ thống điểm danh thông minh dành cho sinh viên và giảng viên Trường Đại học Kỹ thuật - Công nghệ Cần Thơ.'),  
        const SizedBox(height: 16),  
        const Text('Phát triển bởi: Nhóm phát triển CTUT'),  
        const Text('Email hỗ trợ: support@ctut.edu.vn'),  
      ],  
    );  
  }  
  
  void _showLogoutDialog(AuthProvider authProvider) {  
    AppUtils.showConfirmDialog(  
      context,  
      title: 'Đăng xuất',  
      content: 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',  
      onConfirm: () {  
        authProvider.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); 
      },  
      confirmText: 'Đăng xuất',  
      cancelText: 'Hủy',  
    );  
  }  
}