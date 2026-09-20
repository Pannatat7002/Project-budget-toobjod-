import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart' as di;
import '../../../security/data/datasources/security_local_data_source.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Mark that splash was displayed today
    _markSplashShownToday();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto navigate to main dashboard after 1.0 second (faster)
    _timer = Timer(const Duration(milliseconds: 1000), _goToDashboard);
  }

  void _markSplashShownToday() {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      di.sl<SharedPreferences>().setString(AppConstants.lastSplashDateKey, today);
    } catch (_) {}
  }

  void _goToDashboard() {
    if (mounted) {
      try {
        final isPinEnabled = di.sl<SecurityLocalDataSource>().isPinEnabled();
        if (isPinEnabled) {
          context.go('/pin');
          return;
        }
      } catch (_) {}
      context.go('/');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFEA580C),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToDashboard, // Tap anywhere to skip splash instantly
        child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF8A00),
                Color(0xFFEA580C),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cute Mascot Icon (PNG)
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Image.asset(
                          'assets/images/mascot_dog_peek.png',
                          cacheWidth: 280,
                          cacheHeight: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.pets,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // App Name (เหมือนในรูปตัวอย่าง เหมียวจด แต่เป็น เจ้าตูบจด)
                      const Text(
                        'เจ้าตูบจด',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0B132B), // Deep Midnight Navy text
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ผู้ช่วยวางแผนคุมงบการเงิน 🐾',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
