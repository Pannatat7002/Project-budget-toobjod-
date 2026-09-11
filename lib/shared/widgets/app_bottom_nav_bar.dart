import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAiPressed;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onAiPressed,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int? _hoveredIndex;
  bool _isAiHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main Navigation Bar Container
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tab 0: ภาพรวม (Left)
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'ภาพรวม',
                    isDark: isDark,
                  ),

                  // Center Spacer for Floating AI Button
                  const SizedBox(width: 80),

                  // Tab 1: รายการ (Right)
                  _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    selectedIcon: Icons.receipt_long_rounded,
                    label: 'รายการ',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Prominent Floating Center AI Dog Button (Zero overflow)
        Positioned(
          top: -24,
          child: _buildCenterAiButton(isDark),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index && !isSelected;
    final activeColor =
        isDark ? AppColors.primaryLight : AppColors.primaryOrange;
    final inactiveColor = isHovered
        ? (isDark ? Colors.white : const Color(0xFF334155))
        : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B));

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(index),
          onHover: (hovering) {
            setState(() {
              _hoveredIndex = hovering ? index : null;
            });
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : const Color(0xFFFFEDD5))
                      : (isHovered
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05))
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : (isHovered ? FontWeight.w600 : FontWeight.w500),
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAiButton(bool isDark) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isAiHovered = true),
      onExit: (_) => setState(() => _isAiHovered = false),
      child: GestureDetector(
        onTap: widget.onAiPressed,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _isAiHovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A00), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3.2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkCard : Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mascot_ai_dog_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/mascot_ai_dog.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/mascot_avatar.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'AI แนะนำ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
