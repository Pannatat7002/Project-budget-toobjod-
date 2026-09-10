import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/bank_account_entity.dart';

class BankQuickJumpBar extends StatelessWidget {
  final List<BankAccountEntity> accounts;
  final String? selectedBankId; // null = All
  final ValueChanged<String?> onSelectBank;

  const BankQuickJumpBar({
    super.key,
    required this.accounts,
    this.selectedBankId,
    required this.onSelectBank,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 1 + accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedBankId == null;
            return _buildChip(
              context: context,
              label: 'รวมทุกบัญชี',
              icon: Icons.dashboard_rounded,
              color: const Color(0xFFF59E0B),
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => onSelectBank(null),
            );
          }

          final acc = accounts[index - 1];
          final isSelected = selectedBankId == acc.bankId;

          return _buildChip(
            context: context,
            label: acc.shortName,
            icon: Icons.account_balance_rounded,
            color: Color(acc.brandColor),
            logoAsset: acc.bankId != 'cash' ? acc.logoAsset : null,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => onSelectBank(acc.bankId),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    String? logoAsset,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoAsset != null)
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(icon, size: 12, color: color),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(icon, size: 14, color: isSelected ? color : AppColors.darkTextMuted),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : color)
                    : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
