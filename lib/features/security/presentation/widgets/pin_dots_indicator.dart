import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

class PinDotsIndicator extends StatefulWidget {
  final int length;
  final int filledCount;
  final bool isError;
  final bool isSuccess;
  final int shakeTrigger;

  const PinDotsIndicator({
    super.key,
    this.length = 4,
    required this.filledCount,
    this.isError = false,
    this.isSuccess = false,
    this.shakeTrigger = 0,
  });

  @override
  State<PinDotsIndicator> createState() => _PinDotsIndicatorState();
}

class _PinDotsIndicatorState extends State<PinDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant PinDotsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger && widget.shakeTrigger > 0) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Subtle sinusoidal horizontal shake
        final offset = sin(_shakeAnimation.value * pi * 4) * 12 * (1 - _shakeAnimation.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (index) {
          final isFilled = index < widget.filledCount;

          Color dotColor;
          Color borderColor;

          if (widget.isError) {
            dotColor = AppColors.error;
            borderColor = AppColors.error;
          } else if (widget.isSuccess || isFilled) {
            dotColor = AppColors.primaryOrange;
            borderColor = AppColors.primaryOrange;
          } else {
            dotColor = Colors.transparent;
            borderColor = isDark
                ? AppColors.darkTextMuted.withValues(alpha: 0.35)
                : AppColors.lightBorder;
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            width: (isFilled || widget.isSuccess) ? 18 : 16,
            height: (isFilled || widget.isSuccess) ? 18 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: Border.all(
                color: borderColor,
                width: (isFilled || widget.isSuccess) ? 0 : 2,
              ),
              boxShadow: (isFilled || widget.isSuccess) && !widget.isError
                  ? [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: widget.isSuccess ? 0.5 : 0.35),
                        blurRadius: widget.isSuccess ? 10 : 8,
                        spreadRadius: widget.isSuccess ? 2 : 1,
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
