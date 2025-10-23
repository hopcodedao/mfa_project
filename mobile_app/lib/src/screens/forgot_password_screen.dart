import 'package:flutter/material.dart';  
import '../api/auth_service.dart';  
  
class ForgotPasswordScreen extends StatefulWidget {  
  const ForgotPasswordScreen({super.key});  
  
  @override  
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();  
}  
  
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {  
  final _formKey = GlobalKey<FormState>();  
  final _emailController = TextEditingController();  
  final AuthService _authService = AuthService();  
    
  bool _isLoading = false;  
  bool _isEmailSent = false;  
  String? _errorMessage;  
  
  @override  
  void dispose() {  
    _emailController.dispose();  
    super.dispose();  
  }  
  
  Future<void> _sendResetEmail() async {  
    if (!_formKey.currentState!.validate()) return;  
  
    setState(() {  
      _isLoading = true;  
      _errorMessage = null;  
    });  
  
    try {  
      final response = await _authService.requestPasswordReset(_emailController.text);
      if (response['success'] != null) {
        setState(() {  
          _isEmailSent = true;  
        });
      } else {
        throw Exception('Không nhận được phản hồi từ server');
      }
    } catch (e) {  
      setState(() {  
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });  
    } finally {  
      setState(() {  
        _isLoading = false;  
      });  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Theme.of(context).colorScheme.surface,  
      appBar: AppBar(  
        title: const Text('Quên mật khẩu'),  
        elevation: 0,  
      ),  
      body: SingleChildScrollView(  
        padding: const EdgeInsets.all(24.0),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.stretch,  
          children: [  
            // Header  
            _buildHeader(),  
              
            const SizedBox(height: 32),  
              
            if (_isEmailSent)  
              _buildSuccessMessage()  
            else  
              _buildForm(),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildHeader() {  
    return Column(  
      children: [  
        Container(  
          width: 80,  
          height: 80,  
          decoration: BoxDecoration(  
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  
            borderRadius: BorderRadius.circular(40),  
          ),  
          child: Icon(  
            Icons.lock_reset,  
            size: 40,  
            color: Theme.of(context).colorScheme.primary,  
          ),  
        ),  
        const SizedBox(height: 16),  
        Text(  
          'Quên mật khẩu?',  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            fontWeight: FontWeight.bold,  
          ),  
        ),  
        const SizedBox(height: 8),  
        Text(  
          'Nhập email của bạn để nhận liên kết đặt lại mật khẩu',  
          style: Theme.of(context).textTheme.bodyMedium,  
          textAlign: TextAlign.center,  
        ),  
      ],  
    );  
  }  
  
  Widget _buildForm() {  
    return Column(  
      children: [  
        Form(  
          key: _formKey,  
          child: TextFormField(  
            controller: _emailController,  
            keyboardType: TextInputType.emailAddress,  
            decoration: InputDecoration(  
              labelText: 'Email',  
              prefixIcon: Icon(  
                Icons.email_outlined,  
                color: Theme.of(context).colorScheme.primary,  
              ),  
            ),  
            validator: (value) {  
              if (value == null || value.isEmpty) {  
                return 'Vui lòng nhập email';  
              }  
              if (!RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$').hasMatch(value)) {  
                return 'Email không hợp lệ';  
              }  
              return null;  
            },  
            textInputAction: TextInputAction.done,  
            onFieldSubmitted: (_) => _sendResetEmail(),  
          ),  
        ),  
          
        const SizedBox(height: 24),  
          
        // Error message  
        if (_errorMessage != null) ...[  
          Container(  
            padding: const EdgeInsets.all(12),  
            decoration: BoxDecoration(  
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),  
              borderRadius: BorderRadius.circular(8),  
              border: Border.all(  
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),  
              ),  
            ),  
            child: Row(  
              children: [  
                Icon(  
                  Icons.error_outline,  
                  color: Theme.of(context).colorScheme.error,  
                  size: 20,  
                ),  
                const SizedBox(width: 8),  
                Expanded(  
                  child: Text(  
                    _errorMessage!,  
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
                      color: Theme.of(context).colorScheme.error,  
                    ),  
                  ),  
                ),  
              ],  
            ),  
          ),  
          const SizedBox(height: 16),  
        ],  
          
        // Send button  
        SizedBox(  
          height: 56,  
          width: double.infinity,  
          child: ElevatedButton(  
            onPressed: _isLoading ? null : _sendResetEmail,  
            style: ElevatedButton.styleFrom(  
              shape: RoundedRectangleBorder(  
                borderRadius: BorderRadius.circular(12),  
              ),  
            ),  
            child: _isLoading  
                ? const SizedBox(  
                    width: 24,  
                    height: 24,  
                    child: CircularProgressIndicator(  
                      strokeWidth: 2,  
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),  
                    ),  
                  )  
                : const Text(  
                    'Gửi email đặt lại',  
                    style: TextStyle(  
                      fontSize: 16,  
                      fontWeight: FontWeight.w600,  
                    ),  
                  ),  
          ),  
        ),  
          
        const SizedBox(height: 16),  
          
        // Back to login  
        TextButton(  
          onPressed: () => Navigator.of(context).pop(),  
          child: Text(  
            'Quay lại đăng nhập',  
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
              color: Theme.of(context).colorScheme.primary,  
              fontWeight: FontWeight.w500,  
            ),  
          ),  
        ),  
      ],  
    );  
  }  
  
  Widget _buildSuccessMessage() {  
    return Column(  
      children: [  
        Container(  
          width: 120,  
          height: 120,  
          decoration: BoxDecoration(  
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  
            borderRadius: BorderRadius.circular(60),  
          ),  
          child: Icon(  
            Icons.mark_email_read,  
            size: 60,  
            color: Theme.of(context).colorScheme.primary,  
          ),  
        ),  
        const SizedBox(height: 24),  
        Text(  
          'Email đã được gửi!',  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            fontWeight: FontWeight.bold,  
            color: Theme.of(context).colorScheme.primary,  
          ),  
        ),  
        const SizedBox(height: 16),  
        Text(  
          'Chúng tôi đã gửi liên kết đặt lại mật khẩu đến email của bạn. Vui lòng kiểm tra hộp thư và làm theo hướng dẫn.',  
          style: Theme.of(context).textTheme.bodyMedium,  
          textAlign: TextAlign.center,  
        ),  
        const SizedBox(height: 32),  
        SizedBox(  
          width: double.infinity,  
          child: ElevatedButton(  
            onPressed: () => Navigator.of(context).pop(),  
            style: ElevatedButton.styleFrom(  
              shape: RoundedRectangleBorder(  
                borderRadius: BorderRadius.circular(12),  
              ),  
            ),  
            child: const Text('Quay lại đăng nhập'),  
          ),  
        ),  
      ],  
    );  
  }  
}