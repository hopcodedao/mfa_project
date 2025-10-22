import 'package:flutter/material.dart';  
  
class CTUTAppBar extends StatelessWidget implements PreferredSizeWidget {  
  final String title;  
  final List<Widget>? actions;  
  final bool showLogo;  
  final VoidCallback? onBackPressed;  
  
  const CTUTAppBar({  
    super.key,  
    required this.title,  
    this.actions,  
    this.showLogo = true,  
    this.onBackPressed,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    return AppBar(  
      title: Row(  
        mainAxisSize: MainAxisSize.min,  
        children: [  
          if (showLogo) ...[  
            Container(  
              width: 32,  
              height: 32,  
              decoration: BoxDecoration(  
                color: Colors.white,  
                borderRadius: BorderRadius.circular(6),  
              ),  
              child: const Icon(  
                Icons.school,  
                color: Color(0xFF1976D2),  
                size: 20,  
              ),  
            ),  
            const SizedBox(width: 8),  
          ],  
          Flexible(  
            child: Text(  
              title,  
              style: const TextStyle(  
                fontSize: 18,  
                fontWeight: FontWeight.w600,  
              ),  
              overflow: TextOverflow.ellipsis,  
            ),  
          ),  
        ],  
      ),  
      actions: actions,  
      leading: onBackPressed != null  
          ? IconButton(  
              icon: const Icon(Icons.arrow_back),  
              onPressed: onBackPressed,  
            )  
          : null,  
      elevation: 2,  
      shadowColor: Colors.black26,  
    );  
  }  
  
  @override  
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);  
}