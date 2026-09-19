import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_colors.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.imageAsset = 'assets/images/mascot_dog_writing.png',
    required this.title,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mascot Image or Icon Container
            if (imageAsset != null)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    imageAsset!,
                    cacheWidth: 280,
                    cacheHeight: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon ?? Icons.inbox,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.inbox,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 18),

            // Speech Bubble / Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : const Color(0xFF92400E),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    if (onAction != null) {
      return GestureDetector(
        onTap: onAction,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
