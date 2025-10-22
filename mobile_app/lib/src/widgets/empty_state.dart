import 'package:flutter/material.dart';  
  
class EmptyState extends StatelessWidget {  
  final IconData icon;  
  final String title;  
  final String? subtitle;  
  final String? actionText;  
  final VoidCallback? onActionPressed;  
  
  const EmptyState({  
    super.key,  
    required this.icon,  
    required this.title,  
    this.subtitle,  
    this.actionText,  
    this.onActionPressed,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Center(  
      child: Padding(  
        padding: const EdgeInsets.all(32),  
        child: Column(  
          mainAxisSize: MainAxisSize.min,  
          children: [  
            Icon(  
              icon,  
              size: 80,  
              color: Colors.grey[400],  
            ),  
            const SizedBox(height: 16),  
            Text(  
              title,  
              style: const TextStyle(  
                fontSize: 18,  
                fontWeight: FontWeight.w600,  
                color: Color(0xFF757575),  
              ),  
              textAlign: TextAlign.center,  
            ),  
            if (subtitle != null) ...[  
              const SizedBox(height: 8),  
              Text(  
                subtitle!,  
                style: const TextStyle(  
                  fontSize: 14,  
                  color: Color(0xFFBDBDBD),  
                ),  
                textAlign: TextAlign.center,  
              ),  
            ],  
            if (actionText != null && onActionPressed != null) ...[  
              const SizedBox(height: 24),  
              ElevatedButton(  
                onPressed: onActionPressed,  
                child: Text(actionText!),  
              ),  
            ],  
          ],  
        ),  
      ),  
    );  
  }  
}