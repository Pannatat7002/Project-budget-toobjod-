import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _wiggleController;
  late Animation<double> _tiltAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _tailWagAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Mark that splash was displayed today
    _markSplashShownToday();

    // 1. Entry Animation (Pop in)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    // 2. Playful Continuous Wiggle & Tail-Wag Animation
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _tiltAnimation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(
        parent: _wiggleController,
        curve: Curves.easeInOutSine,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _wiggleController,
        curve: Curves.easeInOutQuad,
      ),
    );

    _tailWagAnimation = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(
        parent: _wiggleController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entryController.forward().then((_) {
      if (mounted) {
        _wiggleController.repeat(reverse: true);
      }
    });

    // Auto navigate to main dashboard after 1.5 seconds (gives user time to enjoy the dog)
    _timer = Timer(const Duration(milliseconds: 1500), _goToDashboard);
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
    _entryController.dispose();
    _wiggleController.dispose();
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
          backgroundColor: const Color(0xFFFF7A00),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8A00),
                  Color(0xFFEA580C),
                  Color(0xFFC2410C),
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
                        // Animated Mascot Dog with Tail Wag and Playful Bounce
                        _buildAnimatedDogMascot(),
                        const SizedBox(height: 20),

                        // App Name
                        Text(
                          'เจ้าตูบจด',
                          style: GoogleFonts.prompt(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🐾 ', style: TextStyle(fontSize: 13)),
                              Text(
                                'ผู้ช่วยวางแผนคุมงบการเงิน',
                                style: GoogleFonts.prompt(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
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

  Widget _buildAnimatedDogMascot() {
    return AnimatedBuilder(
      animation: _wiggleController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.rotate(
            angle: _tiltAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Floating Sparkle / Heart / Paw
                Positioned(
                  top: -16 + (_bounceAnimation.value * 0.5),
                  right: 12 + (_tailWagAnimation.value * 30),
                  child: const Text('✨', style: TextStyle(fontSize: 22)),
                ),
                Positioned(
                  top: 8,
                  left: -14 - (_tailWagAnimation.value * 20),
                  child: const Text('🐾', style: TextStyle(fontSize: 18)),
                ),

                // Main Mascot Image Container with interactive tap
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                  },
                  child: Container(
                    width: 155,
                    height: 155,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/mascot_dog_peek.png',
                      cacheWidth: 310,
                      cacheHeight: 310,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/mascot_avatar.jpg',
                        cacheWidth: 310,
                        cacheHeight: 310,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.pets,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

