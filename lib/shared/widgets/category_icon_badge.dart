import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../core/utils/icon_helper.dart';

class CategoryIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final String? categoryId;
  final String? assetPath;

  const CategoryIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 22,
    this.categoryId,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedAsset = assetPath ?? IconHelper.getCategoryAsset(categoryId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.30 : 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: resolvedAsset != null
            ? Image.asset(
                resolvedAsset,
                width: size * 0.90,
                height: size * 0.90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              )
            : Icon(
                icon,
                color: color,
                size: iconSize,
              ),
      ),
    );
  }
}
