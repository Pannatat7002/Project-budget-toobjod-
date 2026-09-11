import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/bank_profile.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import '../widgets/bank_logo_badge.dart';

class AutoSyncSettingsView extends StatefulWidget {
  const AutoSyncSettingsView({super.key});

  @override
  State<AutoSyncSettingsView> createState() => _AutoSyncSettingsViewState();
}

class _AutoSyncSettingsViewState extends State<AutoSyncSettingsView>
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
          'ตรวจจับแจ้งเตือนธนาคาร',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AutoSyncCubit, AutoSyncState>(
        builder: (context, state) {
          final allBanks = BankProfile.supportedBanks;
          final enabledCount = state.enabledBankPackages.isEmpty
              ? allBanks.length
              : allBanks.where((b) => state.enabledBankPackages.contains(b.packageName)).length;

          final isGranted = state.isPermissionGranted;
          final isConnected = state.isServiceConnected;
          final isBatteryIgnored = state.isBatteryOptimizationIgnored;
          final previewBanks = allBanks.take(3).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. ปุ่ม: สิทธิ์การเข้าถึงแจ้งเตือน
              _buildMenuItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? AppColors.income.withAlpha(25)
                        : AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                    color: isGranted ? AppColors.income : AppColors.primary,
                    size: 24,
                  ),
                ),
                title: 'สิทธิ์การเข้าถึงแจ้งเตือน',
                subtitle: isGranted
                    ? 'เปิดใช้งานเรียบร้อยแล้ว'
                    : 'จำเป็นต้องเปิดสิทธิ์ Notification Access',
                badgeText: isGranted ? 'เปิดแล้ว ✅' : 'ต้องเปิดสิทธิ์ ⚠️',
                badgeColor: isGranted ? AppColors.income : AppColors.warning,
                onTap: () => context.push('/notification-permission'),
              ),
              const SizedBox(height: 14),

              // 2. ปุ่ม: ปิดการประหยัดแบตเตอรี่ (Battery Optimization)
              _buildMenuItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBatteryIgnored
                        ? AppColors.income.withAlpha(25)
                        : const Color(0xFFF59E0B).withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isBatteryIgnored ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                    color: isBatteryIgnored ? AppColors.income : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                title: 'การประหยัดแบตเตอรี่',
                subtitle: isBatteryIgnored
                    ? 'ไม่จำกัดการทำงานเบื้องหลัง (พร้อมดักจับตลอดเวลา)'
                    : 'แนะนำให้ตั้งเป็น "ไม่จำกัด" เพื่อไม่ให้ Android ฆ่าระบบตรวจจับ',
                badgeText: isBatteryIgnored ? 'ไม่จำกัด ✅' : 'แนะนำตั้งค่า ⚡',
                badgeColor: isBatteryIgnored ? AppColors.income : const Color(0xFFF59E0B),
                onTap: () => context.read<AutoSyncCubit>().requestIgnoreBatteryOptimization(),
              ),
              const SizedBox(height: 14),

              // 3. ปุ่ม: ซ่อมแซม / รีเฟรชการเชื่อมต่อ Service
              _buildMenuItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isGranted && isConnected)
                        ? AppColors.income.withAlpha(25)
                        : AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    color: (isGranted && isConnected) ? AppColors.income : AppColors.primary,
                    size: 24,
                  ),
                ),
                title: 'ซ่อมแซมการเชื่อมต่อ',
                subtitle: 'กดเพื่อบังคับ Rebind Service หากระบบ Android ตัดการทำงาน',
                badgeText: (isGranted && isConnected) ? 'เชื่อมต่อปกติ 🟢' : 'กดเชื่อมต่อใหม่ 🔄',
                badgeColor: (isGranted && isConnected) ? AppColors.income : AppColors.primary,
                onTap: () async {
                  final scaffold = ScaffoldMessenger.of(context);
                  final success = await context.read<AutoSyncCubit>().forceRebindService();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '🔄 สั่ง Rebind Service ดักจับแจ้งเตือนใหม่สำเร็จแล้ว!'
                            : '⚠️ ไม่สามารถ Rebind ได้ กรุณาตรวจสอบสิทธิ์',
                      ),
                      backgroundColor: success ? const Color(0xFF059669) : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 4. สวิตช์: ตรวจจับการโอนเงินข้ามบัญชีอัตโนมัติ (Smart Transfer Detection)
              _buildSwitchItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 26,
                  ),
                ),
                title: 'ตรวจจับโอนข้ามบัญชีอัตโนมัติ',
                subtitle: 'เมื่อโอนเงินระหว่างบัญชีในเครื่องเดียวกัน ระบบจะไม่นับเป็นรายรับหรือรายจ่ายซ้ำซ้อน',
                value: state.isTransferDetectionEnabled,
                onChanged: (val) => context.read<AutoSyncCubit>().toggleTransferDetection(val),
              ),
              const SizedBox(height: 14),

              // 5. ปุ่ม: เลือกธนาคารตรวจจับ
              _buildMenuItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: SizedBox(
                  width: 46,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      for (int i = 0; i < previewBanks.length; i++)
                        Positioned(
                          left: i * 11.0,
                          child: BankLogoBadge(
                            bankId: previewBanks[i].id,
                            packageName: previewBanks[i].packageName,
                            fallbackShortName: previewBanks[i].shortName,
                            fallbackColorValue: previewBanks[i].brandColor,
                            size: 24,
                            borderRadius: 6,
                          ),
                        ),
                    ],
                  ),
                ),
                title: 'เลือกธนาคารตรวจจับ',
                subtitle: 'เลือกแอปที่ต้องการให้ตรวจจับยอดเงิน',
                badgeText: 'เปิด $enabledCount/${allBanks.length} แอป',
                badgeColor: AppColors.primary,
                onTap: () => context.push('/bank-selection'),
              ),
              const SizedBox(height: 14),

              // 6. ปุ่ม: คำแนะนำและวิธีแก้ปัญหาการตรวจจับแต่ละรุ่นมือถือ (Troubleshooting Guide)
              _buildMenuItem(
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                borderColor: borderColor,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFFEC4899),
                    size: 24,
                  ),
                ),
                title: 'คู่มือแก้ปัญหาตรวจจับ',
                subtitle: 'วิธีตั้งค่า Xiaomi, Samsung, Oppo และข้อจำกัดต่างๆ',
                badgeText: 'คู่มือ 📖',
                badgeColor: const Color(0xFFEC4899),
                onTap: () => _showDeviceTroubleshootingSheet(context, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeviceTroubleshootingSheet(BuildContext context, bool isDark) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: subtextColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFEC4899),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คู่มือตั้งค่า & แก้ไขปัญหาตรวจจับ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'คำแนะนำเพื่อให้ระบบตรวจจับทำงานแม่นยำ 100%',
                            style: TextStyle(fontSize: 12, color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subtextColor),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildGuideCard(
                      title: '1. ตั้งค่าการทำงานเบื้องหลัง (สำคัญมาก)',
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: 'มือถือแบรนด์ Xiaomi (HyperOS/MIUI), Samsung, Oppo, Vivo มักจะสั่งหยุดการทำงานของแอปเมื่อปิดหน้าจอ\n\n'
                          '👉 **วิธีแก้:**\n'
                          '• ไปที่ ตั้งค่าเครื่อง > แอป > Budget Planner > แบตเตอรี่ > เลือก **"ไม่จำกัด (Unrestricted)"**\n'
                          '• (สำหรับ Xiaomi/Oppo) เปิดเมนู **"เริ่มทำงานอัตโนมัติ (Autostart)"** ให้แอป',
                    ),
                    const SizedBox(height: 14),
                    _buildGuideCard(
                      title: '2. การแสดงข้อความบนหน้าจอล็อก',
                      icon: Icons.lock_open_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: 'หากมือถือตั้งค่า **"ซ่อนเนื้อหาที่ละเอียดอ่อนบนหน้าจอล็อก"** ข้อความแจ้งเตือนจะถูกซ่อนตัวเลขยอดเงิน ทำให้ระบบไม่สามารถอ่านตัวเลขได้\n\n'
                          '👉 **วิธีแก้:** ตั้งค่าให้แสดงเนื้อหาการแจ้งเตือนจากแอปธนาคารตามปกติ',
                    ),
                    const SizedBox(height: 14),
                    _buildGuideCard(
                      title: '3. ระบบโอนเงินข้ามบัญชีตัวเอง (Smart Match)',
                      icon: Icons.swap_horiz_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: 'เมื่อโอนเงินระหว่างบัญชี (เช่น KBank ➔ SCB หรือโอนในธนาคารเดียวกัน) ระบบจะจับคู่อัตโนมัติเมื่อ:\n'
                          '• ยอดเงินตรงกันเป๊ะ\n'
                          '• มีทั้งยอดเงินออกและเงินเข้าเกิดขึ้นภายใน **90 วินาที**\n'
                          '• ระบบจะยกเลิกทั้ง 2 รายการอัตโนมัติ เพื่อไม่ให้ยอดรายรับ-รายจ่ายบวม',
                    ),
                    const SizedBox(height: 14),
                    _buildGuideCard(
                      title: '4. แจ้งเตือนหลุดการเชื่อมต่อ?',
                      icon: Icons.sync_problem_rounded,
                      iconColor: const Color(0xFF10B981),
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      content: 'หากพบว่าระบบหยุดตรวจจับหลังจากรีสตาร์ทเครื่องหรือไม่ได้เปิดแอปนานๆ สามารถกดปุ่ม **"ซ่อมแซมการเชื่อมต่อระบบตรวจจับ"** ในหน้าตั้งค่านี้ เพื่อสั่ง Rebind Service ใหม่ได้ทันที',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 12.5, color: subtextColor, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
    required Widget leading,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: subtextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color borderColor,
    required Widget leading,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

}
