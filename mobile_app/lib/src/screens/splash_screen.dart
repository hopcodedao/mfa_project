import 'package:flutter/material.dart';  
  
class SplashScreen extends StatefulWidget {  
  const SplashScreen({super.key});  
  
  @override  
  State<SplashScreen> createState() => _SplashScreenState();  
}  
  
class _SplashScreenState extends State<SplashScreen>  
    with SingleTickerProviderStateMixin {  
  late AnimationController _animationController;  
  late Animation<double> _fadeAnimation;  
  late Animation<double> _scaleAnimation;  
  
  @override  
  void initState() {  
    super.initState();  
    _animationController = AnimationController(  
      duration: const Duration(milliseconds: 2000),  
      vsync: this,  
    );  
  
    _fadeAnimation = Tween<double>(  
      begin: 0.0,  
      end: 1.0,  
    ).animate(CurvedAnimation(  
      parent: _animationController,  
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),  
    ));  
  
    _scaleAnimation = Tween<double>(  
      begin: 0.8,  
      end: 1.0,  
    ).animate(CurvedAnimation(  
      parent: _animationController,  
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),  
    ));  
  
    _animationController.forward();  
  }  
  
  @override  
  void dispose() {  
    _animationController.dispose();  
    super.dispose();  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      body: Container(  
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
        child: Center(  
          child: AnimatedBuilder(  
            animation: _animationController,  
            builder: (context, child) {  
              return FadeTransition(  
                opacity: _fadeAnimation,  
                child: ScaleTransition(  
                  scale: _scaleAnimation,  
                  child: Column(  
                    mainAxisAlignment: MainAxisAlignment.center,  
                    children: [  
                      Container(  
                        width: 120,  
                        height: 120,  
                        decoration: BoxDecoration(  
                          color: Colors.white.withOpacity(0.2),  
                          borderRadius: BorderRadius.circular(60),  
                        ),  
                        child: const Icon(  
                          Icons.school,  
                          size: 60,  
                          color: Colors.white,  
                        ),  
                      ),  
                      const SizedBox(height: 32),  
                      Text(  
                        'CTUT Smart Attendance',  
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(  
                          color: Colors.white,  
                          fontWeight: FontWeight.bold,  
                        ),  
                        textAlign: TextAlign.center,  
                      ),  
                      const SizedBox(height: 8),  
                      Text(  
                        'Trường ĐH Kỹ thuật - Công nghệ Cần Thơ',  
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(  
                          color: Colors.white70,  
                        ),  
                        textAlign: TextAlign.center,  
                      ),  
                      const SizedBox(height: 48),  
                      const SizedBox(  
                        width: 32,  
                        height: 32,  
                        child: CircularProgressIndicator(  
                          strokeWidth: 3,  
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),  
                        ),  
                      ),  
                    ],  
                  ),  
                ),  
              );  
            },  
          ),  
        ),  
      ),  
    );  
  }  
}