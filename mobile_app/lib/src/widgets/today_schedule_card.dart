import 'package:flutter/material.dart';  
  
class TodayScheduleCard extends StatelessWidget {  
  final Map<String, dynamic> schedule;  
  final VoidCallback? onTap;  
  
  const TodayScheduleCard({  
    super.key,  
    required this.schedule,  
    this.onTap,  
  });  
  
  @override  
  Widget build(BuildContext context) {  
    final course = schedule['class_instance']['course'];  
    final room = schedule['room'];  
  
    return Container(  
      margin: const EdgeInsets.only(bottom: 12),  
      decoration: BoxDecoration(  
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(  
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),  
        ),  
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
          child: Column(  
            crossAxisAlignment: CrossAxisAlignment.start,  
            children: [  
              Row(  
                children: [  
                  Container(  
                    width: 4,  
                    height: 40,  
                    decoration: BoxDecoration(  
                      color: Theme.of(context).colorScheme.primary,  
                      borderRadius: BorderRadius.circular(2),  
                    ),  
                  ),  
                  const SizedBox(width: 12),  
                  Expanded(  
                    child: Text(  
                      course['course_name'],  
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                        fontWeight: FontWeight.w600,  
                      ),  
                    ),  
                  ),  
                ],  
              ),  
              const SizedBox(height: 12),  
              Row(  
                children: [  
                  Icon(  
                    Icons.access_time,  
                    size: 16,  
                    color: Theme.of(context).colorScheme.outline,  
                  ),  
                  const SizedBox(width: 8),  
                  Text(  
                    '${schedule['start_time']} - ${schedule['end_time']}',  
                    style: Theme.of(context).textTheme.bodyMedium,  
                  ),  
                ],  
              ),  
              const SizedBox(height: 4),  
              Row(  
                children: [  
                  Icon(  
                    Icons.location_on,  
                    size: 16,  
                    color: Theme.of(context).colorScheme.outline,  
                  ),  
                  const SizedBox(width: 8),  
                  Text(  
                    'Phòng: ${room?['room_code'] ?? 'TBA'} - Nhóm: ${schedule['group_code']}',
                    style: Theme.of(context).textTheme.bodyMedium,  
                  ),  
                ],  
              ),  
              const SizedBox(height: 16),  
              SizedBox(  
                width: double.infinity,  
                child: ElevatedButton.icon(  
                  onPressed: () {  
                    Navigator.of(context).pushNamed('/qr-scan', arguments: schedule['id']);  
                  },  
                  icon: const Icon(Icons.qr_code_scanner),  
                  label: const Text('Điểm danh ngay'),  
                  style: ElevatedButton.styleFrom(  
                    padding: const EdgeInsets.symmetric(vertical: 12),  
                    shape: RoundedRectangleBorder(  
                      borderRadius: BorderRadius.circular(8),  
                    ),  
                  ),  
                ),  
              ),  
            ],  
          ),  
        ),  
      ),  
    );  
  }  
}