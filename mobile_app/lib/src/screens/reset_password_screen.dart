import 'package:flutter/material.dart';  
import 'dart:convert';  
import '../api/auth_service.dart';  
  
class ResetPasswordScreen extends StatefulWidget {  
  final String uidb64;  
  final String token;  
  
  const ResetPasswordScreen({  
    super.key,  
    required this.uidb64,  
    required this.token,  
  });  
  
  @override  
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();  
}  
  
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {  
  final _formKey = GlobalKey<FormState>();  
  final _newPasswordController = TextEditingController();  
  final _confirmPasswordController = TextEditingController();  
  final AuthService _authService = AuthService();  
    
  bool _isLoading = false;  
  bool _obscureNewPassword = true;  
  bool _obscureConfirmPassword = true;  
  String? _errorMessage;  
  bool _isSuccess = false;  
  
  @override  
  void dispose() {  
    _newPasswordController.dispose();  
    _confirmPasswordController.dispose();  
    super.dispose();  
  }  
  
  Future<void> _submit() async {  
    if (!_formKey.currentState!.validate()) return;  
  
    setState(() {  
      _isLoading = true;  
      _errorMessage = null;  
    });  
  
    try {  
      final response = await _authService.confirmPasswordReset(  
        uidb64: widget.uidb64,  
        token: widget.token,  
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );  
  
      if (response['success'] != null) {  
        setState(() {  
          _isSuccess = true;  
        });  
          
        // Auto navigate after 3 seconds  
        Future.delayed(const Duration(seconds: 3), () {  
          if (mounted) {  
            Navigator.of(context).pushNamedAndRemoveUntil(  
              '/login',   
              (route) => false,  
            );  
          }  
        });  
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
        title: const Text('Đặt lại mật khẩu'),  
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
              
            if (_isSuccess)  
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
          'Đặt lại mật khẩu',  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            fontWeight: FontWeight.bold,  
          ),  
        ),  
        const SizedBox(height: 8),  
        Text(  
          'Tạo mật khẩu mới cho tài khoản của bạn',  
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
          child: Column(  
            children: [  
              // New password  
              TextFormField(  
                controller: _newPasswordController,  
                obscureText: _obscureNewPassword,  
                decoration: InputDecoration(  
                  labelText: 'Mật khẩu mới',  
                  prefixIcon: Icon(  
                    Icons.lock,  
                    color: Theme.of(context).colorScheme.primary,  
                  ),  
                  suffixIcon: IconButton(  
                    icon: Icon(  
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,  
                      color: Theme.of(context).colorScheme.primary,  
                    ),  
                    onPressed: () {  
                      setState(() {  
                        _obscureNewPassword = !_obscureNewPassword;  
                      });  
                    },  
                  ),  
                ),  
                validator: (value) {  
                  if (value == null || value.isEmpty) {  
                    return 'Vui lòng nhập mật khẩu mới';  
                  }  
                  if (value.length < 8) {  
                    return 'Mật khẩu phải có ít nhất 8 ký tự';  
                  }  
                  return null;  
                },  
                textInputAction: TextInputAction.next,  
              ),  
                
              const SizedBox(height: 16),  
                
              // Confirm password  
              TextFormField(  
                controller: _confirmPasswordController,  
                obscureText: _obscureConfirmPassword,  
                decoration: InputDecoration(  
                  labelText: 'Xác nhận mật khẩu mới',  
                  prefixIcon: Icon(  
                    Icons.lock_reset,  
                    color: Theme.of(context).colorScheme.primary,  
                  ),  
                  suffixIcon: IconButton(  
                    icon: Icon(  
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,  
                      color: Theme.of(context).colorScheme.primary,  
                    ),  
                    onPressed: () {  
                      setState(() {  
                        _obscureConfirmPassword = !_obscureConfirmPassword;  
                      });  
                    },  
                  ),  
                ),  
                validator: (value) {  
                  if (value == null || value.isEmpty) {  
                    return 'Vui lòng xác nhận mật khẩu mới';  
                  }  
                  if (value != _newPasswordController.text) {  
                    return 'Mật khẩu xác nhận không khớp';  
                  }  
                  return null;  
                },  
                textInputAction: TextInputAction.done,  
                onFieldSubmitted: (_) => _submit(),  
              ),  
            ],  
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
          
        // Submit button  
        SizedBox(  
          height: 56,  
          width: double.infinity,  
          child: ElevatedButton(  
            onPressed: _isLoading ? null : _submit,  
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
                    'Đặt lại mật khẩu',  
                    style: TextStyle(  
                      fontSize: 16,  
                      fontWeight: FontWeight.w600,  
                    ),  
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
            Icons.check_circle,  
            size: 60,  
            color: Theme.of(context).colorScheme.primary,  
          ),  
        ),  
        const SizedBox(height: 24),  
        Text(  
          'Đặt lại mật khẩu thành công!',  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            fontWeight: FontWeight.bold,  
            color: Theme.of(context).colorScheme.primary,  
          ),  
        ),  
        const SizedBox(height: 16),  
        Text(  
          'Mật khẩu của bạn đã được cập nhật thành công. Bạn sẽ được chuyển về trang đăng nhập sau 3 giây.',  
          style: Theme.of(context).textTheme.bodyMedium,  
          textAlign: TextAlign.center,  
        ),  
        const SizedBox(height: 32),  
        const CircularProgressIndicator(),  
      ],  
    );  
  }  
}