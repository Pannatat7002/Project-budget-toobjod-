import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_helper.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../state/transaction_state.dart';

class RecurringTransactionsSheet extends StatefulWidget {
  const RecurringTransactionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<TransactionCubit>(),
        child: const RecurringTransactionsSheet(),
      ),
    );
  }

  @override
  State<RecurringTransactionsSheet> createState() => _RecurringTransactionsSheetState();
}

class _RecurringTransactionsSheetState extends State<RecurringTransactionsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('⏰', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รายการประจำอัตโนมัติ',
                          style: GoogleFonts.prompt(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ลงบัญชีอัตโนมัติเมื่อถึงวันที่กำหนด 🐾',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showAddRecurringDialog(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  tooltip: 'เพิ่มรายการประจำใหม่',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            labelStyle: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.prompt(fontSize: 13),
            tabs: const [
              Tab(text: 'ทั้งหมด'),
              Tab(text: 'รายจ่าย'),
              Tab(text: 'รายรับ'),
              Tab(text: 'โอนย้าย'),
            ],
          ),
          const Divider(height: 1),

          // Tab View
          Expanded(
            child: BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                final rules = state.recurringRules;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRuleList(rules, isDark),
                    _buildRuleList(
                      rules.where((r) => r.isExpense).toList(),
                      isDark,
                    ),
                    _buildRuleList(
                      rules.where((r) => r.isIncome).toList(),
                      isDark,
                    ),
                    _buildRuleList(
                      rules.where((r) => r.isTransfer).toList(),
                      isDark,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleList(List<RecurringTransactionEntity> rules, bool isDark) {
    if (rules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐶', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'ยังไม่มีรายการประจำในหมวดนี้',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'แตะปุ่ม + ด้านบนเพื่อตั้งค่ารายการอัตโนมัติ เช่น เงินเดือน, ผ่อนบ้าน, ค่าเน็ต, หรือโอนออมเงิน',
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 12.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rule = rules[index];
        return _buildRuleCard(rule, isDark);
      },
    );
  }

  Widget _buildRuleCard(RecurringTransactionEntity rule, bool isDark) {
    final nextDue = rule.getNextDueDate();
    final nextDueStr = DateFormat('d MMM', 'th').format(nextDue);
    final isIncome = rule.isIncome;
    final isTransfer = rule.isTransfer;

    final typeColor = isIncome
        ? const Color(0xFF10B981)
        : isTransfer
            ? const Color(0xFF6366F1)
            : const Color(0xFFEF4444);

    final prefix = isIncome ? '+' : (isTransfer ? '⇄' : '-');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rule.isActive
              ? (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(rule.categoryColorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconHelper.getIcon(rule.categoryIconCode),
                    color: Color(rule.categoryColorValue),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: rule.isActive
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            rule.categoryName,
                            style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          if (rule.bankShortName != null) ...[
                            const SizedBox(width: 4),
                            Text('•', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26)),
                            const SizedBox(width: 4),
                            Text(
                              rule.bankShortName!,
                              style: GoogleFonts.prompt(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '$prefix${CurrencyFormatter.format(rule.amount)}',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: rule.isActive ? typeColor : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Frequency, Next Run Date, and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.frequency == RecurringFrequency.monthly
                            ? 'ทุกเดือน วันที่ ${rule.scheduledDay}'
                            : rule.frequency == RecurringFrequency.weekly
                                ? 'ทุกสัปดาห์ (วัน${_getWeekdayName(rule.scheduledDay)})'
                                : 'ทุกวัน',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'รอบถัดไป: $nextDueStr',
                      style: GoogleFonts.prompt(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Trigger Now button
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<TransactionCubit>().triggerRecurringRuleNow(rule);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🐾 บันทึก "${rule.title}" ลงบัญชีแล้วทันใจ!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              'ลงทันที',
                              style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Pause/Resume Switch
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: rule.isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) {
                          context.read<TransactionCubit>().toggleRecurringRule(rule.id);
                        },
                      ),
                    ),
                    // Delete popup
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      onSelected: (val) {
                        if (val == 'delete') {
                          context.read<TransactionCubit>().deleteRecurringRule(rule.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'ลบรายการนี้',
                                style: GoogleFonts.prompt(color: Colors.redAccent, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int day) {
    const days = ['', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัส', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
    if (day >= 1 && day <= 7) return days[day];
    return '';
  }

  void _showAddRecurringDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddRecurringModalDialog(
        onSave: (newRule) {
          context.read<TransactionCubit>().saveRecurringRule(newRule);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _AddRecurringModalDialog extends StatefulWidget {
  final ValueChanged<RecurringTransactionEntity> onSave;

  const _AddRecurringModalDialog({required this.onSave});

  @override
  State<_AddRecurringModalDialog> createState() => _AddRecurringModalDialogState();
}

class _AddRecurringModalDialogState extends State<_AddRecurringModalDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  int _scheduledDay = 25;
  final RecurringFrequency _frequency = RecurringFrequency.monthly;
  late CategoryItem _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = AppConstants.defaultExpenseCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _type == TransactionType.income
        ? AppConstants.defaultIncomeCategories
        : AppConstants.defaultExpenseCategories;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            'ตั้งรายการประจำใหม่',
            style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('รายจ่าย')),
                ButtonSegment(value: TransactionType.income, label: Text('รายรับ')),
                ButtonSegment(value: TransactionType.transfer, label: Text('โอนย้าย')),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                  _selectedCategory = _type == TransactionType.income
                      ? AppConstants.defaultIncomeCategories.first
                      : (_type == TransactionType.transfer
                          ? AppConstants.transferCategory
                          : AppConstants.defaultExpenseCategories.first);
                });
              },
            ),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'ชื่อรายการ (เช่น เงินเดือน, ค่าเน็ต, ผ่อนรถ)',
                labelStyle: GoogleFonts.prompt(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'จำนวนเงิน (บาท)',
                labelStyle: GoogleFonts.prompt(fontSize: 13),
                prefixText: '฿ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Category selector
            if (_type != TransactionType.transfer) ...[
              Text('หมวดหมู่', style: GoogleFonts.prompt(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<CategoryItem>(
                initialValue: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 18),
                              const SizedBox(width: 8),
                              Text(cat.name, style: GoogleFonts.prompt(fontSize: 13)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (cat) {
                  if (cat != null) setState(() => _selectedCategory = cat);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Day selector
            Text('ทำซ้ำทุกเดือน วันที่:', style: GoogleFonts.prompt(fontSize: 12.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _scheduledDay.toDouble(),
                    min: 1,
                    max: 31,
                    divisions: 30,
                    activeColor: AppColors.primary,
                    label: 'วันที่ $_scheduledDay',
                    onChanged: (val) => setState(() => _scheduledDay = val.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'วันที่ $_scheduledDay',
                    style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ยกเลิก', style: GoogleFonts.prompt()),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
            if (title.isEmpty || amount <= 0) return;

            final newRule = RecurringTransactionEntity(
              id: const Uuid().v4(),
              title: title,
              amount: amount,
              type: _type,
              categoryId: _selectedCategory.id,
              categoryName: _selectedCategory.name,
              categoryIconCode: _selectedCategory.iconCode,
              categoryColorValue: _selectedCategory.colorValue,
              frequency: _frequency,
              scheduledDay: _scheduledDay,
              startDate: DateTime.now(),
              autoPost: true,
              isActive: true,
              tags: _selectedCategory.defaultTags,
            );

            widget.onSave(newRule);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('บันทึก', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
