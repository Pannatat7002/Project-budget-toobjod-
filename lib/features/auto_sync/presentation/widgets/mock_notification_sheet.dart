import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bank_profile.dart';
import '../state/auto_sync_cubit.dart';
import 'bank_logo_badge.dart';

class MockNotificationSheet extends StatefulWidget {
  const MockNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MockNotificationSheet(),
    );
  }

  @override
  State<MockNotificationSheet> createState() => _MockNotificationSheetState();
}

class _MockNotificationSheetState extends State<MockNotificationSheet> {
  // Custom builder states
  String _selectedBankId = 'kbank';
  bool _isIncome = false;
  bool _isSmsMode = false;
  final _amountController = TextEditingController(text: '350');
  final _detailController = TextEditingController(text: 'ร้านอาหารตามสั่ง');

  final List<Map<String, dynamic>> _smsPresets = [
    {
      'bankId': 'kbank',
      'packageName': 'com.google.android.apps.messaging',
      'title': 'KBANK',
      'text': 'บช. x-4521 ใช้จ่าย 890.00 บาท ที่ TOPS MARKET วันที่ 10/09 15:30',
      'type': 'expense',
      'amount': 890.0,
      'desc': 'SMS: KBANK (ใช้จ่ายบัตร TOPS)',
    },
    {
      'bankId': 'scb',
      'packageName': 'com.google.android.apps.messaging',
      'title': 'SCB',
      'text': 'เงินเข้า 15,000.00บ เข้า บช x-8832 โอนจาก บจก.ไทยซอฟต์แวร์ ยอดคงเหลือ 28,500.00บ',
      'type': 'income',
      'amount': 15000.0,
      'desc': 'SMS: SCB (เงินเดือนเข้า บช.)',
    },
    {
      'bankId': 'ktb',
      'packageName': 'com.google.android.apps.messaging',
      'title': 'KTB',
      'text': 'เงินเข้า บช. x-1290 จำนวน 5,000.00 บาท ยอดเงินใช้ได้ 12,300.00 บาท',
      'type': 'income',
      'amount': 5000.0,
      'desc': 'SMS: KTB (เงินโอนเข้า)',
    },
    {
      'bankId': 'ttb',
      'packageName': 'com.google.android.apps.messaging',
      'title': 'ttb',
      'text': 'โอนเงินออก 320.00 บาท จาก บช x-7714 ให้แก่ ข้าวมันไก่เจ๊หงษ์ ยอดคงเหลือ 8,450.00 บาท',
      'type': 'expense',
      'amount': 320.0,
      'desc': 'SMS: ttb (โอนเงินออก)',
    },
    {
      'bankId': 'kbank',
      'packageName': 'com.google.android.apps.messaging',
      'title': 'KBANK',
      'text': 'บช. x-4521 เงินเข้า 3,500.00 บ. จาก นายสมชาย ว. ยอดคงเหลือ 45,650.00 บ.',
      'type': 'income',
      'amount': 3500.0,
      'desc': 'SMS: KBANK (รับโอนเงิน)',
    },
  ];

