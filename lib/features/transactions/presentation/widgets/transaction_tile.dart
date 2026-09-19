import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionTile extends StatefulWidget {
  final TransactionEntity transaction;
  final bool isEyeViewHidden;
  final bool isGrouped;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.isEyeViewHidden = false,
    this.isGrouped = false,
    this.showDivider = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.isIncome;
    final isTransfer = widget.transaction.isTransfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawBankBadge = widget.transaction.bankShortName ?? _extractBankBadge(widget.transaction.note);
    final resolvedBank = BankProfile.resolveBank(
      bankId: widget.transaction.bankId,
      bankName: rawBankBadge,
      note: widget.transaction.note,
    );

    final bankBadge = rawBankBadge ?? resolvedBank?.shortName;
    final bool showBankLogo = !isTransfer && widget.transaction.isUnknownCategory && resolvedBank != null;

    final smartIcon = isTransfer
        ? Icons.swap_horiz_rounded
        : (showBankLogo
            ? resolvedBank.icon
            : IconHelper.getSmartIcon(
                categoryName: widget.transaction.categoryName,
                title: widget.transaction.title,
                code: widget.transaction.categoryIconCode,
              ));

    final categoryColor = isTransfer
        ? const Color(0xFF6366F1)
        : (showBankLogo
            ? Color(resolvedBank.brandColor)
            : Color(widget.transaction.categoryColorValue != 0
                ? widget.transaction.categoryColorValue
                : (isIncome ? 0xFF10B981 : 0xFFEF4444)));


    final subtitleItems = <String>[];
    if (isTransfer) {
      subtitleItems.add('โอนข้ามบัญชี');
    } else if (widget.transaction.title.trim() != widget.transaction.categoryName.trim()) {
      subtitleItems.add(widget.transaction.categoryName);
    }

    if (bankBadge != null && bankBadge.isNotEmpty) {
      subtitleItems.add(bankBadge);
    }

    final hasNote = widget.transaction.note != null &&
        widget.transaction.note!.isNotEmpty &&
        !widget.transaction.note!.startsWith('ตรวจจับอัตโนมัติจาก');
    if (hasNote) {
      subtitleItems.add(widget.transaction.note!);
    }

    if (subtitleItems.isEmpty) {
      subtitleItems.add(widget.transaction.categoryName);
    }

    final subtitleText = subtitleItems.join(' • ');

    final rowContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isGrouped ? 16 : 14,
        vertical: widget.isGrouped ? 11 : 12,
      ),
      child: Row(
        children: [
          CategoryIconBadge(
            icon: smartIcon,
            color: categoryColor,
            size: widget.isGrouped ? 40 : 48,
            iconSize: widget.isGrouped ? 20 : 24,
            categoryId: showBankLogo ? null : widget.transaction.categoryId,
            assetPath: showBankLogo ? resolvedBank.logoAsset : null,
            isBankLogo: showBankLogo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.transaction.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: widget.isGrouped ? 14 : 14.5,
                        letterSpacing: -0.2,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatAmount(isIncome, isTransfer),
                style: TextStyle(
                  fontSize: widget.isGrouped ? 14.5 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isTransfer
                      ? const Color(0xFF6366F1)
                      : (isIncome ? AppColors.income : AppColors.expense),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatTime(widget.transaction.date),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final interactiveRow = Material(
      color: Colors.transparent,
      borderRadius: widget.isGrouped ? null : BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap?.call();
              }
            : null,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        borderRadius: widget.isGrouped ? null : BorderRadius.circular(16),
        splashColor: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.06),
        highlightColor: (isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.03),
        child: rowContent,
      ),
    );

    final Widget coreTile;
    if (widget.isGrouped) {
      coreTile = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          interactiveRow,
          if (widget.showDivider)
            Divider(
              height: 1,
              thickness: 0.6,
              indent: 68,
              endIndent: 0,
              color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFF1F5F9),
            ),
        ],
      );
    } else {
      coreTile = Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
            width: 1,
          ),
        ),
        child: interactiveRow,
      );
    }

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Dismissible(
        key: Key('tx_${widget.transaction.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          HapticFeedback.mediumImpact();
          widget.onDelete?.call();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          margin: EdgeInsets.only(bottom: widget.isGrouped ? 0 : 8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.9),
            borderRadius: widget.isGrouped ? null : BorderRadius.circular(16),
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
        child: coreTile,
      ),
    );
  }

  String _formatAmount(bool isIncome, bool isTransfer) {
    if (isTransfer) {
      return CurrencyFormatter.format(widget.transaction.amount);
    }
    return '${isIncome ? '+' : '-'}${CurrencyFormatter.format(widget.transaction.amount)}';
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
