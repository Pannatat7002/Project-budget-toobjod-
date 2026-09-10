import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../../../shared/widgets/top_toast.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import 'bank_logo_badge.dart';
import 'mock_notification_sheet.dart';

class NotificationDrawerSheet extends StatelessWidget {
  const NotificationDrawerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationDrawerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocListener<AutoSyncCubit, AutoSyncState>(
      listenWhen: (previous, current) =>
          previous.pendingTransactions.isNotEmpty && current.pendingTransactions.isEmpty,
      listener: (context, state) {
        // Automatically close the sheet when all items are cleared
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 120 : 30),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtextColor.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              BlocBuilder<AutoSyncCubit, AutoSyncState>(
                builder: (context, state) {
                  final count = state.pendingTransactions.length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'รายการตรวจพบ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
                          tooltip: 'จำลองการแจ้งเตือน (Mock)',
                          onPressed: () {
                            Navigator.pop(context);
                            MockNotificationSheet.show(context);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: subtextColor),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Gesture Helper Guide (Visual Indicator for One-Handed Use)
              BlocBuilder<AutoSyncCubit, AutoSyncState>(
                builder: (context, state) {
                  if (state.pendingTransactions.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Left Action Guide
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 12, color: AppColors.expense),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'ปัดซ้าย: ลบออก',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: subtextColor.withAlpha(60),
                        ),
                        // Right Action Guide
                        Row(
                          children: [
                            const Text(
                              'ปัดขวา: บันทึก',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.income.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.income),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              Divider(height: 1, color: borderColor),

              // Content List
              Expanded(
                child: BlocBuilder<AutoSyncCubit, AutoSyncState>(
                  builder: (context, state) {
                    final list = state.pendingTransactions;

                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.income.withAlpha(25),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.income,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'ตรวจทานครบเรียบร้อยแล้ว 🐾',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ทุกรายการบันทึกลงระบบให้เรียบร้อยแล้วครับ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  MockNotificationSheet.show(context);
                                },
                                icon: const Icon(Icons.bolt_rounded, size: 16),
                                label: const Text('จำลอง Notification ธนาคาร (Mock)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: const Color(0xFF78350F),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _DismissibleNotificationCard(
                          key: ValueKey(item.id),
                          transaction: item,
                          isDark: isDark,
                          borderColor: borderColor,
                          textColor: textColor,
                          subtextColor: subtextColor,
                          onConfirm: (customEntity) {
                            context.read<AutoSyncCubit>().confirmTransaction(
                                  item,
                                  customEntity: customEntity,
                                );
                          },
                          onDiscard: () {
                            context.read<AutoSyncCubit>().discardTransaction(item);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom Thumb Quick Action Bar (for One-Handed Bulk Action)
              BlocBuilder<AutoSyncCubit, AutoSyncState>(
                builder: (context, state) {
                  if (state.pendingTransactions.length > 1) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              context.read<AutoSyncCubit>().discardAllPending();
                              TopToast.show(
                                context,
                                message: '🗑️ ลบรายการค้างตรวจทานทั้งหมดแล้ว',
                                isSuccess: false,
                              );
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.expense),
                            label: const Text(
                              'ลบทั้งหมด',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.expense,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.read<AutoSyncCubit>().confirmAllPending();
                              TopToast.show(
                                context,
                                message: '✅ บันทึกรายการทั้งหมดเรียบร้อย',
                                isSuccess: true,
                              );
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 15, color: AppColors.income),
                            label: const Text(
                              'บันทึกทั้งหมด',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.income,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DismissibleNotificationCard extends StatefulWidget {
  final DetectedTransaction transaction;
  final bool isDark;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Function(TransactionEntity entity) onConfirm;
  final VoidCallback onDiscard;

  const _DismissibleNotificationCard({
    super.key,
    required this.transaction,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.onConfirm,
    required this.onDiscard,
  });

  @override
  State<_DismissibleNotificationCard> createState() => _DismissibleNotificationCardState();
}

class _DismissibleNotificationCardState extends State<_DismissibleNotificationCard> {
  late String _categoryId;
  late String _categoryName;
  late int _categoryIconCode;
  late int _categoryColorValue;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.transaction.suggestedCategoryId;
    _categoryName = widget.transaction.suggestedCategoryName;
    _categoryIconCode = widget.transaction.suggestedCategoryIconCode;
    _categoryColorValue = widget.transaction.suggestedCategoryColorValue;
  }

  void _showCategoryPicker(BuildContext context) {
    final categories = widget.transaction.isIncome
        ? AppConstants.defaultIncomeCategories
        : AppConstants.defaultExpenseCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เลือกหมวดหมู่',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = cat.id == _categoryId;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _categoryId = cat.id;
                          _categoryName = cat.name;
                          _categoryIconCode = cat.iconCode;
                          _categoryColorValue = cat.colorValue;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(cat.colorValue)
                              : (widget.isDark ? AppColors.darkCard : AppColors.lightBorderSubtle),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Color(cat.colorValue) : widget.borderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              cat.imageAsset,
                              width: 16,
                              height: 16,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                cat.icon,
                                size: 13,
                                color: isSelected ? Colors.white : Color(cat.colorValue),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : widget.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerConfirm() {
    final entity = TransactionEntity(
      id: widget.transaction.id,
      title: widget.transaction.title,
      amount: widget.transaction.amount,
      type: widget.transaction.type,
      categoryId: _categoryId,
      categoryName: _categoryName,
      categoryIconCode: _categoryIconCode,
      categoryColorValue: _categoryColorValue,
      date: widget.transaction.timestamp,
      note: widget.transaction.rawText,
      bankId: widget.transaction.bankId,
      bankAccountId: widget.transaction.bankAccountId,
      bankShortName: widget.transaction.bankShortName,
      accountMask: widget.transaction.accountMask,
    );
    widget.onConfirm(entity);
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isIncome = tx.isIncome;
    final typeColor = isIncome ? AppColors.income : AppColors.expense;
    final cardBg = widget.isDark ? AppColors.darkCard : AppColors.lightCard;

    return Dismissible(
      key: Key('notif_card_${tx.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.25,
        DismissDirection.endToStart: 0.25,
      },
      // Swipe Right -> Confirm / Save (Green)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.income,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'ยืนยันบันทึก',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      // Swipe Left -> Discard / Delete (Red)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'ไม่ถูกต้อง (ลบ)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Swiped Right -> Confirm
          _triggerConfirm();
          TopToast.show(
            context,
            message: '✅ บันทึก "${tx.title}" เรียบร้อย',
            isSuccess: true,
          );
        } else {
          // Swiped Left -> Discard
          widget.onDiscard();
          TopToast.show(
            context,
            message: '🗑️ ลบ "${tx.title}" แล้ว',
            isSuccess: false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(widget.isDark ? 25 : 8),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bank Logo Badge
            BankLogoBadge(
              packageName: tx.packageName,
              fallbackShortName: tx.bankShortName,
              fallbackColorValue: tx.bankColorValue,
              size: 40,
            ),
            const SizedBox(width: 10),

            // Title & Details (text) & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tx.rawText != null && tx.rawText!.isNotEmpty) ...[
                    const SizedBox(height: 1.5),
                    Text(
                      tx.rawText!,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: widget.subtextColor.withAlpha(200),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Category Tag (Tap to change)
                      Flexible(
                        child: InkWell(
                          onTap: () => _showCategoryPicker(context),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                IconHelper.getCategoryAsset(_categoryId) ?? '',
                                width: 14,
                                height: 14,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  IconHelper.getSmartIcon(
                                    categoryName: _categoryName,
                                    title: tx.title,
                                    code: _categoryIconCode,
                                  ),
                                  size: 12,
                                  color: Color(_categoryColorValue),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _categoryName,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(_categoryColorValue),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, size: 12, color: widget.subtextColor),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('•', style: TextStyle(fontSize: 9, color: widget.subtextColor.withAlpha(120))),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatRelativeWithTime(tx.timestamp),
                        style: TextStyle(fontSize: 10, color: widget.subtextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount Only (Clean gesture-driven design without check/cross buttons)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 14,
                  color: widget.subtextColor.withAlpha(80),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
