import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final bool isEyeViewHidden;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.isEyeViewHidden = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final isTransfer = transaction.isTransfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final smartIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : IconHelper.getSmartIcon(
            categoryName: transaction.categoryName,
            title: transaction.title,
            code: transaction.categoryIconCode,
          );

    final categoryColor = isTransfer
        ? const Color(0xFF6366F1)
        : Color(transaction.categoryColorValue != 0
            ? transaction.categoryColorValue
            : (isIncome ? 0xFF10B981 : 0xFFEF4444));

    final bankBadge = transaction.bankShortName ?? _extractBankBadge(transaction.note);
    final bankColor = _getBankColor(transaction.bankId, bankBadge);

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ลบ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.06),
            highlightColor: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CategoryIconBadge(
                    icon: smartIcon,
                    color: categoryColor,
                    size: 48,
                    iconSize: 24,
                    categoryId: transaction.categoryId,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Category Tag
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isTransfer ? 'โอนข้ามบัญชี' : transaction.categoryName,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Bank Tag Badge
                            if (bankBadge != null) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bankColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: bankColor.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  bankBadge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: bankColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            // Note snippet
                            if (transaction.note != null &&
                                transaction.note!.isNotEmpty &&
                                !transaction.note!.startsWith('ตรวจจับอัตโนมัติจาก')) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  transaction.note!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(isIncome, isTransfer),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isTransfer
                              ? const Color(0xFF6366F1)
                              : (isIncome ? AppColors.income : AppColors.expense),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormatter.formatTime(transaction.date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(bool isIncome, bool isTransfer) {
    if (isTransfer) {
      return CurrencyFormatter.format(transaction.amount);
    }
    return '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}';
  }

  static Color _getBankColor(String? bankId, String? bankBadge) {
    if (bankId == 'kbank' || (bankBadge?.contains('K') ?? false)) return const Color(0xFF138F2D);
    if (bankId == 'scb' || (bankBadge?.contains('SCB') ?? false)) return const Color(0xFF4E2A84);
    if (bankId == 'ktb' || (bankBadge?.contains('KTB') ?? false)) return const Color(0xFF00A3E0);
    if (bankId == 'truemoney' || (bankBadge?.contains('True') ?? false)) return const Color(0xFFFF5B00);
    if (bankId == 'ttb') return const Color(0xFF0056B3);
    if (bankId == 'kma') return const Color(0xFFFDB913);
    return const Color(0xFF2563EB);
  }

  static String? _extractBankBadge(String? note) {
    if (note == null || note.isEmpty) return null;
    final lower = note.toLowerCase();
    if (lower.contains('k plus') || lower.contains('kbank')) return 'K PLUS';
    if (lower.contains('scb easy') || lower.contains('scb')) return 'SCB EASY';
    if (lower.contains('krungthai') || lower.contains('ktb')) return 'Krungthai';
    if (lower.contains('เป๋าตัง') || lower.contains('paotang')) return 'เป๋าตัง';
    if (lower.contains('truemoney')) return 'TrueMoney';
    if (lower.contains('ttb')) return 'ttb';
    if (lower.contains('kma') || lower.contains('krungsri')) return 'KMA';
    if (lower.contains('bbl') || lower.contains('bangkok bank')) return 'BBL';
    if (lower.contains('mymo')) return 'MyMo';
    if (lower.contains('dime')) return 'Dime!';
    if (lower.contains('make')) return 'MAKE';
    return null;
  }
}
