import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/models/pin_mode.dart';
import '../state/security_cubit.dart';
import '../state/security_state.dart';
import 'pin_screen.dart';

class SecuritySettingsView extends StatelessWidget {
  const SecuritySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SecurityCubit(localDataSource: di.sl())..init(),
      child: const _SecuritySettingsContent(),
    );
  }
}

class _SecuritySettingsContent extends StatelessWidget {
  const _SecuritySettingsContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'ความปลอดภัย & รหัสผ่าน',
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<SecurityCubit, SecurityState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<SecurityCubit>();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // 1. Header Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primaryOrange.withValues(alpha: 0.25),
                            AppColors.darkSurface,
                          ]
                        : [
                            const Color(0xFFFFF3E0),
                            const Color(0xFFFFE0B2),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.primaryOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.isPinSet ? 'ระบบความปลอดภัยเปิดอยู่' : 'ยังไม่ได้ตั้งรหัส PIN',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.isPinSet
                                ? 'ข้อมูลการเงินของคุณได้รับการปกป้องด้วยรหัส PIN'
                                : 'ตั้งรหัส PIN 4 หลักเพื่อป้องกันการเข้าถึงข้อมูลโดยไม่ได้รับอนุญาต',
                            style: GoogleFonts.prompt(
                              fontSize: 12.5,
                              color: textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'การตั้งค่าล็อกแอป',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Settings Container
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. PIN Code Switch
                    SwitchListTile(
                      value: state.isPinSet,
                      activeColor: AppColors.primaryOrange,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        'ล็อกแอปด้วยรหัส PIN 4 หลัก',
                        style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'ต้องกรอกรหัสผ่านทุกครั้งที่เปิดเข้าแอป',
                        style: GoogleFonts.prompt(
                          fontSize: 12.5,
                          color: textSecondary,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pin_rounded,
                          color: AppColors.primaryOrange,
                          size: 22,
                        ),
                      ),
                      onChanged: (enabled) async {
                        if (enabled) {
                          // Navigate to create PIN
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const PinScreen(
                                initialMode: PinMode.create,
                                isCancelable: true,
                              ),
                            ),
                          );
                          if (result == true) {
                            cubit.init();
                          }
                        } else {
                          // Verify current PIN before disabling
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const PinScreen(
                                initialMode: PinMode.verify,
                                isCancelable: true,
                              ),
                            ),
                          );
                          if (result == true) {
                            await cubit.removePin();
                            cubit.init();
                          }
                        }
                      },
                    ),

                    if (state.isPinSet) ...[
                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),

                      // 2. Change PIN Tile
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.password_rounded,
                            color: Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'เปลี่ยนรหัส PIN',
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'เปลี่ยนรหัสผ่าน 4 หลักใหม่',
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: textSecondary,
                        ),
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const PinScreen(
                                initialMode: PinMode.change,
                                isCancelable: true,
                              ),
                            ),
                          );
                          if (result == true) {
                            cubit.init();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('เปลี่ยนรหัส PIN สำเร็จเรียบร้อยแล้ว'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                      ),

                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),

                      // 3. Biometrics Switch
                      SwitchListTile(
                        value: state.isBiometricEnabled,
                        activeColor: AppColors.primaryOrange,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          'สแกนลายนิ้วมือ / ใบหน้า (Biometrics)',
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'ใช้ลายนิ้วมือหรือ Face ID เพื่อปลดล็อกแอปเร็วขึ้น',
                          style: GoogleFonts.prompt(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            color: Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        onChanged: (enabled) async {
                          await cubit.toggleBiometric(enabled);
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Hint & Device Credentials Support Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'กรณีลืมรหัส PIN ทำอย่างไร?',
                            style: GoogleFonts.prompt(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'คุณสามารถแตะ "ลืมรหัส PIN?" ที่หน้าจอกรอกรหัส แล้วยืนยันตัวตนด้วยรหัสล็อกหน้าจอเครื่อง (Device Screen Lock / Fingerprint) เพื่อรีเซ็ตและตั้งรหัส PIN ใหม่ได้ทันที',
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
