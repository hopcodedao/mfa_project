import 'package:flutter/material.dart';  
import '../api/student_service.dart';  
  
class AttendanceHistoryScreen extends StatefulWidget {  
  final int classId;  
  final String className;  
  const AttendanceHistoryScreen({super.key, required this.classId, required this.className});  
  
  @override  
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();  
}  
  
class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {  
  final StudentService _studentService = StudentService();  
  late Future<List<dynamic>> _historyFuture;  
  
  @override  
  void initState() {  
    super.initState();  
    _historyFuture = _studentService.getMyAttendanceHistory(widget.classId);  
  }  
  
  Widget _buildRequestStatus(String? status) {  
    if (status == null) return Container();  
    Color color;  
    String text;  
    IconData icon;  
      
    switch (status) {  
      case 'PENDING':  
        color = Colors.orange;  
        text = 'Chờ duyệt';  
        icon = Icons.pending;  
        break;  
      case 'APPROVED':  
        color = Colors.green;  
        text = 'Đã duyệt';  
        icon = Icons.check_circle;  
        break;  
      case 'REJECTED':  
        color = Colors.red;  
        text = 'Đã từ chối';  
        icon = Icons.cancel;  
        break;  
      default:  
        return Container();  
    }  
      
    return Container(  
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  
      decoration: BoxDecoration(  
        color: color.withOpacity(0.1),  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(color: color.withOpacity(0.3)),  
      ),  
      child: Row(  
        mainAxisSize: MainAxisSize.min,  
        children: [  
          Icon(icon, size: 16, color: color),  
          const SizedBox(width: 4),  
          Text(  
            text,  
            style: TextStyle(  
              color: color,  
              fontWeight: FontWeight.w600,  
              fontSize: 12,  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Theme.of(context).colorScheme.surface,  
      appBar: AppBar(  
        title: Text(widget.className),  
        elevation: 0,  
      ),  
      body: Column(  
        children: [  
          // Header thống kê  
          _buildStatsHeader(),  
            
          // Danh sách lịch sử  
          Expanded(  
            child: FutureBuilder<List<dynamic>>(  
              future: _historyFuture,  
              builder: (context, snapshot) {  
                if (snapshot.connectionState == ConnectionState.waiting) {  
                  return const Center(child: CircularProgressIndicator());  
                }  
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {  
                  return _buildEmptyState();  
                }  
                  
                final records = snapshot.data!;  
                return RefreshIndicator(  
                  onRefresh: () async {  
                    setState(() {  
                      _historyFuture = _studentService.getMyAttendanceHistory(widget.classId);  
                    });  
                  },  
                  child: ListView.builder(  
                    padding: const EdgeInsets.all(16),  
                    itemCount: records.length,  
                    itemBuilder: (ctx, i) {  
                      final record = records[i];  
                      return _buildAttendanceCard(record);  
                    },  
                  ),  
                );  
              },  
            ),  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildStatsHeader() {  
    return Container(  
      margin: const EdgeInsets.all(16),  
      padding: const EdgeInsets.all(20),  
      decoration: BoxDecoration(  
        gradient: LinearGradient(  
          begin: Alignment.topLeft,  
          end: Alignment.bottomRight,  
          colors: [  
            Theme.of(context).colorScheme.primary,  
            Theme.of(context).colorScheme.secondary,  
          ],  
        ),  
        borderRadius: BorderRadius.circular(16),  
      ),  
      child: Row(  
        children: [  
          Expanded(  
            child: _buildStatItem('Tổng buổi', '24', Icons.event),  
          ),  
          Container(  
            width: 1,  
            height: 40,  
            color: Colors.white.withOpacity(0.3),  
          ),  
          Expanded(  
            child: _buildStatItem('Có mặt', '20', Icons.check_circle),  
          ),  
          Container(  
            width: 1,  
            height: 40,  
            color: Colors.white.withOpacity(0.3),  
          ),  
          Expanded(  
            child: _buildStatItem('Vắng mặt', '4', Icons.cancel),  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildStatItem(String label, String value, IconData icon) {  
    return Column(  
      children: [  
        Icon(icon, color: Colors.white, size: 24),  
        const SizedBox(height: 8),  
        Text(  
          value,  
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
            color: Colors.white,  
            fontWeight: FontWeight.bold,  
          ),  
        ),  
        Text(  
          label,  
          style: Theme.of(context).textTheme.bodySmall?.copyWith(  
            color: Colors.white70,  
          ),  
        ),  
      ],  
    );  
  }  
  
  Widget _buildEmptyState() {  
    return Center(  
      child: Column(  
        mainAxisAlignment: MainAxisAlignment.center,  
        children: [  
          Container(  
            width: 120,  
            height: 120,  
            decoration: BoxDecoration(  
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),  
              borderRadius: BorderRadius.circular(60),  
            ),  
            child: Icon(  
              Icons.history,  
              size: 60,  
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),  
            ),  
          ),  
          const SizedBox(height: 24),  
          Text(  
            'Chưa có dữ liệu điểm danh',  
            style: Theme.of(context).textTheme.titleLarge?.copyWith(  
              fontWeight: FontWeight.w600,  
            ),  
          ),  
          const SizedBox(height: 8),  
          Text(  
            'Lịch sử điểm danh sẽ xuất hiện tại đây',  
            style: Theme.of(context).textTheme.bodyMedium,  
            textAlign: TextAlign.center,  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildAttendanceCard(Map<String, dynamic> record) {  
    final schedule = record['schedule'];  
    final status = record['status'];  
    final absenceRequestStatus = record['absence_request_status'];  
    bool canRequest = status == 'ABSENT' && absenceRequestStatus == null;  
      
    Color statusColor;  
    IconData statusIcon;  
    String statusText;  
      
    switch (status) {  
      case 'PRESENT':  
        statusColor = Colors.green;  
        statusIcon = Icons.check_circle;  
        statusText = 'Có mặt';  
        break;  
      case 'ABSENT':  
        statusColor = Colors.red;  
        statusIcon = Icons.cancel;  
        statusText = 'Vắng mặt';  
        break;  
      case 'LATE':  
        statusColor = Colors.orange;  
        statusIcon = Icons.access_time;  
        statusText = 'Muộn';  
        break;  
      default:  
        statusColor = Colors.grey;  
        statusIcon = Icons.help;  
        statusText = 'Không xác định';  
    }  
  
    return Container(  
      margin: const EdgeInsets.only(bottom: 12),  
      decoration: BoxDecoration(  
        color: Theme.of(context).colorScheme.surface,  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(  
          color: statusColor.withOpacity(0.2),  
        ),  
        boxShadow: [  
          BoxShadow(  
            color: Colors.black.withOpacity(0.05),  
            blurRadius: 8,  
            offset: const Offset(0, 2),  
          ),  
        ],  
      ),  
      child: Padding(  
        padding: const EdgeInsets.all(16),  
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Row(  
              children: [  
                Container(  
                  padding: const EdgeInsets.all(8),  
                  decoration: BoxDecoration(  
                    color: statusColor.withOpacity(0.1),  
                    borderRadius: BorderRadius.circular(8),  
                  ),  
                  child: Icon(  
                    statusIcon,  
                    color: statusColor,  
                    size: 20,  
                  ),  
                ),  
                const SizedBox(width: 12),  
                Expanded(  
                  child: Column(  
                    crossAxisAlignment: CrossAxisAlignment.start,  
                    children: [  
                      Text(  
                        '${schedule['group_code']} - ${schedule['date'] ?? 'Lịch cố định'}',  
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(  
                          fontWeight: FontWeight.w600,  
                        ),  
                      ),  
                      const SizedBox(height: 4),  
                      Row(  
                        children: [  
                          Text(  
                            'Trạng thái: ',  
                            style: Theme.of(context).textTheme.bodyMedium,  
                          ),  
                          Text(  
                            statusText,  
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
                              color: statusColor,  
                              fontWeight: FontWeight.w600,  
                            ),  
                          ),  
                        ],  
                      ),  
                    ],  
                  ),  
                ),  
                if (absenceRequestStatus != null)  
                  _buildRequestStatus(absenceRequestStatus)  
                else if (canRequest)  
                  ElevatedButton.icon(  
                    onPressed: () {  
                      Navigator.of(context).pushNamed(  
                        '/absence-request-form',  
                        arguments: schedule['id'],  
                      );  
                    },  
                    icon: const Icon(Icons.edit_note, size: 16),  
                    label: const Text('Xin phép'),  
                    style: ElevatedButton.styleFrom(  
                      backgroundColor: Theme.of(context).colorScheme.tertiary,  
                      foregroundColor: Colors.white,  
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),  
                      minimumSize: Size.zero,  
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,  
                    ),  
                  ),  
              ],  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}