import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/models/pin_mode.dart';
import '../state/security_cubit.dart';
import '../state/security_state.dart';
import '../widgets/pin_dots_indicator.dart';
import '../widgets/pin_keypad.dart';

class PinScreen extends StatelessWidget {
  final PinMode initialMode;
  final VoidCallback? onSuccess;
  final bool isCancelable;

  const PinScreen({
    super.key,
    this.initialMode = PinMode.verify,
    this.onSuccess,
    this.isCancelable = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = SecurityCubit(localDataSource: di.sl());
        cubit.init(defaultMode: initialMode);
        return cubit;
      },
      child: _PinScreenContent(
        onSuccess: onSuccess,
        isCancelable: isCancelable,
      ),
    );
  }
}

class _PinScreenContent extends StatelessWidget {
  final VoidCallback? onSuccess;
  final bool isCancelable;

  const _PinScreenContent({
    this.onSuccess,
    this.isCancelable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return BlocConsumer<SecurityCubit, SecurityState>(
      listener: (context, state) {
        if (state.isSuccess) {
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 250), () {
            if (context.mounted) {
              if (onSuccess != null) {
                onSuccess!();
              } else if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/');
              }
            }
          });
        }
      },
      builder: (context, state) {
        final cubit = context.read<SecurityCubit>();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: isCancelable
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textPrimaryColor,
                    ),
                    onPressed: () => context.pop(false),
                  ),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // 🐕 1. Mascot Avatar (ToobJod Shiba Mascot)
                _buildMascotAvatar(isDark),

                const SizedBox(height: 20),

                // 2. Title & Subtitle
                Text(
                  _getTitle(state.mode),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getSubtitle(state.mode, state.isLocked, state.lockoutRemainingSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    color: state.isLocked ? AppColors.error : textSecondaryColor,
                    fontWeight: state.isLocked ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // 3. Pin Dots Indicator (4 Minimal Dots)
                PinDotsIndicator(
                  length: 4,
                  filledCount: state.enteredPin.length,
                  isError: state.isError,
                  isSuccess: state.isSuccess,
                  shakeTrigger: state.shakeCount,
                ),

                // 4. Error message or spacing
                Container(
                  height: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: state.errorMessage != null && !state.isLocked
                      ? Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : null,
                ),

                const Spacer(flex: 1),

                // 5. Minimal Keypad (3x4 Grid)
                PinKeypad(
                  onDigitPressed: cubit.inputDigit,
                  onDeletePressed: cubit.deleteDigit,
                  onClearPressed: cubit.clearPin,
                  onBiometricPressed: (state.mode == PinMode.verify && state.isBiometricAvailable)
                      ? cubit.triggerBiometric
                      : null,
                  showBiometric: state.mode == PinMode.verify,
                  isLocked: state.isLocked,
                ),

                const SizedBox(height: 20),

                // 6. Action Footer (e.g. Forgot PIN)
                if (state.mode == PinMode.verify)
                  TextButton(
                    onPressed: () {
                      _showForgotPinDialog(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'ลืมรหัส PIN?',
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                else
                  const SizedBox(height: 36),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascotAvatar(bool isDark) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryOrange.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            'assets/images/mascot_dog_peek.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.pets_rounded,
              size: 36,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(PinMode mode) {
    switch (mode) {
      case PinMode.verify:
        return 'กรอกรหัส PIN';
      case PinMode.create:
        return 'ตั้งรหัส PIN 4 หลัก';
      case PinMode.confirm:
        return 'ยืนยันรหัส PIN';
      case PinMode.change:
        return 'กรอกรหัส PIN เดิม';
    }
  }

  String _getSubtitle(PinMode mode, bool isLocked, int remainingSeconds) {
    if (isLocked) {
      return 'กรุณารอ $remainingSeconds วินาทีก่อนลองใหม่';
    }
    switch (mode) {
      case PinMode.verify:
        return 'แตะเพื่อเข้าสู่แอปพลิเคชัน';
      case PinMode.create:
        return 'สร้างรหัสผ่านเพื่อความปลอดภัย';
      case PinMode.confirm:
        return 'กรอกรหัส 4 หลักเดิมอีกครั้งเพื่อยืนยัน';
      case PinMode.change:
        return 'ยืนยันตัวตนก่อนเปลี่ยนรหัสผ่าน';
    }
  }

  void _showForgotPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.primaryOrange),
            SizedBox(width: 8),
            Text('ลืมรหัส PIN?'),
          ],
        ),
        content: const Text(
          'คุณสามารถใช้การสแกนลายนิ้วมือเพื่อเข้าสู่ระบบ หรือหากจำรหัสไม่ได้ ระบบจะให้รีเซ็ตข้อมูลความปลอดภัยใหม่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}
