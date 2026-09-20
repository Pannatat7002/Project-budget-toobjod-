import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';

class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onClearPressed;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;
  final bool isLocked;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    this.onClearPressed,
    this.onBiometricPressed,
    this.showBiometric = true,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3'], isDark, textColor),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6'], isDark, textColor),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9'], isDark, textColor),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left Action: Biometric or empty placeholder
            _buildSpecialButton(
              child: showBiometric && onBiometricPressed != null
                  ? Icon(
                      Icons.fingerprint_rounded,
                      size: 32,
                      color: isLocked
                          ? AppColors.darkTextMuted
                          : AppColors.primaryOrange,
                    )
                  : const SizedBox(width: 72, height: 72),
              onTap: !isLocked && showBiometric ? onBiometricPressed : null,
              isDark: isDark,
              isAction: true,
            ),
            const SizedBox(width: 24),
            // Center: 0
            _buildDigitButton('0', isDark, textColor),
            const SizedBox(width: 24),
            // Right Action: Backspace
            _buildSpecialButton(
              child: Icon(
                Icons.backspace_outlined,
                size: 26,
                color: isLocked ? AppColors.darkTextMuted : textColor,
              ),
              onTap: !isLocked ? onDeletePressed : null,
              onLongPress: !isLocked ? onClearPressed : null,
              isDark: isDark,
              isAction: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits, bool isDark, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDigitButton(digits[0], isDark, textColor),
        const SizedBox(width: 24),
        _buildDigitButton(digits[1], isDark, textColor),
        const SizedBox(width: 24),
        _buildDigitButton(digits[2], isDark, textColor),
      ],
    );
  }

  Widget _buildDigitButton(String digit, bool isDark, Color textColor) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLocked
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onDigitPressed(digit);
                },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: isLocked ? AppColors.darkTextMuted : textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required Widget child,
    required VoidCallback? onTap,
    VoidCallback? onLongPress,
    required bool isDark,
    bool isAction = false,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress();
                }
              : null,
          child: Center(child: child),
        ),
      ),
    );
  }
}
