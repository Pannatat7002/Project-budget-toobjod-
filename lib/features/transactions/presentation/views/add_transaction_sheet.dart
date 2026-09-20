import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../widgets/delete_transaction_dialog.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionEntity? existingTransaction;
  final TransactionType initialType;
  final String? initialBankId;
  final String? initialBankAccountId;

  const AddTransactionSheet({
    super.key,
    this.existingTransaction,
    this.initialType = TransactionType.expense,
    this.initialBankId,
    this.initialBankAccountId,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionEntity? existingTransaction,
    TransactionType initialType = TransactionType.expense,
    String? initialBankId,
    String? initialBankAccountId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TransactionCubit>()),
          BlocProvider.value(value: context.read<AccountCubit>()),
        ],
        child: AddTransactionSheet(
          existingTransaction: existingTransaction,
          initialType: initialType,
          initialBankId: initialBankId,
          initialBankAccountId: initialBankAccountId,
        ),
      ),
    );
  }

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _amountFocusNode = FocusNode();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _selectedType;
  late CategoryItem _selectedCategory;
  late DateTime _selectedDate;
  bool _showMoreOptions = false;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;

    _selectedType = existing?.type ?? widget.initialType;
    _selectedDate = existing?.date ?? DateTime.now();

    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _showMoreOptions = existing != null && (existing.note != null && existing.note!.isNotEmpty);

    final initialList = _selectedType == TransactionType.expense
        ? AppConstants.defaultExpenseCategories
        : AppConstants.defaultIncomeCategories;

    if (existing != null) {
      _selectedCategory = initialList.firstWhere(
        (c) => c.id == existing.categoryId,
        orElse: () => initialList.first,
      );
    } else {
      _selectedCategory = initialList.first;
    }

    // Auto-focus amount field so user can type immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && _amountFocusNode.canRequestFocus) {
          _amountFocusNode.requestFocus();
          if (_amountController.text.isNotEmpty) {
            _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
          }
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedAccountId == null) {
      final accState = context.read<AccountCubit>().state;
      final existing = widget.existingTransaction;

      if (existing != null) {
        if (existing.bankAccountId != null && accState.accounts.any((a) => a.id == existing.bankAccountId)) {
          _selectedAccountId = existing.bankAccountId;
        } else if (existing.bankId != null && accState.accounts.any((a) => a.bankId == existing.bankId)) {
          _selectedAccountId = accState.accounts.firstWhere((a) => a.bankId == existing.bankId).id;
        }
      }

      if (_selectedAccountId == null && accState.accounts.isNotEmpty) {
        // Priority 1: explicitly passed initialBankAccountId
        if (widget.initialBankAccountId != null && accState.accounts.any((a) => a.id == widget.initialBankAccountId)) {
          _selectedAccountId = widget.initialBankAccountId;
        }
        // Priority 2: explicitly passed initialBankId (e.g. from current bank card on dashboard)
        else if (widget.initialBankId != null && accState.accounts.any((a) => a.bankId == widget.initialBankId)) {
          _selectedAccountId = accState.accounts.firstWhere((a) => a.bankId == widget.initialBankId).id;
        }
        // Priority 3: currently selected bank in AccountCubit
        else if (accState.selectedBankId != null) {
          final matched = accState.accounts.where((a) => a.bankId == accState.selectedBankId).toList();
          if (matched.isNotEmpty) {
            _selectedAccountId = matched.first.id;
          }
        }
        // Priority 4: fallback to first account
        _selectedAccountId ??= accState.accounts.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      final categories = type == TransactionType.expense
          ? AppConstants.defaultExpenseCategories
          : AppConstants.defaultIncomeCategories;
      _selectedCategory = categories.first;
      if (widget.existingTransaction == null) {
        _titleController.clear();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      final id = widget.existingTransaction?.id ?? const Uuid().v4();

      final enteredTitle = _titleController.text.trim();
      final finalTitle = enteredTitle.isNotEmpty ? enteredTitle : _selectedCategory.name;

      final accState = context.read<AccountCubit>().state;
      final matchedAcc = accState.accounts.where((a) => a.id == _selectedAccountId).toList();
      final selectedAcc = matchedAcc.isNotEmpty ? matchedAcc.first : null;

      final transaction = TransactionEntity(
        id: id,
        title: finalTitle,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategory.id,
        categoryName: _selectedCategory.name,
        categoryIconCode: _selectedCategory.iconCode,
        categoryColorValue: _selectedCategory.colorValue,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        bankId: selectedAcc?.bankId ?? widget.existingTransaction?.bankId,
        bankAccountId: selectedAcc?.id ?? widget.existingTransaction?.bankAccountId,
        bankShortName: selectedAcc?.shortName ?? widget.existingTransaction?.bankShortName,
        accountMask: selectedAcc?.accountMask ?? widget.existingTransaction?.accountMask,
        targetAccountId: widget.existingTransaction?.targetAccountId,
      );

      final cubit = context.read<TransactionCubit>();
      if (widget.existingTransaction != null) {
        cubit.updateTransaction(transaction);
      } else {
        cubit.addTransaction(transaction);
      }

      context.read<AccountCubit>().refreshBalancesFromTransactions(cubit.state.transactions);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _selectedType == TransactionType.expense
        ? AppConstants.defaultExpenseCategories
        : AppConstants.defaultIncomeCategories;
    final primaryThemeColor = _selectedType == TransactionType.income ? AppColors.income : AppColors.expense;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset > 0
            ? bottomInset + 8
            : (18 + MediaQuery.of(context).padding.bottom),
        left: 16,
        right: 16,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? Border.all(color: AppColors.darkBorderSubtle, width: 1) : null,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar & Close
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header with Type Switcher Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.existingTransaction != null
                              ? 'แก้ไขรายการ'
                              : (_selectedType == TransactionType.income ? 'รับเงินเข้า (+)' : 'จ่ายเงินออก (-)'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.existingTransaction != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                          tooltip: 'ลบรายการ',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final confirmed = await DeleteTransactionDialog.show(
                              context,
                              widget.existingTransaction!,
                            );
                            if (confirmed && mounted) {
                              context.read<TransactionCubit>().deleteTransaction(widget.existingTransaction!.id);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Compact Type Toggle Pill
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      _buildTypePill(
                        type: TransactionType.expense,
                        label: 'จ่ายเงินออก',
                        imageAsset: 'assets/images/action_expense.png',
                        icon: Icons.arrow_upward,
                        color: AppColors.expense,
                        isDark: isDark,
                      ),
                      _buildTypePill(
                        type: TransactionType.income,
                        label: 'รับเงินเข้า',
                        imageAsset: 'assets/images/action_income.png',
                        icon: Icons.arrow_downward,
                        color: AppColors.income,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scrollable Content Area (Compact)
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Input (Hero Display)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            '฿',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: primaryThemeColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'กรุณาระบุจำนวนเงิน';
                                final numVal = double.tryParse(val);
                                if (numVal == null || numVal <= 0) return 'จำนวนเงินต้องมากกว่า 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Account / Bank Selector (Unified Multi-Bank Architecture)
                    _buildAccountSelector(isDark),
                    const SizedBox(height: 12),

                    // Category Grid (Compact 4-columns)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'หมวดหมู่: ${_selectedCategory.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedCategory.color,
                          ),
                        ),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatRelative(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: 84,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat.id == _selectedCategory.id;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withValues(alpha: isDark ? 0.25 : 0.14)
                                  : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? cat.color : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                                width: isSelected ? 2.0 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: cat.color.withValues(alpha: isDark ? 0.35 : 0.20),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0 : 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Image.asset(
                                      cat.imageAsset,
                                      cacheWidth: 108,
                                      cacheHeight: 108,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => CategoryIconBadge(
                                        icon: cat.icon,
                                        color: cat.color,
                                        size: 36,
                                        iconSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? cat.color
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Title Input (Compact Field)
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ชื่อรายการ (เว้นว่างจะใช้: ${_selectedCategory.name})',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Toggle More Options (Note)
                    if (!_showMoreOptions)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showMoreOptions = true),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('เพิ่มโน้ตช่วยจำ'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'บันทึกช่วยจำ (ไม่บังคับ)...',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.notes_rounded, size: 16),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sticky Bottom Prominent Save Button (Always in Thumb Reach!)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _onSubmit,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  widget.existingTransaction != null ? 'บันทึกการแก้ไข' : 'บันทึกรายการ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryThemeColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePill({
    required TransactionType type,
    required String label,
    required String imageAsset,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imageAsset,
              width: 22,
              height: 22,
              cacheWidth: 66,
              cacheHeight: 66,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSelector(bool isDark) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accState) {
        if (accState.accounts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'บัญชี / กระเป๋า:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: accState.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final acc = accState.accounts[idx];
                  final isAccSelected = _selectedAccountId == acc.id;
                  final brandCol = Color(acc.brandColor);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAccountId = acc.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAccSelected
                            ? brandCol.withValues(alpha: 0.18)
                            : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAccSelected
                              ? brandCol
                              : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                          width: isAccSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: brandCol,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                acc.logoAsset,
                                cacheWidth: 60,
                                cacheHeight: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            acc.accountMask != null ? '${acc.shortName} • ${acc.accountMask}' : acc.shortName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isAccSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isAccSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
