import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';

/// Floating Action Button แบบ Speed Dial สำหรับ Dashboard
/// แสดง 3 รายการ: รับเงิน, จ่ายเงิน, โอนย้าย
/// พร้อมรูปภาพไอคอน 3D Asset เดิม และสไตล์ธีมตูบจด
class DashboardSpeedDial extends StatefulWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;
  final ValueChanged<bool>? onOpenChanged;

  const DashboardSpeedDial({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
    this.onOpenChanged,
  });

  @override
  DashboardSpeedDialState createState() => DashboardSpeedDialState();
}

class DashboardSpeedDialState extends State<DashboardSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool get isOpen => _isOpen;

  late final AnimationController _controller;
  late final Animation<double> _rotateAnimation;

  // Staggered animations ผูกกับ _controller โดยตรง (ป้องกัน Curves [0, 1] assertion error)
  late final Animation<double> _animIncome;
  late final Animation<double> _animExpense;
  late final Animation<double> _animTransfer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // 3 ปุ่มย่อย: รับเงิน, จ่ายเงิน, โอนย้าย
    _animIncome = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 1.0, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.0, 0.84, curve: Curves.easeInCubic),
    );

    _animExpense = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.92, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.08, 0.92, curve: Curves.easeInCubic),
    );

    _animTransfer = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.84, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.16, 1.0, curve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onOpenChanged?.call(_isOpen);
  }

  void close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _controller.reverse();
      widget.onOpenChanged?.call(false);
    }
  }

  void _handleAction(VoidCallback action) {
    close();
    Future.delayed(const Duration(milliseconds: 160), action);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ─── 1. รับเงิน ─────────────────────────────────────────────
        _SpeedDialItem(
          animation: _animIncome,
          label: 'รับเงิน',
          imageAsset: 'assets/images/action_income.png',
          fallbackIcon: Icons.arrow_downward_rounded,
          isDark: isDark,
          onTap: () => _handleAction(widget.onAddIncome),
        ),
        const SizedBox(height: 10),

        // ─── 2. จ่ายเงิน ────────────────────────────────────────────
        _SpeedDialItem(
          animation: _animExpense,
          label: 'จ่ายเงิน',
          imageAsset: 'assets/images/action_expense.png',
          fallbackIcon: Icons.arrow_upward_rounded,
          isDark: isDark,
          onTap: () => _handleAction(widget.onAddExpense),
        ),
        const SizedBox(height: 10),

        // ─── 3. โอนย้าย ─────────────────────────────────────────────
        _SpeedDialItem(
          animation: _animTransfer,
          label: 'โอนย้าย',
          imageAsset: 'assets/images/action_transfer.png',
          fallbackIcon: Icons.swap_horiz_rounded,
          isDark: isDark,
          onTap: () => _handleAction(widget.onTransfer),
        ),
        const SizedBox(height: 14),

        // ─── Main FAB Button ────────────────────────────────────────
        _MainFab(
          rotateAnimation: _rotateAnimation,
          isOpen: _isOpen,
          isDark: isDark,
          onTap: toggle,
        ),
      ],
    );
  }
}

// ─── Speed Dial Item (ป้าย Label สีเข้ม + ปุ่มรูปภาพกลม) ─────────────────────────

class _SpeedDialItem extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final String imageAsset;
  final IconData fallbackIcon;
  final bool isDark;
  final VoidCallback onTap;

  const _SpeedDialItem({
    required this.animation,
    required this.label,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final val = animation.value;
        if (val <= 0.001) return const SizedBox.shrink();

        final opacityVal = val.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacityVal,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - val.clamp(0.0, 1.0))),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── Label Pill (ป้ายสีเข้มตาม Wireframe ตัวอย่าง) ────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF23272F),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: GoogleFonts.prompt(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ─── Circle Image / Action Button ─────────────────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.40),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Image.asset(
                    imageAsset,
                    cacheWidth: 90,
                    cacheHeight: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      fallbackIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main FAB Button (ปุ่มวงกลมสีส้ม ล่างสุด) ──────────────────────────────────

class _MainFab extends StatelessWidget {
  final Animation<double> rotateAnimation;
  final bool isOpen;
  final bool isDark;
  final VoidCallback onTap;

  const _MainFab({
    required this.rotateAnimation,
    required this.isOpen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotateAnimation,
      builder: (context, child) {
        return Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: isOpen ? 0.55 : 0.42),
                blurRadius: isOpen ? 16 : 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('dashboard_speed_dial_main_fab'),
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.25),
              child: Center(
                child: Transform.rotate(
                  angle: rotateAnimation.value * 2 * 3.14159,
                  child: Icon(
                    isOpen ? Icons.close_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


