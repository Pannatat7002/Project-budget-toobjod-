import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../state/account_cubit.dart';

class ReconciliationBottomSheet extends StatefulWidget {
  final BankAccountEntity account;

  const ReconciliationBottomSheet({
    super.key,
    required this.account,
  });

  static Future<void> show(
    BuildContext context, {
    required BankAccountEntity account,
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
        child: ReconciliationBottomSheet(account: account),
      ),
    );
  }

  @override
  State<ReconciliationBottomSheet> createState() =>
      _ReconciliationBottomSheetState();
}

class _ReconciliationBottomSheetState extends State<ReconciliationBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  double? _actualBalance;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    // Autofocus amount after bottom sheet animation finishes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _amountFocusNode.requestFocus();
      }
    });
  }

  void _onAmountChanged() {
    final cleanText = _amountController.text.replaceAll(',', '').trim();
    setState(() {
      _actualBalance = double.tryParse(cleanText);
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  double get _diff {
    if (_actualBalance == null) return 0.0;
    return _actualBalance! - widget.account.currentBalance;
  }

  bool get _canSubmit {
    return _actualBalance != null && _diff.abs() >= 0.01 && !_isSubmitting;
  }

  Future<void> _submitReconciliation() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.mediumImpact();

    final diffAmount = _diff;
    final isIncome = diffAmount > 0;
    final absDiff = diffAmount.abs();

    final customNote = _noteController.text.trim();
    final defaultNote =
        'ปรับปรุงยอดให้ตรงกับยอดจริงในธนาคาร (${CurrencyFormatter.format(_actualBalance!)} ฿)';

    final transaction = TransactionEntity(
      id: 'recon_${DateTime.now().millisecondsSinceEpoch}',
      title: isIncome
          ? 'ปรับปรุงยอดเงินเพิ่ม (กระทบยอด)'
          : 'ปรับปรุงยอดเงินลด (กระทบยอด)',
      amount: absDiff,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      categoryId:
          isIncome ? 'reconciliation_income' : 'reconciliation_expense',
      categoryName: isIncome ? 'ปรับปรุงยอดเงินเพิ่ม' : 'ปรับปรุงยอดเงินลด',
      categoryIconCode: 0xe8af, // Icons.tune
      categoryColorValue: isIncome ? 0xFF10B981 : 0xFF64748B,
      date: DateTime.now(),
      bankId: widget.account.bankId,
      bankAccountId: widget.account.id,
      bankShortName: widget.account.shortName,
      accountMask: widget.account.accountMask,
      note: customNote.isNotEmpty ? customNote : defaultNote,
    );

    final txCubit = context.read<TransactionCubit>();
    final accCubit = context.read<AccountCubit>();

    await txCubit.addTransaction(transaction);
    // Explicit balance refresh for zero-delay synchronization
    accCubit.refreshBalancesFromTransactions(txCubit.state.transactions);

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: const Color(0xFF0F172A),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'กระทบยอดสำเร็จ! ยอดคงเหลือตรงกับธนาคารแล้ว',
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = Color(widget.account.brandColor);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Bank Logo + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: brandColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      widget.account.logoAsset,
                      cacheWidth: 90,
                      cacheHeight: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_balance,
                        color: brandColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'กระทบยอดบัญชี',
                                style: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.account.accountMask != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: brandColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '•••• ${widget.account.accountMask!.replaceAll(RegExp(r'[^0-9]'), '')}',
                                  style: GoogleFonts.prompt(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: brandColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.account.shortName,
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Current Balance Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยอดคงเหลือในระบบขณะนี้',
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${CurrencyFormatter.format(widget.account.currentBalance)} ฿',
                              style: GoogleFonts.prompt(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ระบบปัจจุบัน',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actual Bank Balance Input Field
              Text(
                'ยอดเงินคงเหลือจริงในแอปธนาคาร',
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _amountFocusNode.hasFocus
                        ? brandColor
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: GoogleFonts.prompt(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 10),
                      child: Text(
                        '฿',
                        style: GoogleFonts.prompt(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: brandColor,
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _amountController.clear();
                              _onAmountChanged();
                            },
                          )
                        : null,
                    hintText: '0.00',
                    hintStyle: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Difference Calculation Preview Card
              if (_actualBalance != null) ...[
                _buildDifferenceCard(isDark, _diff),
                const SizedBox(height: 14),
              ],

              // Optional Note field
              Text(
                'บันทึกเพิ่มเติม (ไม่บังคับ)',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _noteController,
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'เช่น กระทบยอดต้นเดือน, ปรับปรุงดอกเบี้ย',
                    hintStyle: GoogleFonts.prompt(
                      fontSize: 13,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submitReconciliation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        disabledBackgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: _canSubmit ? 2 : 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'ยืนยันปรับยอด',
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _canSubmit
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.black26),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifferenceCard(bool isDark, double diff) {
    if (diff.abs() < 0.01) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ยอดเงินตรงกันแล้ว ไม่จำเป็นต้องปรับปรุงยอด',
                style: GoogleFonts.prompt(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isIncome = diff > 0;
    final cardColor = isIncome
        ? const Color(0xFF10B981).withValues(alpha: 0.12)
        : const Color(0xFFF59E0B).withValues(alpha: 0.12);
    final borderColor = isIncome
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFFF59E0B).withValues(alpha: 0.35);
    final textColor =
        isIncome ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final icon = isIncome
        ? Icons.add_circle_outline_rounded
        : Icons.remove_circle_outline_rounded;
    final label = isIncome
        ? 'จะเพิ่มรายการรายรับปรับยอด:'
        : 'จะเพิ่มรายการรายจ่ายปรับยอด:';
    final sign = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign${CurrencyFormatter.format(diff.abs())} ฿',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isIncome
                ? 'บันทึกเป็นหมวดหมู่ "ปรับปรุงยอดเงินเพิ่ม" เพื่อให้ยอดคงเหลือในแอปเท่ากับยอดจริงในธนาคารทันที'
                : 'บันทึกเป็นหมวดหมู่ "ปรับปรุงยอดเงินลด" เพื่อให้ยอดคงเหลือในแอปเท่ากับยอดจริงในธนาคารทันที',
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
