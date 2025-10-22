import 'package:flutter/material.dart';  
import 'dashboard_screen.dart';  
import 'class_list_screen.dart';  
import 'notification_screen.dart';
import 'attendance_history_overview_screen.dart';
  
class MainNavigationScreen extends StatefulWidget {  
  const MainNavigationScreen({super.key});  
  
  @override  
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();  
}  
  
class _MainNavigationScreenState extends State<MainNavigationScreen> {  
  int _currentIndex = 0;  
    
  final List<Widget> _screens = [  
    const DashboardScreen(),  
    const ClassListScreen(),  
    const AttendanceHistoryOverviewScreen(), 
    const NotificationScreen(),  
  ];  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      body: IndexedStack(  
        index: _currentIndex,  
        children: _screens,  
      ),  
      bottomNavigationBar: Container(  
        decoration: BoxDecoration(  
          boxShadow: [  
            BoxShadow(  
              color: Colors.black.withOpacity(0.1),  
              blurRadius: 10,  
              offset: const Offset(0, -2),  
            ),  
          ],  
        ),  
        child: BottomNavigationBar(  
          currentIndex: _currentIndex,  
          onTap: (index) {  
            setState(() {  
              _currentIndex = index;  
            });  
          },  
          type: BottomNavigationBarType.fixed,  
          backgroundColor: Theme.of(context).colorScheme.surface,  
          selectedItemColor: Theme.of(context).colorScheme.primary,  
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),  
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),  
          items: const [  
            BottomNavigationBarItem(  
              icon: Icon(Icons.dashboard_outlined),  
              activeIcon: Icon(Icons.dashboard),  
              label: 'Trang chủ',  
            ),  
            BottomNavigationBarItem(  
              icon: Icon(Icons.class_outlined),  
              activeIcon: Icon(Icons.class_),  
              label: 'Lớp học',  
            ),  
            BottomNavigationBarItem(  
              icon: Icon(Icons.history_outlined),  
              activeIcon: Icon(Icons.history),  
              label: 'Lịch sử',  
            ),  
            BottomNavigationBarItem(  
              icon: Icon(Icons.notifications_outlined),  
              activeIcon: Icon(Icons.notifications),  
              label: 'Thông báo',  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
}