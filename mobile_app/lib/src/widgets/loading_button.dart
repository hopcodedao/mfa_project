import 'package:flutter/material.dart';  
  
class LoadingButton extends StatelessWidget {  
  final String text;  
  final VoidCallback? onPressed;  
  final bool isLoading;  
  final Color? backgroundColor;  
  final Color? textColor;  
  final IconData? icon;  
  final double? width;  
  final double height;  
  
  const LoadingButton({  
    super.key,  
    required this.text,  
    this.onPressed,  
    this.isLoading = false,  
    this.backgroundColor,  
    this.textColor,  
    this.icon,  
    this.width,  
    this.height = 48,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return SizedBox(  
      width: width,  
      height: height,  
      child: ElevatedButton(  
        onPressed: isLoading ? null : onPressed,  
        style: ElevatedButton.styleFrom(  
          backgroundColor: backgroundColor ?? const Color(0xFF1976D2),  
          foregroundColor: textColor ?? Colors.white,  
          disabledBackgroundColor: Colors.grey[300],  
          shape: RoundedRectangleBorder(  
            borderRadius: BorderRadius.circular(8),  
          ),  
        ),  
        child: isLoading  
            ? const SizedBox(  
                width: 20,  
                height: 20,  
                child: CircularProgressIndicator(  
                  strokeWidth: 2,  
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),  
                ),  
              )  
            : Row(  
                mainAxisSize: MainAxisSize.min,  
                children: [  
                  if (icon != null) ...[  
                    Icon(icon, size: 18),  
                    const SizedBox(width: 8),  
                  ],  
                  Text(  
                    text,  
                    style: const TextStyle(  
                      fontSize: 16,  
                      fontWeight: FontWeight.w600,  
                    ),  
                  ),  
                ],  
              ),  
      ),  
    );  
  }  
}