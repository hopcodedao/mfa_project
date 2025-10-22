import 'package:flutter/material.dart';  
import 'dart:io';  
import 'package:image_picker/image_picker.dart';  
import '../api/student_service.dart';  
  
class AbsenceRequestFormScreen extends StatefulWidget {  
  final int scheduleId;  
  const AbsenceRequestFormScreen({super.key, required this.scheduleId});  
  
  @override  
  State<AbsenceRequestFormScreen> createState() => _AbsenceRequestFormScreenState();  
}  
  
class _AbsenceRequestFormScreenState extends State<AbsenceRequestFormScreen> {  
  final _formKey = GlobalKey<FormState>();  
  final _reasonController = TextEditingController();  
  File? _proofImage;  
  bool _isLoading = false;  
  String? _errorMessage;  
  
  @override  
  void dispose() {  
    _reasonController.dispose();  
    super.dispose();  
  }  
  
  Future<void> _pickImage(ImageSource source) async {  
    final picker = ImagePicker();  
    final pickedFile = await picker.pickImage(  
      source: source,  
      maxWidth: 1024,  
      maxHeight: 1024,  
      imageQuality: 85,  
    );  
      
    if (pickedFile != null) {  
      setState(() {  
        _proofImage = File(pickedFile.path);  
        _errorMessage = null;  
      });  
    }  
  }  
  
