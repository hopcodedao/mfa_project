import 'package:flutter/material.dart';  
  
class LoadingOverlay extends StatelessWidget {  
  final bool isLoading;  
  final Widget child;  
  final String? loadingText;  
  final Color? backgroundColor;  
  
  const LoadingOverlay({  
    super.key,  
    required this.isLoading,  
    required this.child,  
    this.loadingText,  
    this.backgroundColor,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return Stack(  
      children: [  
        child,  
        if (isLoading)  
          Container(  
            color: backgroundColor ?? Colors.black54,  
            child: Center(  
              child: Card(  
                elevation: 8,  
                shape: RoundedRectangleBorder(  
                  borderRadius: BorderRadius.circular(12),  
                ),  
                child: Padding(  
                  padding: const EdgeInsets.all(24),  
                  child: Column(  
                    mainAxisSize: MainAxisSize.min,  
                    children: [  
                      const CircularProgressIndicator(  
                        valueColor: AlwaysStoppedAnimation<Color>(  
                          Color(0xFF1976D2),  
                        ),  
                      ),  
                      if (loadingText != null) ...[  
                        const SizedBox(height: 16),  
                        Text(  
                          loadingText!,  
                          style: const TextStyle(  
                            fontSize: 16,  
                            fontWeight: FontWeight.w500,  
                            color: Color(0xFF212121),  
                          ),  
                          textAlign: TextAlign.center,  
                        ),  
                      ],  
                    ],  
                  ),  
                ),  
              ),  
            ),  
          ),  
      ],  
    );  
  }  
}