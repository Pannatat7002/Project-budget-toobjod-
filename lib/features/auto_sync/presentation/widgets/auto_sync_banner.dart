import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import 'bank_logo_badge.dart';
import 'notification_drawer_sheet.dart';

class AutoSyncBanner extends StatelessWidget {
  const AutoSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoSyncCubit, AutoSyncState>(
      buildWhen: (prev, curr) =>
          prev.pendingTransactions != curr.pendingTransactions ||
          prev.dismissedBannerTransactionIds != curr.dismissedBannerTransactionIds ||
          prev.isDashboardBannerDismissed != curr.isDashboardBannerDismissed ||
          prev.isPermissionGranted != curr.isPermissionGranted ||
          prev.isAutoSyncEnabled != curr.isAutoSyncEnabled,
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        final unDismissedPending = state.unDismissedPendingTransactions;

        // ════════════════════════════════════════════════════════════════════════════
        // Case 1: Dog Sniffed Transaction(s) - เจ้าตูบดมกลิ่นพบรายการใหม่!
        // ════════════════════════════════════════════════════════════════════════════
        if (unDismissedPending.isNotEmpty) {
          final firstTx = unDismissedPending.first;
          final count = unDismissedPending.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(firstTx.bankColorValue).withAlpha(isDark ? 45 : 28),
                  const Color(0xFF10B981).withAlpha(isDark ? 30 : 18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(firstTx.bankColorValue).withAlpha(isDark ? 110 : 140),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(firstTx.bankColorValue).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      NotificationDrawerSheet.show(context);
                    },
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            BankLogoBadge(
                              packageName: firstTx.packageName,
                              fallbackShortName: firstTx.bankShortName,
                              fallbackColorValue: firstTx.bankColorValue,
                              size: 38,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('🐾', style: TextStyle(fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '🐾 ตูบดมกลิ่นพบรายการจาก ${firstTx.bankShortName}',
                                      style: GoogleFonts.prompt(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (count > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+$count',
                                        style: GoogleFonts.prompt(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${firstTx.isIncome ? '🦴 ได้เงินเข้า' : '💸 จ่ายออก'} ${CurrencyFormatter.format(firstTx.amount)} • ตูบจดแล้ว (แตะดู)',
                                style: GoogleFonts.prompt(
                                  fontSize: 11.5,
                                  color: subtextColor,
                                  height: 1.35,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'ปิดการแจ้งเตือนบนแดชบอร์ด',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<AutoSyncCubit>().dismissDashboardBanner();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withAlpha(isDark ? 30 : 15),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ════════════════════════════════════════════════════════════════════════════
        // Case 2: Permission not granted -> Sleeping Puppy Status (เจ้าตูบแอบงีบอยู่)
        // ════════════════════════════════════════════════════════════════════════════
        if (!state.isPermissionGranted) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(isDark ? 28 : 16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withAlpha(isDark ? 70 : 90),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(isDark ? 45 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '💤',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เจ้าตูบยังแอบงีบอยู่โฮ่ง 🐾',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'เปิดหูให้เจ้าตูบช่วยอ่านแจ้งเตือนเงินเข้าออกอัตโนมัติ',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: subtextColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/notification-permission');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'เปิดหูให้ตูบ',
                    style: GoogleFonts.prompt(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

