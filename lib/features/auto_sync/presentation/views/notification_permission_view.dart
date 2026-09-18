import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';

class NotificationPermissionView extends StatefulWidget {
  const NotificationPermissionView({super.key});

  @override
  State<NotificationPermissionView> createState() =>
      _NotificationPermissionViewState();
}

class _NotificationPermissionViewState extends State<NotificationPermissionView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AutoSyncCubit>().checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check when returning from Android settings
      context.read<AutoSyncCubit>().checkPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocConsumer<AutoSyncCubit, AutoSyncState>(
      listenWhen: (prev, curr) =>
          prev.isPermissionGranted != curr.isPermissionGranted,
      listener: (context, state) {
        if (state.isPermissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'เปิดสิทธิ์การแจ้งเตือนเรียบร้อยแล้ว 🎉',
                    style: GoogleFonts.prompt(fontSize: 13.5),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ปิดสิทธิ์การแจ้งเตือนแล้ว ⏳',
                    style: GoogleFonts.prompt(fontSize: 13.5),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AutoSyncCubit>();
        final isGranted = state.isPermissionGranted;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'สิทธิ์การเข้าถึงแจ้งเตือน',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: textColor,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Icon Circle with Accent Glow
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: (isGranted
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withAlpha(isDark ? 40 : 25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isGranted
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withAlpha(isDark ? 90 : 120),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isGranted
                                        ? AppColors.success
                                        : AppColors.primary)
                                    .withAlpha(isDark ? 30 : 15),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            isGranted
                                ? Icons.check_circle_rounded
                                : Icons.notifications_active_rounded,
                            color: isGranted
                                ? AppColors.success
                                : AppColors.primary,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Status Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (isGranted
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withAlpha(isDark ? 35 : 20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isGranted
                                      ? AppColors.success
                                      : AppColors.primary)
                                  .withAlpha(isDark ? 90 : 120),
                            ),
                          ),
                          child: Text(
                            isGranted
                                ? 'สถานะ: เปิดใช้งานแล้ว ✅'
                                : 'สถานะ: รอการเปิดสิทธิ์ ⏳',
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isGranted
                                  ? (isDark
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF047857))
                                  : (isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryDark),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          isGranted
                              ? 'เปิดสิทธิ์การเข้าถึงเรียบร้อยแล้ว'
                              : 'จำเป็นต้องเปิดสิทธิ์ Notification Access',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          isGranted
                              ? 'ระบบพร้อมตรวจจับและบันทึกยอดเงินจากแอปธนาคารให้อัตโนมัติ หากต้องการยกเลิกหรือปิดสิทธิ์ สามารถกดปิดได้ที่ปุ่มด้านล่าง'
                              : 'เพื่อให้ "เจ้าตูบจด" สามารถตรวจจับและบันทึกยอดเงินเข้า-ออก จากแอปธนาคารได้ทันที โดยไม่ต้องพิมพ์เอง',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 13.5,
                            color: subtextColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!isGranted) ...[
                          // Simple Steps Guide Card when waiting for permission
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ขั้นตอนการเปิดสิทธิ์',
                                  style: GoogleFonts.prompt(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStepRow(
                                  step: '1',
                                  title: 'กดปุ่ม "ไปหน้าตั้งค่า Android"',
                                  desc:
                                      'ระบบจะเปิดหน้าตั้งค่าการเข้าถึงการแจ้งเตือน',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                                const SizedBox(height: 14),
                                _buildStepRow(
                                  step: '2',
                                  title: 'ค้นหาและเลือกแอป "เจ้าตูบจด"',
                                  desc: 'มองหาไอคอนเจ้าตูบจดในรายการแอป',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                                const SizedBox(height: 14),
                                _buildStepRow(
                                  step: '3',
                                  title: 'เลื่อนเปิดสวิตช์ "อนุญาต"',
                                  desc:
                                      'กดยืนยันเพื่อให้ระบบเริ่มทำงานอัตโนมัติ',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Quick in-app pause toggle card when granted
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (state.isAutoSyncEnabled
                                            ? AppColors.success
                                            : subtextColor)
                                        .withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    state.isAutoSyncEnabled
                                        ? Icons.sync_rounded
                                        : Icons.sync_disabled_rounded,
                                    color: state.isAutoSyncEnabled
                                        ? AppColors.success
                                        : subtextColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ตรวจจับแจ้งเตือนอัตโนมัติ',
                                        style: GoogleFonts.prompt(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.isAutoSyncEnabled
                                            ? 'กำลังเปิดทำงานตรวจจับในแอป'
                                            : 'ปิดการตรวจจับชั่วคราวในแอป',
                                        style: GoogleFonts.prompt(
                                          fontSize: 12,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: state.isAutoSyncEnabled,
                                  activeTrackColor: AppColors.success,
                                  onChanged: (val) =>
                                      cubit.toggleAutoSync(val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    MediaQuery.of(context).padding.bottom + 14,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGranted) ...[
                        // Button when granted: Turn off permission in Android settings
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => cubit.openNotificationSettings(),
                            icon: const Icon(
                              Icons.power_settings_new_rounded,
                              size: 20,
                            ),
                            label: Text(
                              'ไปหน้าตั้งค่า Android (เพื่อปิดสิทธิ์) ⚙️',
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Button when NOT granted: Open settings to grant permission
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => cubit.openNotificationSettings(),
                            icon: const Icon(
                              Icons.settings_suggest_rounded,
                              size: 20,
                            ),
                            label: Text(
                              'ไปหน้าตั้งค่า Android (เปิดสิทธิ์) ⚙️',
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: TextButton.icon(
                          onPressed: () => cubit.checkPermission(),
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: subtextColor,
                          ),
                          label: Text(
                            'ตรวจสอบสถานะสิทธิ์อีกครั้ง 🔄',
                            style: GoogleFonts.prompt(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subtextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String desc,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withAlpha(80),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: GoogleFonts.prompt(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.prompt(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: subtextColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