  final List<Map<String, dynamic>> _appPresets = [
    {
      'bankId': 'kbank',
      'packageName': 'com.kasikorn.retail.mbanking.wap',
      'title': 'K PLUS',
      'text': 'โอนเงินให้แก่ 7-Eleven จำนวน 189.00 บาท จาก บช. x-4521',
      'type': 'expense',
      'amount': 189.0,
      'desc': 'แอป: 7-Eleven (K PLUS)',
    },
    {
      'bankId': 'scb',
      'packageName': 'com.scb.phone',
      'title': 'SCB EASY',
      'text': 'เงินเข้า 25,000.00 บาท โอนจาก บริษัท ทูบจด มีตังค์ จำกัด เข้า บช. x-8832',
      'type': 'income',
      'amount': 25000.0,
      'desc': 'แอป: เงินเดือน/รายได้ (SCB EASY)',
    },
    {
      'bankId': 'ktb',
      'packageName': 'ktbcs.netbank',
      'title': 'Krungthai NEXT',
      'text': 'ชำระเงินให้แก่ BTS สายสุขุมวิท จำนวน 45.00 บาท จาก บช. x-1290',
      'type': 'expense',
      'amount': 45.0,
      'desc': 'แอป: ค่าโดยสาร BTS (Krungthai NEXT)',
    },
    {
      'bankId': 'ttb',
      'packageName': 'com.ttbbank.oneapp',
      'title': 'ttb touch',
      'text': 'ชำระเงินให้แก่ Cafe Amazon จำนวน 75.00 บาท จาก บช. x-7714',
      'type': 'expense',
      'amount': 75.0,
      'desc': 'แอป: Cafe Amazon (ttb touch)',
    },
    {
      'bankId': 'truemoney',
      'packageName': 'th.co.truemoney.wallet',
      'title': 'TrueMoney',
      'text': 'คุณได้ชำระเงิน 120.00 บ. ให้แก่ CP FreshMart สำเร็จ',
      'type': 'expense',
      'amount': 120.0,
      'desc': 'แอป: CP FreshMart (TrueMoney)',
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _handlePreset(Map<String, dynamic> preset) async {
    final cubit = context.read<AutoSyncCubit>();
    await cubit.simulateNotification(
      packageName: preset['packageName'] as String,
      title: preset['title'] as String,
      text: preset['text'] as String,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('⚡ '),
              Expanded(
                child: Text(
                  'ระบบดักจับการแจ้งเตือนจาก "${preset['title']}" เรียบร้อยแล้ว 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleMockSmsAll() async {
    final cubit = context.read<AutoSyncCubit>();
    final count = await cubit.mockSmsNotifications();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('📩 '),
              Expanded(
                child: Text(
                  'จำลอง SMS การเงิน $count รายการเข้าระบบให้ระบบดักจับแล้ว โฮ่ง! 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleMockAppAll() async {
    final cubit = context.read<AutoSyncCubit>();
    final count = await cubit.mockSampleNotifications();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🚀 '),
              Expanded(
                child: Text(
                  'จำลอง Notification จากแอปธนาคาร $count รายการเข้าระบบแล้ว โฮ่ง! 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleCustomSubmit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุจำนวนเงินที่ถูกต้อง'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final detail = _detailController.text.trim().isEmpty
        ? 'รายการทดสอบ'
        : _detailController.text.trim();

    final bank = BankProfile.findById(_selectedBankId) ?? BankProfile.supportedBanks.first;
    final cubit = context.read<AutoSyncCubit>();

    String pkg;
    String notifTitle;
    String notificationText;

    if (_isSmsMode) {
      pkg = 'com.google.android.apps.messaging';
      notifTitle = bank.shortName.toUpperCase();
      if (_isIncome) {
        notificationText = 'เงินเข้า ${amount.toStringAsFixed(2)}บ เข้า บช x-4521 จาก $detail';
      } else {
        notificationText = 'บช. x-4521 ใช้จ่าย ${amount.toStringAsFixed(2)} บาท ที่ $detail';
      }
    } else {
      pkg = bank.packageName;
      notifTitle = bank.shortName;
      if (_isIncome) {
        notificationText = 'เงินเข้า ${amount.toStringAsFixed(2)} บาท โอนจาก $detail เข้า บช. x-4521';
      } else {
        notificationText = 'โอนเงินให้แก่ $detail จำนวน ${amount.toStringAsFixed(2)} บาท จาก บช. x-4521';
      }
    }

    await cubit.simulateNotification(
      packageName: pkg,
      title: notifTitle,
      text: notificationText,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('✨ '),
              Expanded(
                child: Text(
                  'ดักจับการแจ้งเตือน $notifTitle (฿${amount.toStringAsFixed(2)}) สำเร็จ 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: subtextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_chat_unread_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จำลอง Notification & SMS ธนาคาร',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'ให้ระบบตรวจจับเงินเข้า-ออกโดยอัตโนมัติ 🐾',
                          style: TextStyle(fontSize: 11.5, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: subtextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // 1. One-Click Quick Actions (SMS & App)
                  Row(
                    children: [
                      // Mock SMS All Button (User requested!)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleMockSmsAll,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                child: Column(
                                  children: [
                                    Icon(Icons.sms_rounded, color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    Text(
                                      '📩 จำลอง 5 SMS ด่วน',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'KBANK, SCB, KTB, ttb',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Mock App Notifications Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleMockAppAll,
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    Text(
                                      '🚀 จำลอง 5 แอปด่วน',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'K PLUS, SCB, NEXT, ttb',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Section: Bank SMS Presets (High Priority)
                  Row(
                    children: [
                      const Icon(Icons.sms_outlined, size: 16, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Text(
                        'ข้อความ SMS ธนาคาร (แตะเพื่อจำลองทันที):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._smsPresets.map((preset) {
                    final isIncome = preset['type'] == 'income';
                    final color = isIncome ? AppColors.income : AppColors.expense;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(Icons.sms_rounded, color: Color(0xFF3B82F6), size: 18),
                        ),
                        title: Text(
                          preset['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          preset['text'] as String,
                          style: TextStyle(fontSize: 11, color: subtextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}฿${CurrencyFormatter.format(preset['amount'] as double)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.send_rounded, size: 16, color: Color(0xFF3B82F6)),
                          ],
                        ),
                        onTap: () => _handlePreset(preset),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // 3. Section: App Notification Presets
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'แอปพลิเคชันธนาคาร (Bank Apps):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._appPresets.map((preset) {
                    final isIncome = preset['type'] == 'income';
                    final color = isIncome ? AppColors.income : AppColors.expense;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: BankLogoBadge(
                          packageName: preset['packageName'] as String,
                          fallbackShortName: preset['title'] as String,
                          size: 34,
                        ),
                        title: Text(
                          preset['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          preset['text'] as String,
                          style: TextStyle(fontSize: 11, color: subtextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}฿${CurrencyFormatter.format(preset['amount'] as double)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.send_rounded, size: 16, color: Color(0xFF10B981)),
                          ],
                        ),
                        onTap: () => _handlePreset(preset),
                      ),
                    );
                  }),

                  const SizedBox(height: 18),

                  // 4. Custom Notification & SMS Builder Section
                  Text(
                    '✏️ สร้างการแจ้งเตือนกำหนดเอง:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Channel Mode Toggle: SMS vs App Notification
                        Row(
                          children: [
                            Text('ช่องทาง:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: false, label: Text('แอปธนาคาร', style: TextStyle(fontSize: 11.5))),
                                  ButtonSegment(value: true, label: Text('SMS ธนาคาร', style: TextStyle(fontSize: 11.5))),
                                ],
                                selected: {_isSmsMode},
                                onSelectionChanged: (val) => setState(() => _isSmsMode = val.first),
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  selectedBackgroundColor: _isSmsMode ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                                  selectedForegroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Select Bank
                        Row(
                          children: [
                            Text('ธนาคาร:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedBankId,
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: bgColor,
                                  items: BankProfile.supportedBanks.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Row(
                                        children: [
                                          BankLogoBadge(packageName: b.packageName, fallbackShortName: b.shortName, size: 20),
                                          const SizedBox(width: 8),
                                          Flexible(child: Text(b.shortName, style: TextStyle(fontSize: 12.5, color: textColor))),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedBankId = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),

                        // Income / Expense Toggle
                        Row(
                          children: [
                            Text('ประเภท:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(value: false, label: Text('เงินออก (จ่าย)', style: TextStyle(fontSize: 11.5))),
                                  ButtonSegment(value: true, label: Text('เงินเข้า (รับ)', style: TextStyle(fontSize: 11.5))),
                                ],
                                selected: {_isIncome},
                                onSelectionChanged: (val) => setState(() => _isIncome = val.first),
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  selectedBackgroundColor: _isIncome ? AppColors.income : AppColors.expense,
                                  selectedForegroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Amount Input
                        Row(
                          children: [
                            Text('จำนวนเงิน:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  prefixText: '฿ ',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Merchant / Sender Input
                        Row(
                          children: [
                            Text('ร้าน/ผู้โอน:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _detailController,
                                decoration: InputDecoration(
                                  hintText: 'เช่น ข้าวมันไก่, 7-Eleven, สมชาย',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Submit Custom Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleCustomSubmit,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(
                              _isSmsMode ? 'ส่ง SMS ทดสอบให้ระบบดักจับ 📩' : 'ส่ง Notification แอปจำลอง 🚀',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSmsMode ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
