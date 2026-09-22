import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../views/swipe_history_view.dart';
import 'bank_logo_badge.dart';

class NotificationDrawerSheet extends StatefulWidget {
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
  State<NotificationDrawerSheet> createState() =>
      _NotificationDrawerSheetState();
}

class _NotificationDrawerSheetState extends State<NotificationDrawerSheet>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late final AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    // Auto-refresh missed notifications when drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleRefresh(isAutoTrigger: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh({bool isAutoTrigger = false}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshAnimController.repeat();
    if (!isAutoTrigger) {
      HapticFeedback.lightImpact();
    }

    try {
      final cubit = context.read<AutoSyncCubit>();
      final count = await cubit.manualSyncMissedNotifications();

      if (!mounted) return;

      if (count == -1) {
        if (!isAutoTrigger) {
          TopToast.show(
            context,
            message: '⚠️ กรุณาเปิดสิทธิ์การอ่านการแจ้งเตือนก่อน',
            isSuccess: false,
          );
        }
      } else if (count > 0) {
        HapticFeedback.mediumImpact();
        TopToast.show(
          context,
          message: '🎉 ดึงรายการตกหล่นสำเร็จ $count รายการ',
          isSuccess: true,
        );
      } else if (!isAutoTrigger) {
        TopToast.show(
          context,
          message: '🐾 ไม่พบการแจ้งเตือนตกหล่นเพิ่มเติม',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!isAutoTrigger) {
        TopToast.show(
          context,
          message: '❌ ไม่สามารถดึงแจ้งเตือนได้: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        _refreshAnimController.stop();
        _refreshAnimController.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocListener<AutoSyncCubit, AutoSyncState>(
      listenWhen: (previous, current) =>
          !_isRefreshing &&
          previous.pendingTransactions.isNotEmpty &&
          current.pendingTransactions.isEmpty,
      listener: (context, state) {
        // Automatically close the sheet when all items are cleared
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<AutoSyncCubit, AutoSyncState>(
        builder: (context, state) {
          final list = state.pendingTransactions;
          final isEmpty = list.isEmpty;
          final count = list.length;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 15),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
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

                    // Header Row: Title, Counter, History Button, and Close Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(
                                isDark ? 35 : 20,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'รายการตรวจพบ',
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.prompt(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // ปุ่มดึงแจ้งเตือนที่ตกหล่น (Manual Refresh)
                          // IconButton(
                          //   onPressed: _isRefreshing ? null : _handleRefresh,
                          //   tooltip: 'ดึงแจ้งเตือนที่ตกหล่น',
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(
                          //     minWidth: 32,
                          //     minHeight: 32,
                          //   ),
                          //   icon: RotationTransition(
                          //     turns: _refreshAnimController,
                          //     child: Icon(
                          //       Icons.refresh_rounded,
                          //       size: 21,
                          //       color: _isRefreshing
                          //           ? AppColors.primary
                          //           : AppColors.primary,
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(width: 2),
                          // ปุ่มไปที่หน้าประวัติการตรวจจับ
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/swipe-history');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              state.swipeHistory.isEmpty
                                  ? 'ประวัติ'
                                  : 'ประวัติ (${state.swipeHistory.length})',
                              style: GoogleFonts.prompt(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: subtextColor,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gesture Helper Guide (Visual Indicator for One-Handed Use)
                    if (!isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // const Icon(
                            //   Icons.check_circle_rounded,
                            //   size: 13,
                            //   color: AppColors.income,
                            // ),
                            // const SizedBox(width: 5),
                            // Text(
                            //   'บันทึกลงระบบแล้วอัตโนมัติ',
                            //   style: GoogleFonts.prompt(
                            //     fontSize: 11.5,
                            //     fontWeight: FontWeight.w600,
                            //     color: AppColors.income,
                            //   ),
                            // ),
                            // const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: subtextColor.withAlpha(120),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_back_rounded,
                              size: 13,
                              color: AppColors.expense,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ปัดซ้ายเพื่อลบออกหากไม่ถูกต้อง',
                              style: GoogleFonts.prompt(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Divider(height: 1, color: borderColor),

                    // Content List: shrinkWrap & Flexible to show height based on items
                    if (isEmpty)
                      Flexible(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkCard
                              : Colors.white,
                          onRefresh: _handleRefresh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(
                                        isDark ? 35 : 20,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      size: 30,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'ยังไม่มีรายการตรวจพบ',
                                    style: GoogleFonts.prompt(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'หากมีแจ้งเตือนธนาคารเข้าแต่ยังไม่ตรวจพบ\nสามารถกดปุ่มด้านล่างเพื่อดึงแจ้งเตือนที่ตกหล่นได้ทันที',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.prompt(
                                      fontSize: 12.5,
                                      color: subtextColor,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: _isRefreshing
                                        ? null
                                        : _handleRefresh,
                                    icon: _isRefreshing
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.sync_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isRefreshing
                                          ? 'กำลังดึงข้อมูล...'
                                          : 'ดึงข้อมูลใหม่',
                                      style: GoogleFonts.prompt(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkCard
                              : Colors.white,
                          onRefresh: _handleRefresh,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
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
                                  context
                                      .read<AutoSyncCubit>()
                                      .confirmTransaction(
                                        item,
                                        customEntity: customEntity,
                                      );
                                },
                                onDiscard: () {
                                  context
                                      .read<AutoSyncCubit>()
                                      .discardTransaction(item);
                                },
                              );
                            },
                          ),
                        ),
                      ),

                    // Bottom Thumb Quick Action Bar (for One-Handed Bulk Action)
                    if (list.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightBackground,
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                context
                                    .read<AutoSyncCubit>()
                                    .discardAllPending();
                                TopToast.show(
                                  context,
                                  message: '🗑️ ลบรายการทั้งหมดออกจากระบบแล้ว',
                                  isSuccess: false,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_sweep_rounded,
                                size: 16,
                                color: AppColors.expense,
                              ),
                              label: Text(
                                'ลบทั้งหมดออกจากระบบ',
                                style: GoogleFonts.prompt(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.expense,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                context.read<AutoSyncCubit>().clearAllPending();
                                TopToast.show(
                                  context,
                                  message:
                                      '✨ เคลียร์รายการตรวจพบแล้ว (ข้อมูลบันทึกในระบบแล้ว)',
                                  isSuccess: true,
                                );
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'รับทราบทั้งหมด',
                                style: GoogleFonts.prompt(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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
  State<_DismissibleNotificationCard> createState() =>
      _DismissibleNotificationCardState();
}

class _DismissibleNotificationCardState
    extends State<_DismissibleNotificationCard> {
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
                        _triggerConfirm();
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(cat.colorValue)
                              : (widget.isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightBorderSubtle),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Color(cat.colorValue)
                                : widget.borderColor,
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
                              cacheWidth: 48,
                              cacheHeight: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                cat.icon,
                                size: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Color(cat.colorValue),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : widget.textColor,
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
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.25},
      // Swipe Left -> Discard / Delete (Red)
      background: Container(
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
              'ลบออกจากระบบ',
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
      onDismissed: (_) {
        widget.onDiscard();
        TopToast.show(
          context,
          message: '🗑️ ลบ "${tx.title}" ออกจากระบบแล้ว',
          isSuccess: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.borderColor, width: 0.8),
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
                                IconHelper.getCategoryAsset(
                                      _categoryId,
                                      categoryName: _categoryName,
                                      title: tx.title,
                                    ) ??
                                    'assets/images/categories/cat_other.png',
                                width: 14,
                                height: 14,
                                cacheWidth: 42,
                                cacheHeight: 42,
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
                              Icon(
                                Icons.arrow_drop_down,
                                size: 12,
                                color: widget.subtextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.subtextColor.withAlpha(120),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          DateFormatter.formatRelativeWithTime(tx.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.subtextColor,
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
