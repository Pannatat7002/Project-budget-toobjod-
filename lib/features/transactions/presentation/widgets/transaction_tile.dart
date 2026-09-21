import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final bool isGrouped;
  final bool showDivider;
  final VoidCallback? onTap;
  final Future<bool> Function()? confirmDelete;
  final VoidCallback? onDelete;
  final String? currentBankId;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.isGrouped = false,
    this.showDivider = true,
    this.onTap,
    this.confirmDelete,
    this.onDelete,
    this.currentBankId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,##0.00', 'th_TH');

    // Determine current bank context if viewing a specific bank
    final activeBankId = currentBankId ??
        context.watch<TransactionCubit>().state.selectedBankId ??
        context.watch<AccountCubit>().state.selectedBankId;

    final isTransfer = transaction.isTransfer;
    final isIncomingTransfer =
        isTransfer && activeBankId != null && transaction.targetAccountId == activeBankId;
    final isOutgoingTransfer = isTransfer &&
        activeBankId != null &&
        (transaction.bankAccountId == activeBankId || transaction.bankId == activeBankId);

    // Resolve bank names for display
    final accState = context.watch<AccountCubit>().state;
    String fromBankName = transaction.bankShortName ?? '';
    if (fromBankName.isEmpty && transaction.bankAccountId != null) {
      final acc = accState.accounts.where((a) => a.id == transaction.bankAccountId).toList();
      if (acc.isNotEmpty) {
        fromBankName = acc.first.shortName;
      }
    }
    if (fromBankName.isEmpty && transaction.bankId != null) {
      final profile = BankProfile.findById(transaction.bankId!);
      if (profile != null) fromBankName = profile.shortName;
    }
    if (fromBankName.isEmpty) fromBankName = 'ต้นทาง';

    String toBankName = '';
    if (isTransfer && transaction.targetAccountId != null) {
      final targetAcc =
          accState.accounts.where((a) => a.id == transaction.targetAccountId).toList();
      if (targetAcc.isNotEmpty) {
        toBankName = targetAcc.first.shortName;
      } else {
        final profile = BankProfile.findById(transaction.targetAccountId!);
        toBankName = profile?.shortName ?? transaction.targetAccountId!;
      }
    }
    if (toBankName.isEmpty) toBankName = 'ปลายทาง';

    // Amount text and color
    String amountPrefix = '';
    Color amountColor;
    if (isTransfer) {
      if (isIncomingTransfer) {
        amountPrefix = '+ ';
        amountColor = AppColors.income;
      } else if (isOutgoingTransfer) {
        amountPrefix = '- ';
        amountColor = AppColors.expense;
      } else {
        amountPrefix = '';
        amountColor = const Color(0xFF6366F1);
      }
    } else if (transaction.isIncome) {
      amountPrefix = '+ ';
      amountColor = AppColors.income;
    } else {
      amountPrefix = '- ';
      amountColor = AppColors.expense;
    }

    // Subtitle logic
    String subtitleText;
    if (isTransfer) {
      if (isIncomingTransfer) {
        subtitleText = 'โอนเข้าจาก $fromBankName';
      } else if (isOutgoingTransfer) {
        subtitleText = 'โอนออกไปยัง $toBankName';
      } else {
        subtitleText = '$fromBankName ➜ $toBankName';
      }
    } else {
      final bankInfo = fromBankName.isNotEmpty ? fromBankName : '';
      final maskInfo = transaction.accountMask != null ? ' • ${transaction.accountMask}' : '';
      subtitleText = '$bankInfo$maskInfo';
    }

    final tileContent = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category Icon Badge
            CategoryIconBadge(
              icon: IconData(transaction.categoryIconCode, fontFamily: 'MaterialIcons'),
              color: isTransfer
                  ? const Color(0xFF6366F1)
                  : Color(transaction.categoryColorValue),
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: 12),

            // Title & Bank Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction.title.isNotEmpty ? transaction.title : transaction.categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isTransfer) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'โอนย้าย',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          subtitleText,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount
            Text(
              '$amountPrefix฿${currencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: amountColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );

    Widget result = tileContent;

    if (onDelete != null) {
      result = Dismissible(
        key: Key('tx_${transaction.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          if (confirmDelete != null) {
            return await confirmDelete!();
          }
          return true;
        },
        onDismissed: (_) => onDelete!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.expense,
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
        ),
        child: result,
      );
    }

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          result,
          Divider(
            height: 1,
            thickness: 0.7,
            indent: 68,
            endIndent: 16,
            color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFF1F5F9),
          ),
        ],
      );
    }

    return result;
  }
}
