import 'package:flutter/material.dart';
import '../../domain/entities/bank_profile.dart';

class BankLogoBadge extends StatelessWidget {
  final String? packageName;
  final String? bankId;
  final String? fallbackShortName;
  final int? fallbackColorValue;
  final double size;
  final double? borderRadius;
  final bool showBorder;

  const BankLogoBadge({
    super.key,
    this.packageName,
    this.bankId,
    this.fallbackShortName,
    this.fallbackColorValue,
    this.size = 36,
    this.borderRadius,
    this.showBorder = true,
  });

  BankProfile? get _resolvedProfile {
    if (packageName != null && packageName!.isNotEmpty) {
      final found = BankProfile.findByPackage(packageName!);
      if (found != null) return found;
    }
    if (bankId != null && bankId!.isNotEmpty) {
      final found = BankProfile.findById(bankId!);
      if (found != null) return found;
    }
    if (fallbackShortName != null && fallbackShortName!.isNotEmpty) {
      final lower = fallbackShortName!.toLowerCase();
      for (final b in BankProfile.supportedBanks) {
        if (b.shortName.toLowerCase() == lower ||
            b.name.toLowerCase().contains(lower) ||
            b.id.toLowerCase() == lower) {
          return b;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _resolvedProfile;
    final r = borderRadius ?? (size * 0.26);
    final colorVal = profile?.brandColor ?? fallbackColorValue ?? 0xFF64748B;
    final brandColor = Color(colorVal);

    if (profile != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
          border: showBorder
              ? Border.all(
                  color: brandColor.withAlpha(80),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 1),
          child: Image.asset(
            profile.logoAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(brandColor, profile.icon, profile.shortName, r),
          ),
        ),
      );
    }

    return _buildFallback(brandColor, Icons.account_balance_rounded, fallbackShortName ?? '', r);
  }

  Widget _buildFallback(Color brandColor, IconData icon, String label, double r) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brandColor.withAlpha(30),
        borderRadius: BorderRadius.circular(r),
        border: showBorder
            ? Border.all(
                color: brandColor.withAlpha(100),
                width: 1,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: size >= 32 && label.isNotEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: size * 0.45, color: brandColor),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w900,
                    color: brandColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Icon(icon, size: size * 0.55, color: brandColor),
    );
  }
}