  Future<void> _submit() async {  
    if (!_formKey.currentState!.validate()) return;  
      
    if (_proofImage == null) {  
      setState(() {  
        _errorMessage = 'Vui lòng đính kèm ảnh minh chứng';  
      });  
      return;  
    }  
  
    setState(() {  
      _isLoading = true;  
      _errorMessage = null;  
    });  
  
    try {  
      final response = await StudentService().submitAbsenceRequest(  
        scheduleId: widget.scheduleId,  
        reason: _reasonController.text,  
        proofImage: _proofImage!,  
      );  
  
      if (response.statusCode == 201) {  
        if (mounted) {  
          ScaffoldMessenger.of(context).showSnackBar(  
            SnackBar(  
              content: const Text('Nộp đơn thành công!'),  
              backgroundColor: Theme.of(context).colorScheme.primary,  
            ),  
          );  
          Navigator.of(context).pop();  
        }  
      } else {  
        final responseBody = await response.stream.bytesToString();  
        throw Exception('Lỗi: $responseBody');  
      }  
    } catch (e) {  
      setState(() {  
        _errorMessage = 'Lỗi nộp đơn: ${e.toString()}';  
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
        title: const Text('Nộp đơn xin phép nghỉ'),  
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
              
            // Form  
            _buildForm(),  
              
            const SizedBox(height: 24),  
              
            // Image picker section  
            _buildImageSection(),  
              
            const SizedBox(height: 32),  
              
            // Error message  
            if (_errorMessage != null) _buildErrorMessage(),  
              
            // Submit button  
            _buildSubmitButton(),  
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
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),  
            borderRadius: BorderRadius.circular(40),  
          ),  
          child: Icon(  
            Icons.event_note,  
            size: 40,  
            color: Theme.of(context).colorScheme.tertiary,  
          ),  
        ),  
        const SizedBox(height: 16),  
        Text(  
          'Đơn xin phép nghỉ học',  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            fontWeight: FontWeight.bold,  
          ),  
        ),  
        const SizedBox(height: 8),  
        Text(  
          'Vui lòng điền đầy đủ thông tin và đính kèm minh chứng',  
          style: Theme.of(context).textTheme.bodyMedium,  
          textAlign: TextAlign.center,  
        ),  
      ],  
    );  
  }  
  
  Widget _buildForm() {  
    return Form(  
      key: _formKey,  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          Text(  
            'Lý do xin nghỉ *',  
            style: Theme.of(context).textTheme.titleMedium?.copyWith(  
              fontWeight: FontWeight.w600,  
            ),  
          ),  
          const SizedBox(height: 8),  
          TextFormField(  
            controller: _reasonController,  
            maxLines: 4,  
            decoration: InputDecoration(  
              hintText: 'Nhập lý do xin nghỉ học...',  
              border: OutlineInputBorder(  
                borderRadius: BorderRadius.circular(12),  
              ),  
            ),  
            validator: (value) {  
              if (value == null || value.trim().isEmpty) {  
                return 'Vui lòng nhập lý do xin nghỉ';  
              }  
              if (value.trim().length < 10) {  
                return 'Lý do phải có ít nhất 10 ký tự';  
              }  
              return null;  
            },  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildImageSection() {  
    return Column(  
      crossAxisAlignment: CrossAxisAlignment.start,  
      children: [  
        Text(  
          'Minh chứng *',  
          style: Theme.of(context).textTheme.titleMedium?.copyWith(  
            fontWeight: FontWeight.w600,  
          ),  
        ),  
        const SizedBox(height: 8),  
          
        if (_proofImage == null) ...[  
          Container(  
            height: 200,  
            decoration: BoxDecoration(  
              color: Theme.of(context).colorScheme.surface,  
              borderRadius: BorderRadius.circular(12),  
              border: Border.all(  
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),  
              ),  
            ),  
            child: Column(  
              mainAxisAlignment: MainAxisAlignment.center,  
              children: [  
                Icon(  
                  Icons.add_photo_alternate,  
                  size: 64,  
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),  
                ),  
                const SizedBox(height: 16),  
                Text(  
                  'Chưa có ảnh minh chứng',  
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(  
                    color: Theme.of(context).colorScheme.outline,  
                  ),  
                ),  
              ],  
            ),  
          ),  
          const SizedBox(height: 16),  
          Row(  
            children: [  
              Expanded(  
                child: OutlinedButton.icon(  
                  onPressed: () => _pickImage(ImageSource.gallery),  
                  icon: const Icon(Icons.photo_library),  
                  label: const Text('Thư viện'),  
                  style: OutlinedButton.styleFrom(  
                    padding: const EdgeInsets.symmetric(vertical: 16),  
                    shape: RoundedRectangleBorder(  
                      borderRadius: BorderRadius.circular(12),  
                    ),  
                  ),  
                ),  
              ),  
              const SizedBox(width: 16),  
              Expanded(  
                child: ElevatedButton.icon(  
                  onPressed: () => _pickImage(ImageSource.camera),  
                  icon: const Icon(Icons.camera_alt),  
                  label: const Text('Chụp ảnh'),  
                  style: ElevatedButton.styleFrom(  
                    padding: const EdgeInsets.symmetric(vertical: 16),  
                    shape: RoundedRectangleBorder(  
                      borderRadius: BorderRadius.circular(12),  
                    ),  
                  ),  
                ),  
              ),  
            ],  
          ),  
        ] else ...[  
          Container(  
            height: 200,  
            decoration: BoxDecoration(  
              borderRadius: BorderRadius.circular(12),  
              border: Border.all(  
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),  
              ),  
            ),  
            child: ClipRRect(  
              borderRadius: BorderRadius.circular(12),  
              child: Image.file(  
                _proofImage!,  
                fit: BoxFit.cover,  
                width: double.infinity,  
              ),  
            ),  
          ),  
          const SizedBox(height: 16),  
          Row(  
            children: [  
              Expanded(  
                child: OutlinedButton.icon(  
                  onPressed: () => _pickImage(ImageSource.gallery),  
                  icon: const Icon(Icons.photo_library),  
                  label: const Text('Chọn ảnh khác'),  
                  style: OutlinedButton.styleFrom(  
                    padding: const EdgeInsets.symmetric(vertical: 12),  
                    shape: RoundedRectangleBorder(  
                      borderRadius: BorderRadius.circular(12),  
                    ),  
                  ),  
                ),  
              ),  
              const SizedBox(width: 16),  
              Expanded(  
                child: ElevatedButton.icon(  
                  onPressed: () => _pickImage(ImageSource.camera),  
                  icon: const Icon(Icons.camera_alt),  
                  label: const Text('Chụp lại'),  
                  style: ElevatedButton.styleFrom(  
                    padding: const EdgeInsets.symmetric(vertical: 12),  
                    shape: RoundedRectangleBorder(  
                      borderRadius: BorderRadius.circular(12),  
                    ),  
                  ),  
                ),  
              ),  
            ],  
          ),  
        ],  
      ],  
    );  
  }  
  
  Widget _buildErrorMessage() {  
    return Container(  
      margin: const EdgeInsets.only(bottom: 16),  
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
    );  
  }  
  
  Widget _buildSubmitButton() {  
    return SizedBox(  
      height: 56,  
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
                'Nộp đơn xin phép',  
                style: TextStyle(  
                  fontSize: 16,  
                  fontWeight: FontWeight.w600,  
                ),  
              ),  
      ),  
    );  
  }  
}