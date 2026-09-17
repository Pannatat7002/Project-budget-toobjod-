import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import 'notification_drawer_sheet.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AutoSyncCubit, AutoSyncState>(
      // Only rebuild when pending notification count changes
      buildWhen: (prev, curr) =>
          prev.pendingTransactions.length != curr.pendingTransactions.length,
      builder: (context, state) {
        final count = state.pendingTransactions.length;
        final hasNotifications = count > 0;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                hasNotifications
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                size: 22,
                color: hasNotifications
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
              tooltip: 'การแจ้งเตือนรายการเงิน (${count > 0 ? '$count รายการ' : 'ไม่มีรายการค้าง'})',
              onPressed: () => NotificationDrawerSheet.show(context),
            ),

            // Red / Orange Notification Badge
            if (hasNotifications)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: AppColors.expense,
                      shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: count > 9 ? BorderRadius.circular(8) : null,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.expense.withAlpha(90),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
