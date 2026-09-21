import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../auto_sync/domain/entities/bank_profile.dart';
import '../../../auto_sync/presentation/widgets/bank_logo_badge.dart';
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

    final accState = context.watch<AccountCubit>().state;

    final isTransfer = transaction.isTransfer;
    final isIncomingTransfer = isTransfer &&
        activeBankId != null &&
        (transaction.targetAccountId == activeBankId ||
            accState.accounts.any((a) =>
                (a.bankId == activeBankId || a.id == activeBankId) &&
                (a.id == transaction.targetAccountId || a.bankId == transaction.targetAccountId)));
    final isOutgoingTransfer = isTransfer &&
        activeBankId != null &&
        (transaction.bankAccountId == activeBankId ||
            transaction.bankId == activeBankId ||
            accState.accounts.any((a) =>
                (a.bankId == activeBankId || a.id == activeBankId) &&
                (a.id == transaction.bankAccountId || a.bankId == transaction.bankId)));

    // Resolve bank names for display
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
      final targetAcc = accState.accounts
          .where((a) => a.id == transaction.targetAccountId || a.bankId == transaction.targetAccountId)
          .toList();
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

    // Check if category is "Other" / Uncategorized and has bank info to show Bank Logo
    final isOtherCategory = transaction.isUnknownCategory ||
        transaction.categoryId == 'other' ||
        transaction.categoryId == 'other_income';

    String? resolvedBankId = transaction.bankId;
    if (resolvedBankId == null && transaction.bankAccountId != null) {
      final acc = accState.accounts.where((a) => a.id == transaction.bankAccountId).toList();
      if (acc.isNotEmpty) {
        resolvedBankId = acc.first.bankId;
      }
    }

    String? resolvedTargetBankId;
    if (isTransfer && transaction.targetAccountId != null) {
      final targetAcc = accState.accounts
          .where((a) => a.id == transaction.targetAccountId || a.bankId == transaction.targetAccountId)
          .toList();
      if (targetAcc.isNotEmpty) {
        resolvedTargetBankId = targetAcc.first.bankId;
      } else {
        final profile = BankProfile.findById(transaction.targetAccountId!);
        if (profile != null) {
          resolvedTargetBankId = profile.id;
        }
      }
    }

    final hasBankInfo = (resolvedBankId != null && resolvedBankId.isNotEmpty) ||
        (transaction.bankShortName != null && transaction.bankShortName!.isNotEmpty) ||
        (fromBankName.isNotEmpty && fromBankName != 'ต้นทาง');

    final tileContent = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 1. Transfer Transaction -> Show Source Bank ➜ Target Bank Logo Badge
            if (isTransfer)
              _buildTransferBankBadge(
                sourceBankId: resolvedBankId,
                fromBankName: fromBankName,
                targetBankId: resolvedTargetBankId,
                toBankName: toBankName,
                isDark: isDark,
              )
            // 2. "Other" category with bank info -> Show Bank Logo Badge
            else if (isOtherCategory && hasBankInfo)
              BankLogoBadge(
                bankId: resolvedBankId,
                fallbackShortName: fromBankName.isNotEmpty && fromBankName != 'ต้นทาง'
                    ? fromBankName
                    : transaction.bankShortName,
                size: 42,
                borderRadius: 12,
              )
            // 3. Regular category -> Show 3D Category Image Badge
            else
              CategoryIconBadge(
                categoryId: transaction.categoryId,
                icon: IconHelper.getSmartIcon(
                  categoryName: transaction.categoryName,
                  title: transaction.title,
                  code: transaction.categoryIconCode,
                ),
                color: Color(transaction.categoryColorValue),
                size: 42,
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

  Widget _buildTransferBankBadge({
    required String? sourceBankId,
    required String fromBankName,
    required String? targetBankId,
    required String toBankName,
    required bool isDark,
  }) {
    final validFromName = fromBankName.isNotEmpty && fromBankName != 'ต้นทาง' ? fromBankName : null;
    final validToName = toBankName.isNotEmpty && toBankName != 'ปลายทาง' ? toBankName : null;

    // 1. If both source and target bank info are available, show dual overlapping badge
    if ((sourceBankId != null || validFromName != null) && (targetBankId != null || validToName != null)) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Source Bank Badge (Top-Left)
            Positioned(
              left: 0,
              top: 0,
              child: BankLogoBadge(
                bankId: sourceBankId,
                fallbackShortName: validFromName,
                size: 26,
                borderRadius: 8,
              ),
            ),
            // Target Bank Badge (Bottom-Right)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    width: 2,
                  ),
                ),
                child: BankLogoBadge(
                  bankId: targetBankId,
                  fallbackShortName: validToName,
                  size: 26,
                  borderRadius: 8,
                ),
              ),
            ),
            // Transfer Mini Arrow (Center)
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 7.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. If only one bank is known, show single bank logo
    if (sourceBankId != null || validFromName != null) {
      return BankLogoBadge(
        bankId: sourceBankId,
        fallbackShortName: validFromName,
        size: 42,
        borderRadius: 12,
      );
    }
    if (targetBankId != null || validToName != null) {
      return BankLogoBadge(
        bankId: targetBankId,
        fallbackShortName: validToName,
        size: 42,
        borderRadius: 12,
      );
    }

    // 3. Default transfer icon badge
    return CategoryIconBadge(
      categoryId: 'transfer',
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF6366F1),
      size: 42,
      iconSize: 20,
    );
  }
}
