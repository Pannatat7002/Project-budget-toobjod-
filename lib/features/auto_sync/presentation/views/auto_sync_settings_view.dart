import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/bank_profile.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
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
    final bgColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
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
          'ตรวจจับแจ้งเตือนธนาคาร',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, accState) {
          return BlocBuilder<AutoSyncCubit, AutoSyncState>(
            builder: (context, state) {
              final isGranted = state.isPermissionGranted;
              final isConnected = state.isServiceConnected;
              final isBatteryIgnored = state.isBatteryOptimizationIgnored;

              final userAccounts = accState.accounts;
              final connectedCount = userAccounts.length;
              final activeSyncCount = userAccounts.where((acc) {
                if (!acc.isAutoSyncActive) return false;
                final profile = BankProfile.findById(acc.bankId);
                if (profile == null) return true;
                if (state.enabledBankPackages.isEmpty) return true;
                return state.enabledBankPackages.contains(
                      profile.packageName,
                    ) ||
                    profile.packageAliases.any(
                      (a) => state.enabledBankPackages.contains(a),
                    );
              }).length;

              final String bankBadgeText;
              final Color bankBadgeColor;
              if (connectedCount == 0) {
                bankBadgeText = 'ยังไม่เพิ่มบัญชี ⚠️';
                bankBadgeColor = AppColors.warning;
              } else if (activeSyncCount == connectedCount) {
                bankBadgeText = 'เปิดตรวจจับ $activeSyncCount บัญชี ✅';
                bankBadgeColor = AppColors.success;
              } else if (activeSyncCount == 0) {
                bankBadgeText = 'ปิดตรวจจับทั้งหมด ❌';
                bankBadgeColor = AppColors.expense;
              } else {
                bankBadgeText = 'เปิด $activeSyncCount/$connectedCount บัญชี';
                bankBadgeColor = AppColors.primary;
              }

              final Widget bankIconWidget;
              if (userAccounts.isEmpty) {
                bankIconWidget = _buildGradientIcon(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  icon: Icons.account_balance_rounded,
                );
              } else if (userAccounts.length == 1) {
                final singleAcc = userAccounts.first;
                bankIconWidget = Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Color(singleAcc.brandColor).withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: BankLogoBadge(
                    bankId: singleAcc.bankId,
                    fallbackShortName: singleAcc.shortName,
                    fallbackColorValue: singleAcc.brandColor,
                    size: 46,
                    borderRadius: 15,
                  ),
                );
              } else {
                final displayAccounts = userAccounts.take(3).toList();
                bankIconWidget = Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withAlpha(70),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < displayAccounts.length; i++)
                        Positioned(
                          left: 4.0 + (i * 10.0),
                          child: BankLogoBadge(
                            bankId: displayAccounts[i].bankId,
                            fallbackShortName: displayAccounts[i].shortName,
                            fallbackColorValue: displayAccounts[i].brandColor,
                            size: 22,
                            borderRadius: 7,
                          ),
                        ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                children: [
                  // 1. เมนู: สิทธิ์การเข้าถึงแจ้งเตือน
                  _buildMenuItem(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    leading: _buildGradientIcon(
                      gradient: isGranted
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      icon: isGranted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                    ),
                    title: 'สิทธิ์การเข้าถึงแจ้งเตือน',
                    subtitle: isGranted
                        ? 'เปิดใช้งานแล้ว (แตะเพื่อจัดการหรือปิดสิทธิ์)'
                        : 'จำเป็นต้องเปิดสิทธิ์ Notification Access',
                    badgeText: isGranted
                        ? 'เปิดแล้ว ✅'
                        : 'สถานะ: รอเปิดสิทธิ์ ⏳',
                    badgeColor: isGranted
                        ? AppColors.success
                        : AppColors.warning,
                    onTap: () => context.push('/notification-permission'),
                  ),
                  const SizedBox(height: 12),

                  // 2. เมนู: ซ่อมแซมการเชื่อมต่อ Service
                  _buildMenuItem(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    leading: _buildGradientIcon(
                      gradient: (isGranted && isConnected)
                          ? const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      icon: Icons.sync_rounded,
                    ),
                    title: 'ซ่อมแซมการเชื่อมต่อ',
                    subtitle:
                        'กดเพื่อบังคับ Rebind Service หากระบบ Android ตัดการทำงาน',
                    badgeText: (isGranted && isConnected)
                        ? 'เชื่อมต่อปกติ 🟢'
                        : 'กดเชื่อมต่อใหม่ 🔄',
                    badgeColor: (isGranted && isConnected)
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFFF43F5E),
                    onTap: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      final success = await context
                          .read<AutoSyncCubit>()
                          .forceRebindService();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                success
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  success
                                      ? '🔄 สั่ง Rebind Service ดักจับแจ้งเตือนใหม่สำเร็จแล้ว!'
                                      : '⚠️ ไม่สามารถ Rebind ได้ กรุณาตรวจสอบสิทธิ์',
                                  style: GoogleFonts.prompt(fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: success
                              ? const Color(0xFF059669)
                              : Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 2.1 เมนู: ดึงแจ้งเตือนที่ตกหล่น (Manual Refresh)
                  _buildMenuItem(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    leading: _buildGradientIcon(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      icon: Icons.mark_email_unread_rounded,
                    ),
                    title: 'ดึงแจ้งเตือนที่ตกหล่น',
                    subtitle:
                        'สแกนแจ้งเตือนจากแถบแจ้งเตือนเครื่องและบัฟเฟอร์ด้วยตนเอง',
                    badgeText: 'กดดึงข้อมูล ⚡',
                    badgeColor: const Color(0xFF8B5CF6),
                    onTap: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(
                            '⏳ กำลังดึงแจ้งเตือนที่ตกหล่น...',
                            style: GoogleFonts.prompt(fontSize: 13.5),
                          ),
                          duration: const Duration(milliseconds: 900),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      final count = await context
                          .read<AutoSyncCubit>()
                          .manualSyncMissedNotifications();
                      if (!context.mounted) return;
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                count > 0
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  count == -1
                                      ? '⚠️ กรุณาเปิดสิทธิ์การอ่านการแจ้งเตือนก่อน'
                                      : (count > 0
                                          ? '🎉 ตรวจพบรายการตกหล่น $count รายการ!'
                                          : '🐾 ไม่พบแจ้งเตือนตกหล่นเพิ่มเติม'),
                                  style: GoogleFonts.prompt(fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: count > 0
                              ? const Color(0xFF059669)
                              : (count == -1
                                  ? Colors.orange
                                  : const Color(0xFF3B82F6)),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. เมนู: ปิดการประหยัดแบตเตอรี่ (Battery Optimization)
                  _buildMenuItem(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    leading: _buildGradientIcon(
                      gradient: isBatteryIgnored
                          ? const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      icon: isBatteryIgnored
                          ? Icons.battery_charging_full_rounded
                          : Icons.battery_saver_rounded,
                    ),
                    title: 'การประหยัดแบตเตอรี่',
                    subtitle: isBatteryIgnored
                        ? 'ไม่จำกัดการทำงานเบื้องหลัง (พร้อมดักจับตลอดเวลา)'
                        : 'แนะนำให้ตั้งเป็น "ไม่จำกัด" เพื่อไม่ให้ Android ฆ่าระบบตรวจจับ',
                    badgeText: isBatteryIgnored
                        ? 'ไม่จำกัด ✅'
                        : 'แนะนำตั้งค่า ⚡',
                    badgeColor: isBatteryIgnored
                        ? AppColors.success
                        : const Color(0xFFF59E0B),
                    onTap: () => context
                        .read<AutoSyncCubit>()
                        .requestIgnoreBatteryOptimization(),
                  ),
                  const SizedBox(height: 12),

                  // 4. เมนู: เลือกธนาคารตรวจจับ
                  _buildMenuItem(
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                    subtextColor: subtextColor,
                    borderColor: borderColor,
                    leading: bankIconWidget,
                    title: 'เลือกธนาคารตรวจจับ',
                    subtitle: connectedCount == 0
                        ? 'แตะเพื่อเพิ่มบัญชีธนาคารและเปิดระบบตรวจจับ'
                        : 'จัดการบัญชีและเปิด/ปิดตรวจจับรายธนาคาร',
                    badgeText: bankBadgeText,
                    badgeColor: bankBadgeColor,
                    onTap: () => context.push('/bank-selection'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGradientIcon({
    required Gradient gradient,
    required IconData icon,
    Color iconColor = Colors.white,
    double size = 46,
    double iconSize = 23,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withAlpha(70),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: iconSize),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                              style: GoogleFonts.prompt(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.prompt(
                                fontSize: 10.5,
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
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: subtextColor.withAlpha(160),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
