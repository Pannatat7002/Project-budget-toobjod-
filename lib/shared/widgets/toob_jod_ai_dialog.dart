import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class ToobJodAiDialog extends StatefulWidget {
  const ToobJodAiDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI Floating Bubble',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const ToobJodAiDialog(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ToobJodAiDialog> createState() => _ToobJodAiDialogState();
}

class _ToobJodAiDialogState extends State<ToobJodAiDialog> {
  int _selectedTipIndex = 0;

  final List<Map<String, String>> _tips = [
    {
      'title': '📊 สรุปยอดวันนี้',
      'message':
          'โฮ่งๆ! วันนี้การใช้จ่ายยังควบคุมได้ดีมากเลยนะเจ้านาย! 🐾 มียอดใช้จ่ายอยู่ในเกณฑ์ประหยัด อย่าลืมบันทึกบิลอาหารเย็นเพิ่มด้วยน้าโฮ่ง ✨',
    },
    {
      'title': '💡 ทริคประหยัดงบ',
      'message':
          'โฮ่ง! ถ้าลดของหวานหรือชานมสัปดาห์ละ 2 แก้ว เจ้านายจะมีเงินเก็บสะสมเพิ่มขึ้นเดือนละกว่า ฿600 เชียวนะครับ! 🧋🎉',
    },
    {
      'title': '🎯 แผนใช้จ่าย',
      'message':
          'โฮ่งๆ! หมวดอาหารและเดินทางคิดเป็น 55% ของงบเดือนนี้ แนะนำกระจายงบไปยังหมวดเงินออมเผื่อฉุกเฉินอีกนิดจะปลอดภัยสุดๆ เลยครับ! 🛡️💰',
    },
    {
      'title': '☕ งบกาแฟและขนม',
      'message':
          'โฮ่ง! เดือนนี้ยอดค่ากาแฟและของว่างอยู่ที่ประมาณ ฿420 ยังอยู่ในงบที่วางไว้ เก่งมากครับเจ้านาย! 🐾☕',
    },
  ];

  void _nextTip() {
    setState(() {
      _selectedTipIndex = (_selectedTipIndex + 1) % _tips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTip = _tips[_selectedTipIndex];
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final cardBgColor =
        isDark ? AppColors.darkCard : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomSafe),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Main Speech Bubble Container
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cardBorderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Dog Avatar + "ตูบจด AI" + Topic + Close Icon
                    Row(
                      children: [
                        // Mini Circular Avatar
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A00), Color(0xFF38BDF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/mascot_ai_dog_avatar.png',
                              cacheWidth: 90,
                              cacheHeight: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/mascot_ai_dog.png',
                                cacheWidth: 90,
                                cacheHeight: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/mascot_avatar.jpg',
                                  cacheWidth: 90,
                                  cacheHeight: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Name
                        Text(
                          'ตูบจด AI',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Topic
                        Expanded(
                          child: Text(
                            activeTip['title'] ?? '',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Close Button
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Message Body
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        activeTip['message'] ?? '',
                        key: ValueKey(_selectedTipIndex),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Footer Row: Cycle tips button + tip counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _nextTip,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'คำแนะนำถัดไป',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '${_selectedTipIndex + 1}/${_tips.length}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Downward Arrow Pointer pointing to the center AI Button on Toolbar
              Positioned(
                bottom: -8,
                child: CustomPaint(
                  size: const Size(16, 9),
                  painter: _BottomChatTailPainter(
                    color: cardBgColor,
                    borderColor: cardBorderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomChatTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _BottomChatTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BottomChatTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
