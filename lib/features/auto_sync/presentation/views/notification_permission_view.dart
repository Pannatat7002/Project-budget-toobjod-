import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isSimulating = false;

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
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AutoSyncCubit, AutoSyncState>(
        builder: (context, state) {
          final cubit = context.read<AutoSyncCubit>();
          final isGranted = state.isPermissionGranted;
          final isBatteryIgnored = state.isBatteryOptimizationIgnored;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  children: [
                    // 1. Hero Mascot & Permission Status Card
                    _buildStatusHero(context, isGranted, isDark, textColor, subtextColor),
                    const SizedBox(height: 18),

                    // 2. Interactive Live Test Simulator (Visible when granted)
                    if (isGranted) ...[
                      _buildLiveTestSimulator(context, cubit, isDark, cardColor, textColor, subtextColor, borderColor),
                      const SizedBox(height: 18),
                    ],

                    // 3. Step-by-Step Guide
                    _buildStepsGuide(context, isDark, cardColor, textColor, subtextColor, borderColor),
                    const SizedBox(height: 18),

                    // 4. Battery Optimization Guidance (Universal / OEM Friendly)
                    _buildBatteryOptimizationSection(
                      context,
                      cubit,
                      isBatteryIgnored,
                      isDark,
                      cardColor,
                      textColor,
                      subtextColor,
                      borderColor,
                    ),
                    const SizedBox(height: 18),

                    // 5. Privacy & Security Highlights (PDPA & Google Play Compliant)
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
                  ? [const Color(0xFF0F3826), const Color(0xFF0A2619)]
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
              ? AppColors.success.withAlpha(isDark ? 110 : 160)
              : AppColors.primary.withAlpha(isDark ? 100 : 160),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGranted ? AppColors.success : AppColors.primary)
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withAlpha(35)
                  : AppColors.primary.withAlpha(35),
              shape: BoxShape.circle,
              border: Border.all(
                color: isGranted ? AppColors.success : AppColors.primary,
                width: 2.2,
              ),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
              color: isGranted ? AppColors.success : AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.success.withAlpha(isDark ? 40 : 25)
                  : AppColors.primary.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isGranted ? AppColors.success.withAlpha(120) : AppColors.primary.withAlpha(120),
              ),
            ),
            child: Text(
              isGranted ? 'สถานะ: พร้อมใช้งานแล้ว ✅' : 'สถานะ: รอการเปิดสิทธิ์ ⏳',
              style: GoogleFonts.prompt(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGranted
                    ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857))
                    : (isDark ? AppColors.primaryLight : AppColors.primaryDark),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status Title
          Text(
            isGranted
                ? 'เปิดสิทธิ์การเข้าถึงเรียบร้อยแล้ว'
                : 'จำเป็นต้องเปิดสิทธิ์ Notification Access',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isGranted
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF047857))
                  : textColor,
            ),
          ),
          const SizedBox(height: 8),

          // Status Description
          Text(
            isGranted
                ? 'แอปพร้อมตรวจจับและบันทึกยอดเงินเข้า-ออก จากการแจ้งเตือนของแอปธนาคารไทยอัตโนมัติแล้ว'
                : 'เพื่อให้ "เจ้าตูบจด" สามารถรับรู้ยอดเงินเข้า-ออก จากแอปธนาคารได้ทันที โดยไม่ต้องพิมพ์เอง',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 13.5,
              color: subtextColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTestSimulator(
    BuildContext context,
    AutoSyncCubit cubit,
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
        border: Border.all(color: AppColors.success.withAlpha(100), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'ทดสอบจำลองการทำงานจริง (Live Test)',
                style: GoogleFonts.prompt(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ทดสอบว่าระบบสามารถตรวจจับและอ่านยอดเงินได้ถูกต้อง โดยจำลองการแจ้งเตือนจากธนาคาร',
            style: GoogleFonts.prompt(
              fontSize: 12.5,
              color: subtextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isSimulating
                  ? null
                  : () async {
                      setState(() => _isSimulating = true);
                      await cubit.sendTestNotification(
                        title: 'ธนาคารกสิกรไทย',
                        text: 'เงินเข้า 500.00 บ. เข้าบัญชี x-1234 เวลา 12:30 น.',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'ส่งการแจ้งเตือนจำลองสำเร็จ! ตรวจสอบรายการในหน้าแจ้งเตือนได้ทันที',
                                    style: GoogleFonts.prompt(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (mounted) setState(() => _isSimulating = false);
                    },
              icon: _isSimulating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success),
                    )
                  : const Icon(Icons.play_arrow_rounded, color: AppColors.success, size: 20),
              label: Text(
                _isSimulating ? 'กำลังจำลองแจ้งเตือน...' : 'จำลองยอดเงินเข้า ฿500.00 (K PLUS)',
                style: GoogleFonts.prompt(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
        'desc': 'มองหาไอคอนเจ้าตูบจด (Budget Planner) ในรายการแอปบนเครื่องของคุณ',
        'icon': Icons.pets_rounded,
      },
      {
        'num': '3',
        'title': 'เลื่อนเปิดสวิตช์ "อนุญาต"',
        'desc': 'กดยืนยันการอนุญาต เพื่อให้ระบบเริ่มบันทึกยอดเงินเข้า-ออกอัตโนมัติ',
        'icon': Icons.toggle_on_rounded,
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
                style: GoogleFonts.prompt(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
                      style: GoogleFonts.prompt(
                        fontSize: 13,
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
                          s['title'] as String,
                          style: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['desc'] as String,
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            color: subtextColor,
                            height: 1.38,
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

  Widget _buildBatteryOptimizationSection(
    BuildContext context,
    AutoSyncCubit cubit,
    bool isBatteryIgnored,
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
        border: Border.all(
          color: isBatteryIgnored ? AppColors.success.withAlpha(80) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBatteryIgnored ? Icons.battery_charging_full_rounded : Icons.battery_saver_rounded,
                size: 20,
                color: isBatteryIgnored ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'การตั้งค่าแบตเตอรี่ (ทำงานเบื้องหลังตลอดเวลา)',
                  style: GoogleFonts.prompt(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isBatteryIgnored
                ? 'ระบบประหยัดแบตเตอรี่ถูกปิดแล้ว แอปสามารถตรวจจับการแจ้งเตือนได้ต่อเนื่องแม้จอดับหรือปิดแอป ✅'
                : 'สมาร์ทโฟน Android (Samsung, Xiaomi, Oppo, Vivo) มักจะปิดแอปเบื้องหลังเมื่อจอดับ แนะนำให้ตั้งค่าเป็น "ไม่จำกัด" (Unrestricted)',
            style: GoogleFonts.prompt(
              fontSize: 12.5,
              color: subtextColor,
              height: 1.4,
            ),
          ),
          if (!isBatteryIgnored) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () => cubit.requestIgnoreBatteryOptimization(),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  'อนุญาตให้ทำงานเบื้องหลังไม่จำกัด ⚡',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
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
                'ความปลอดภัยและความเป็นส่วนตัวสูงสุด (PDPA)',
                style: GoogleFonts.prompt(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
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
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
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
          if (isGranted) ...[
            // Primary Button when granted: Done & Go to Main
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  'เริ่มต้นใช้งานทันที 🎉',
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
                onPressed: () => cubit.openNotificationSettings(),
                icon: Icon(Icons.settings_rounded, size: 16, color: subtextColor),
                label: Text(
                  'เปิดหน้าตั้งค่าการแจ้งเตือน Android ⚙️',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Primary Button when NOT granted: Go to Android Settings
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => cubit.openNotificationSettings(),
                icon: const Icon(Icons.settings_suggest_rounded, size: 20),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: TextButton.icon(
                onPressed: () => cubit.checkPermission(),
                icon: Icon(Icons.refresh_rounded, size: 16, color: subtextColor),
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
        ],
      ),
    );
  }
}
