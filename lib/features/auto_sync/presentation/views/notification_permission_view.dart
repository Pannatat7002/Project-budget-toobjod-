import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';

class NotificationPermissionView extends StatefulWidget {
  const NotificationPermissionView({super.key});

  @override
  State<NotificationPermissionView> createState() => _NotificationPermissionViewState();
}

class _NotificationPermissionViewState extends State<NotificationPermissionView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check
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
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ขอสิทธิ์การเข้าถึงแจ้งเตือน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AutoSyncCubit, AutoSyncState>(
        builder: (context, state) {
          final cubit = context.read<AutoSyncCubit>();
          final isGranted = state.isPermissionGranted;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    // 1. Hero Mascot & Permission Status Card
                    _buildStatusHero(context, isGranted, isDark, textColor, subtextColor),
                    const SizedBox(height: 20),

                    // 2. Step-by-Step Guide
                    _buildStepsGuide(context, isDark, cardColor, textColor, subtextColor, borderColor),
                    const SizedBox(height: 20),

                    // 3. Privacy & Security Highlights
                    _buildPrivacySection(context, isDark, cardColor, textColor, subtextColor, borderColor),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action Bar
              _buildBottomAction(context, cubit, isGranted, isDark, textColor, subtextColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusHero(
    BuildContext context,
    bool isGranted,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGranted
              ? (isDark
                  ? [const Color(0xFF133E2B), const Color(0xFF0D281C)]
                  : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)])
              : (isDark
                  ? [const Color(0xFF332014), const Color(0xFF22150D)]
                  : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isGranted
              ? AppColors.income.withAlpha(isDark ? 100 : 160)
              : AppColors.primary.withAlpha(isDark ? 100 : 160),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGranted ? AppColors.income : AppColors.primary)
                .withAlpha(isDark ? 40 : 18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Circle with Pulse Effect
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.income.withAlpha(35)
                  : AppColors.primary.withAlpha(35),
              shape: BoxShape.circle,
              border: Border.all(
                color: isGranted ? AppColors.income : AppColors.primary,
                width: 2,
              ),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
              color: isGranted ? AppColors.income : AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),

          // Status Title
          Text(
            isGranted
                ? 'เปิดสิทธิ์การเข้าถึงเรียบร้อยแล้ว ✅'
                : 'จำเป็นต้องเปิดสิทธิ์ Notification Access 🔔',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isGranted
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857))
                  : textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Status Description
          Text(
            isGranted
                ? 'แอปพร้อมตรวจจับและดักฟังยอดเงินเข้า-ออก จากการแจ้งเตือนของแอปธนาคารไทยอัตโนมัติแล้ว'
                : 'เพื่อให้ "เจ้าตูบจด" สามารถรับรู้ยอดเงินเข้า-ออก จากแอปธนาคารได้ทันที โดยไม่ต้องพิมพ์เอง',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsGuide(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final steps = [
      {
        'num': '1',
        'title': 'กดปุ่ม "ไปหน้าตั้งค่า Android"',
        'desc': 'ระบบจะเปิดหน้าตั้งค่าการเข้าถึงการแจ้งเตือน (Device Notification Access)',
        'icon': Icons.touch_app_rounded,
      },
      {
        'num': '2',
        'title': 'ค้นหาและเลือกแอป "เจ้าตูบจด"',
        'desc': 'มองหาไอคอนเจ้าตูบจด (Budget Planner) ในรายการแอป',
        'icon': Icons.pets_rounded,
      },
      {
        'num': '3',
        'title': 'เลื่อนเปิดสวิตช์ "อนุญาต"',
        'desc': 'กดยืนยันการอนุญาต เพื่อให้ระบบเริ่มทำงานอัตโนมัติ',
        'icon': Icons.toggle_on_rounded,
      },
      {
        'num': '4',
        'title': 'ตั้งค่าแบตเตอรี่เป็น "ไม่จำกัด" (Unrestricted)',
        'desc': 'เพื่อป้องกันไม่ให้ Android ฆ่าระบบดักจับแจ้งเตือนเมื่อปิดแอปหรือจอดับ',
        'icon': Icons.battery_charging_full_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'วิธีเปิดสิทธิ์ง่ายๆ 3 ขั้นตอน',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withAlpha(90)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s['num'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
                          s['title'] as String,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtextColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'ความปลอดภัยและความเป็นส่วนตัวสูงสุด',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPrivacyRow(
            icon: Icons.account_balance_outlined,
            title: 'กรองเฉพาะแอปธนาคารไทยที่เลือก',
            desc: 'ระบบจะดักฟังเฉพาะการแจ้งเตือนจากแอปธนาคารที่คุณเปิดใช้งานเท่านั้น',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 10),
          _buildPrivacyRow(
            icon: Icons.lock_outline_rounded,
            title: 'ไม่แตะต้องข้อมูลส่วนตัว',
            desc: 'ไม่มีการอ่านแชท ข้อความ SMS ส่วนตัว รหัสผ่าน PIN หรือ OTP ใดๆ ทั้งสิ้น',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: 10),
          _buildPrivacyRow(
            icon: Icons.phonelink_lock_rounded,
            title: 'ประมวลผลภายในเครื่อง 100%',
            desc: 'ข้อมูลทั้งหมดถูกวิเคราะห์และจัดเก็บในเครื่องของคุณ ไม่ส่งข้อมูลออกนอกเครื่อง',
            textColor: textColor,
            subtextColor: subtextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyRow({
    required IconData icon,
    required String title,
    required String desc,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
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

  Widget _buildBottomAction(
    BuildContext context,
    AutoSyncCubit cubit,
    bool isGranted,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => cubit.openNotificationSettings(),
              icon: Icon(
                isGranted ? Icons.settings_rounded : Icons.settings_suggest_rounded,
                size: 20,
              ),
              label: Text(
                isGranted
                    ? 'เปิดหน้าตั้งค่าการแจ้งเตือน ⚙️'
                    : 'ไปหน้าตั้งค่า Android (เปิดสิทธิ์) ⚙️',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: TextButton.icon(
              onPressed: () => cubit.checkPermission(),
              icon: Icon(Icons.refresh_rounded, size: 16, color: subtextColor),
              label: Text(
                'ตรวจสอบสถานะสิทธิ์อีกครั้ง',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
