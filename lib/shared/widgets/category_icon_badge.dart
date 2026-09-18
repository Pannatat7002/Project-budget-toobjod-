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
  final bool isBankLogo;

  const CategoryIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 22,
    this.categoryId,
    this.assetPath,
    this.isBankLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedAsset = assetPath ?? IconHelper.getCategoryAsset(categoryId);
    final isBank = isBankLogo || (resolvedAsset != null && resolvedAsset.contains('/banks/'));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.20),
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
            ? (isBank
                ? Padding(
                    padding: EdgeInsets.all(size * 0.08),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size * 0.22),
                      child: Image.asset(
                        resolvedAsset,
                        width: size * 0.84,
                        height: size * 0.84,
                        cacheWidth: (size * 3).round(),
                        cacheHeight: (size * 3).round(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          icon,
                          color: color,
                          size: iconSize,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    resolvedAsset,
                    width: size * 0.90,
                    height: size * 0.90,
                    cacheWidth: (size * 3).round(),
                    cacheHeight: (size * 3).round(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      icon,
                      color: color,
                      size: iconSize,
                    ),
                  ))
            : Icon(
                icon,
                color: color,
                size: iconSize,
              ),
      ),
    );
  }
}
