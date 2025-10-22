import 'package:flutter/material.dart';  
import 'package:url_launcher/url_launcher.dart';  
  
class HelpScreen extends StatelessWidget {  
  const HelpScreen({super.key});  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Theme.of(context).colorScheme.surface,  
      appBar: AppBar(  
        title: const Text('Trợ giúp & Hỗ trợ'),  
        elevation: 0,  
      ),  
      body: SingleChildScrollView(  
        child: Column(  
          children: [  
            _buildHeader(context),  
            _buildFAQSection(context),  
            _buildContactSection(context),  
            _buildGuideSection(context),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildHeader(BuildContext context) {  
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
              Icons.help_outline,  
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
                  'Trợ giúp & Hỗ trợ',  
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
                    color: Colors.white,  
                    fontWeight: FontWeight.bold,  
                  ),  
                ),  
                Text(  
                  'Chúng tôi luôn sẵn sàng hỗ trợ bạn',  
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
  
  Widget _buildFAQSection(BuildContext context) {  
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
            child: Text(  
              'Câu hỏi thường gặp',  
              style: Theme.of(context).textTheme.titleLarge?.copyWith(  
                fontWeight: FontWeight.bold,  
              ),  
            ),  
          ),  
          _buildFAQItem(  
            context,  
            'Làm thế nào để điểm danh?',  
            'Quét mã QR từ giảng viên, sau đó thực hiện xác thực khuôn mặt để hoàn tất điểm danh.',  
          ),  
          _buildFAQItem(  
            context,  
            'Tại sao không thể đăng ký khuôn mặt?',  
            'Đảm bảo ánh sáng đủ, nhìn thẳng vào camera và không đeo kính râm hoặc khẩu trang.',  
          ),  
          _buildFAQItem(  
            context,  
            'Làm sao để xin phép nghỉ học?',  
            'Vào lịch sử điểm danh, chọn buổi học bạn vắng mặt và nhấn "Xin phép", sau đó đính kèm minh chứng.',  
          ),  
          _buildFAQItem(  
            context,  
            'Quên mật khẩu phải làm gì?',  
            'Nhấn "Quên mật khẩu" ở màn hình đăng nhập và làm theo hướng dẫn qua email.',  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildFAQItem(BuildContext context, String question, String answer) {  
    return ExpansionTile(  
      title: Text(  
        question,  
        style: Theme.of(context).textTheme.titleMedium?.copyWith(  
          fontWeight: FontWeight.w600,  
        ),  
      ),  
      children: [  
        Padding(  
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),  
          child: Text(  
            answer,  
            style: Theme.of(context).textTheme.bodyMedium,  
          ),  
        ),  
      ],  
    );  
  }  
  
  Widget _buildContactSection(BuildContext context) {  
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
            child: Text(  
              'Liên hệ hỗ trợ',  
              style: Theme.of(context).textTheme.titleLarge?.copyWith(  
                fontWeight: FontWeight.bold,  
              ),  
            ),  
          ),  
          _buildContactItem(  
            context,  
            icon: Icons.email,  
            title: 'Email hỗ trợ',  
            subtitle: 'support@ctut.edu.vn',  
            onTap: () => _launchEmail('support@ctut.edu.vn'),  
          ),  
          _buildContactItem(  
            context,  
            icon: Icons.phone,  
            title: 'Hotline',  
            subtitle: '0292.3.831.301',  
            onTap: () => _launchPhone('02923831301'),  
          ),  
          _buildContactItem(  
            context,  
            icon: Icons.location_on,  
            title: 'Địa chỉ',  
            subtitle: '256 Nguyễn Văn Cừ, An Hòa, Ninh Kiều, Cần Thơ',  
            onTap: () => _launchMaps(),  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildContactItem(  
    BuildContext context, {  
    required IconData icon,  
    required String title,  
    required String subtitle,  
    required VoidCallback onTap,  
  }) {  
    return InkWell(  
      onTap: onTap,  
      child: Padding(  
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
        child: Row(  
          children: [  
            Container(  
              width: 48,  
              height: 48,  
              decoration: BoxDecoration(  
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  
                borderRadius: BorderRadius.circular(24),  
              ),  
              child: Icon(  
                icon,  
                color: Theme.of(context).colorScheme.primary,  
                size: 24,  
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
                      fontWeight: FontWeight.w600,  
                    ),  
                  ),  
                  Text(  
                    subtitle,  
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
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
  
  Widget _buildGuideSection(BuildContext context) {  
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
            child: Text(  
              'Hướng dẫn sử dụng',  
              style: Theme.of(context).textTheme.titleLarge?.copyWith(  
                fontWeight: FontWeight.bold,  
              ),  
            ),  
          ),  
          _buildGuideItem(  
            context,  
            icon: Icons.face_retouching_natural,  
            title: 'Đăng ký khuôn mặt',  
            description: 'Hướng dẫn đăng ký khuôn mặt để điểm danh',  
          ),  
          _buildGuideItem(  
            context,  
            icon: Icons.qr_code_scanner,  
            title: 'Quét QR điểm danh',  
            description: 'Cách thức quét mã QR và xác thực khuôn mặt',  
          ),  
          _buildGuideItem(  
            context,  
            icon: Icons.event_note,  
            title: 'Xin phép nghỉ học',  
            description: 'Quy trình nộp đơn xin phép nghỉ học',  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildGuideItem(  
    BuildContext context, {  
    required IconData icon,  
    required String title,  
    required String description,  
  }) {  
    return InkWell(  
      onTap: () {  
        // Navigate to detailed guide  
      },  
      child: Padding(  
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),  
        child: Row(  
          children: [  
            Container(  
              width: 48,  
              height: 48,  
              decoration: BoxDecoration(  
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),  
                borderRadius: BorderRadius.circular(24),  
              ),  
              child: Icon(  
                icon,  
                color: Theme.of(context).colorScheme.secondary,  
                size: 24,  
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
                      fontWeight: FontWeight.w600,  
                    ),  
                  ),  
                  Text(  
                    description,  
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
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
  
  Future<void> _launchEmail(String email) async {  
    final Uri emailUri = Uri(  
      scheme: 'mailto',  
      path: email,  
      query: 'subject=Hỗ trợ ứng dụng CTUT Smart Attendance',  
    );  
      
    if (await canLaunchUrl(emailUri)) {  
      await launchUrl(emailUri);  
    }  
  }  
  
  Future<void> _launchPhone(String phone) async {  
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);  
      
    if (await canLaunchUrl(phoneUri)) {  
      await launchUrl(phoneUri);  
    }  
  }  
  
  Future<void> _launchMaps() async {  
    const String address = '256 Nguyễn Văn Cừ, An Hòa, Ninh Kiều, Cần Thơ';  
    final Uri mapsUri = Uri.parse('https://maps.google.com/?q=$address');  
      
    if (await canLaunchUrl(mapsUri)) {  
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);  
    }  
  }  
}