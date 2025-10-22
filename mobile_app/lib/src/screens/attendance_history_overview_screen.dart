import 'package:flutter/material.dart';  
import '../api/student_service.dart';  
  
class AttendanceHistoryOverviewScreen extends StatefulWidget {  
  const AttendanceHistoryOverviewScreen({super.key});  
  
  @override  
  State<AttendanceHistoryOverviewScreen> createState() => _AttendanceHistoryOverviewScreenState();  
}  
  
class _AttendanceHistoryOverviewScreenState extends State<AttendanceHistoryOverviewScreen> {  
  final StudentService _studentService = StudentService();  
  List<dynamic> _enrolledClasses = [];  
  bool _isLoading = true;  
  
  @override  
  void initState() {  
    super.initState();  
    _loadEnrolledClasses();  
  }  
  
  Future<void> _loadEnrolledClasses() async {  
    try {  
      final classes = await _studentService.getEnrolledClasses();  
      setState(() {  
        _enrolledClasses = classes;  
        _isLoading = false;  
      });  
    } catch (e) {  
      setState(() {  
        _isLoading = false;  
      });  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      backgroundColor: Theme.of(context).colorScheme.surface,  
      body: SafeArea(  
        child: Column(  
          children: [  
            // Custom header  
            _buildHeader(),  
              
            // Classes list  
            Expanded(  
              child: _isLoading  
                  ? const Center(child: CircularProgressIndicator())  
                  : _enrolledClasses.isEmpty  
                      ? _buildEmptyState()  
                      : RefreshIndicator(  
                          onRefresh: _loadEnrolledClasses,  
                          child: ListView.builder(  
                            padding: const EdgeInsets.all(16),  
                            itemCount: _enrolledClasses.length,  
                            itemBuilder: (context, index) {  
                              final classData = _enrolledClasses[index]['class_instance'];  
                              return _buildClassCard(classData);  
                            },  
                          ),  
                        ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildHeader() {  
    return Container(  
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
      ),  
      child: Row(  
        children: [  
          Container(  
            padding: const EdgeInsets.all(8),  
            decoration: BoxDecoration(  
              color: Colors.white.withOpacity(0.2),  
              borderRadius: BorderRadius.circular(8),  
            ),  
            child: const Icon(  
              Icons.history,  
              color: Colors.white,  
              size: 24,  
            ),  
          ),  
          const SizedBox(width: 16),  
          Expanded(  
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,  
              children: [  
                Text(  
                  'Lịch sử điểm danh',  
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(  
                    color: Colors.white,  
                    fontWeight: FontWeight.bold,  
                  ),  
                ),  
                Text(  
                  'Xem chi tiết điểm danh theo từng lớp',  
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(  
                    color: Colors.white70,  
                  ),  
                ),  
              ],  
            ),  
          ),  
        ],  
      ),  
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
              Icons.class_outlined,  
              size: 60,  
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),  
            ),  
          ),  
          const SizedBox(height: 24),  
          Text(  
            'Chưa có lớp học nào',  
            style: Theme.of(context).textTheme.titleLarge?.copyWith(  
              fontWeight: FontWeight.w600,  
            ),  
          ),  
          const SizedBox(height: 8),  
          Text(  
            'Bạn chưa đăng ký lớp học nào',  
            style: Theme.of(context).textTheme.bodyMedium,  
            textAlign: TextAlign.center,  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildClassCard(Map<String, dynamic> classData) {  
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
        onTap: () {  
          Navigator.of(context).pushNamed(  
            '/attendance-history',  
            arguments: {  
              'classId': classData['id'],  
              'className': classData['course']['course_name'],  
            },  
          );  
        },  
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
                      classData['course']['course_name'],  
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