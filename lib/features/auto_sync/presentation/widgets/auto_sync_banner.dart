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
      // Rebuild only when pending transactions change or permission state changes
      buildWhen: (prev, curr) =>
          prev.pendingTransactions.length != curr.pendingTransactions.length ||
          prev.isPermissionGranted != curr.isPermissionGranted ||
          prev.isAutoSyncEnabled != curr.isAutoSyncEnabled,
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        // Case 1: Has pending detected transactions waiting for user review
        if (state.pendingTransactions.isNotEmpty) {
          final firstTx = state.pendingTransactions.first;
          final count = state.pendingTransactions.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(firstTx.bankColorValue).withAlpha(isDark ? 35 : 20),
                  AppColors.primary.withAlpha(isDark ? 25 : 15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(firstTx.bankColorValue).withAlpha(isDark ? 100 : 120),
                width: 1.2,
              ),
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                NotificationDrawerSheet.show(context);
              },
              child: Row(
                children: [
                  BankLogoBadge(
                    packageName: firstTx.packageName,
                    fallbackShortName: firstTx.bankShortName,
                    fallbackColorValue: firstTx.bankColorValue,
                    size: 38,
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
                                'ตรวจพบรายการจาก ${firstTx.bankShortName}',
                                style: GoogleFonts.prompt(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
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
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+$count',
                                  style: GoogleFonts.prompt(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${firstTx.isIncome ? 'รับเงิน' : 'ชำระ'} ${CurrencyFormatter.format(firstTx.amount)} - แตะเพื่อบันทึก 🐾',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: subtextColor,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          );
        }

        // Case 2: Permission not granted and Auto-sync is enabled -> Offer setup banner
        if (state.isAutoSyncEnabled && !state.isPermissionGranted) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(isDark ? 70 : 80),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 45 : 35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ระบบจดบันทึกอัตโนมัติ 🐾',
                        style: GoogleFonts.prompt(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ตรวจจับเงินเข้า-ออกจากแอปธนาคารอัตโนมัติ',
                        style: GoogleFonts.prompt(
                          fontSize: 11.5,
                          color: subtextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/notification-permission');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'เปิดสิทธิ์',
                    style: GoogleFonts.prompt(
                      fontSize: 12,
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
