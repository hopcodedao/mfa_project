import 'package:flutter/material.dart';  
  
class ClassCard extends StatelessWidget {  
  final Map<String, dynamic> classData;  
  final VoidCallback? onTap;  
  
  const ClassCard({  
    super.key,  
    required this.classData,  
    this.onTap,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    final course = classData['course'];  
      
    return Container(  
      margin: const EdgeInsets.only(bottom: 12),  
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
      child: InkWell(  
        onTap: onTap,  
        borderRadius: BorderRadius.circular(12),  
        child: Padding(  
          padding: const EdgeInsets.all(16),  
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
                  Icons.class_,  
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
                      course['course_name'],  
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                        fontWeight: FontWeight.w600,  
                      ),  
                    ),  
                    const SizedBox(height: 4),  
                    Text(  
                      'Mã lớp: ${classData['class_code']}',  
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
                        color: Theme.of(context).colorScheme.outline,  
                      ),  
                    ),  
                    const SizedBox(height: 4),  
                    Text(  
                      'Giảng viên: ${classData['instructor']?['full_name'] ?? 'Chưa có thông tin'}',  
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
      ),  
    );  
  }  
}