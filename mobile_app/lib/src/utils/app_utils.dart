import 'package:flutter/material.dart';  
  
class AppUtils {  
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      SnackBar(  
        content: Row(  
          children: [  
            Icon(  
              isError ? Icons.error_outline : Icons.check_circle_outline,  
              color: Colors.white,  
              size: 20,  
            ),  
            const SizedBox(width: 8),  
            Expanded(  
              child: Text(  
                message,  
                style: const TextStyle(color: Colors.white),  
              ),  
            ),  
          ],  
        ),  
        backgroundColor: isError   
            ? Theme.of(context).colorScheme.error  
            : Theme.of(context).colorScheme.primary,  
        behavior: SnackBarBehavior.floating,  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(8),  
        ),  
        duration: Duration(seconds: isError ? 4 : 2),  
      ),  
    );  
  }  
  
  static void showConfirmDialog(  
    BuildContext context, {  
    required String title,  
    required String content,  
    required VoidCallback onConfirm,  
    String confirmText = 'Xác nhận',  
    String cancelText = 'Hủy',  
  }) {  
    showDialog(  
      context: context,  
      builder: (context) => AlertDialog(  
        title: Text(title),  
        content: Text(content),  
        shape: RoundedRectangleBorder(  
          borderRadius: BorderRadius.circular(12),  
        ),  
        actions: [  
          TextButton(  
            onPressed: () => Navigator.of(context).pop(),  
            child: Text(cancelText),  
          ),  
          ElevatedButton(  
            onPressed: () {  
              Navigator.of(context).pop();  
              onConfirm();  
            },  
            child: Text(confirmText),  
          ),  
        ],  
      ),  
    );  
  }  
}