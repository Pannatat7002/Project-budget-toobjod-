import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dog_sound_helper.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../domain/entities/transaction_entity.dart';
import '../state/transaction_cubit.dart';
import '../widgets/delete_transaction_dialog.dart';
import '../../../accounts/domain/entities/bank_account_entity.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
import '../../../auto_sync/presentation/widgets/bank_logo_badge.dart';

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
  String? _selectedTargetAccountId;
  String? _matchedTargetTransactionId;
  bool _autoCreateTargetIncome = true;
  bool _hasUserManuallyUnlinked = false;
  String? _dogAutoSuggestedCategoryName;
  bool _hasUserManuallySelectedCategory = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;

    _selectedType = existing?.type ?? widget.initialType;
    _selectedDate = existing?.date ?? DateTime.now();

    _titleController = TextEditingController(text: existing?.title ?? '');
    _titleController.addListener(_onTitleChanged);
    _amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    _amountController.addListener(_onAmountChanged);
    _noteController = TextEditingController(text: existing?.note ?? '');
    _showMoreOptions = existing != null && (existing.note != null && existing.note!.isNotEmpty);
    _selectedTargetAccountId = existing?.targetAccountId;

    final initialList = _selectedType == TransactionType.transfer
        ? [
            const CategoryItem(
              id: 'transfer',
              name: 'โอนย้ายเงิน',
              iconCode: 0xe8d4,
              colorValue: 0xFF6366F1,
            )
          ]
        : (_selectedType == TransactionType.expense
            ? AppConstants.defaultExpenseCategories
            : AppConstants.defaultIncomeCategories);

    if (existing != null) {
      _selectedCategory = initialList.where((c) => c.id == existing.categoryId).firstOrNull ?? initialList.first;
    } else {
      _selectedCategory = initialList.first;
    }

    // Auto-focus amount field ONLY when creating a new transaction, not when editing
    if (existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted && _amountFocusNode.canRequestFocus) {
            _amountFocusNode.requestFocus();
          }
        });
      });
    }
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
          _selectedAccountId = accState.accounts.where((a) => a.bankId == existing.bankId).firstOrNull?.id;
        }
      }

      if (_selectedAccountId == null && accState.accounts.isNotEmpty) {
        if (widget.initialBankAccountId != null && accState.accounts.any((a) => a.id == widget.initialBankAccountId)) {
          _selectedAccountId = widget.initialBankAccountId;
        } else if (widget.initialBankId != null && accState.accounts.any((a) => a.bankId == widget.initialBankId)) {
          _selectedAccountId = accState.accounts.where((a) => a.bankId == widget.initialBankId).firstOrNull?.id;
        } else if (accState.selectedBankId != null) {
          final matched = accState.accounts.where((a) => a.bankId == accState.selectedBankId).toList();
          if (matched.isNotEmpty) {
            _selectedAccountId = matched.first.id;
          }
        }
        _selectedAccountId ??= accState.accounts.first.id;
      }
    }

    if (_selectedTargetAccountId == null) {
      final accState = context.read<AccountCubit>().state;
      if (accState.accounts.length > 1) {
        final otherAccs = accState.accounts.where((a) => a.id != _selectedAccountId).toList();
        if (otherAccs.isNotEmpty) {
          _selectedTargetAccountId = otherAccs.first.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _amountController.removeListener(_onAmountChanged);
    _amountFocusNode.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {
        _hasUserManuallyUnlinked = false;
      });
    }
  }

  void _onTitleChanged() {
    if (_hasUserManuallySelectedCategory) return;
    if (_selectedType == TransactionType.transfer) return;

    final text = _titleController.text.trim().toLowerCase();
    if (text.isEmpty) {
      if (_dogAutoSuggestedCategoryName != null && mounted) {
        setState(() {
          _dogAutoSuggestedCategoryName = null;
        });
      }
      return;
    }

    String? matchedCatId;

    if (_selectedType == TransactionType.expense) {
      if (text.contains('7-11') || text.contains('711') || text.contains('เซเว่น') ||
          text.contains('grab') || text.contains('lineman') || text.contains('foodpanda') ||
          text.contains('shopeefood') || text.contains('cafe') || text.contains('คาเฟ่') ||
          text.contains('กาแฟ') || text.contains('ชาตรามือ') || text.contains('starbucks') ||
          text.contains('amazon') || text.contains('ข้าว') || text.contains('ก๋วยเตี๋ยว') ||
          text.contains('อาหาร') || text.contains('หมูกระทะ') || text.contains('kfc') ||
          text.contains('mcdonald') || text.contains('พิซซ่า') || text.contains('sushi') ||
          text.contains('mk') || text.contains('ชาบู') || text.contains('ชานม') ||
          text.contains('ขนม') || text.contains('ส้มตำ') || text.contains('บุฟเฟต์') ||
          text.contains('น้ำดื่ม') || text.contains('เครื่องดื่ม')) {
        matchedCatId = 'food';
      } else if (text.contains('bts') || text.contains('mrt') || text.contains('taxi') ||
          text.contains('แท็กซี่') || text.contains('bolt') || text.contains('ทางด่วน') ||
          text.contains('easy pass') || text.contains('น้ำมัน') || text.contains('ptt') ||
          text.contains('บางจาก') || text.contains('shell') || text.contains('caltex') ||
          text.contains('esso') || text.contains('วิน') || text.contains('รถเมล์') ||
          text.contains('เครื่องบิน') || text.contains('airasia') || text.contains('vietjet') ||
          text.contains('nokair') || text.contains('ที่จอดรถ') || text.contains('ค่าจอด') ||
          text.contains('ล้างรถ') || text.contains('ตั๋วรถ')) {
        matchedCatId = 'transport';
      } else if (text.contains('ค่าน้ำ') || text.contains('ค่าไฟ') || text.contains('ais') ||
          text.contains('true') || text.contains('dtac') || text.contains('เน็ตบ้าน') ||
          text.contains('ค่าเน็ต') || text.contains('netflix') || text.contains('spotify') ||
          text.contains('youtube') || text.contains('ค่าห้อง') || text.contains('ค่าคอนโด') ||
          text.contains('ค่าเช่า') || text.contains('ค่าส่วนกลาง')) {
        matchedCatId = 'bills';
      } else if (text.contains('บัตรเครดิต') || text.contains('งวดรถ') || text.contains('ผ่อนบ้าน') ||
          text.contains('หนี้') || text.contains('กู้') || text.contains('ดอกเบี้ย') ||
          text.contains('ผ่อน')) {
        matchedCatId = 'debts';
      } else if (text.contains('shopee') || text.contains('lazada') || text.contains('tiktok') ||
          text.contains('uniqlo') || text.contains('zara') || text.contains('h&m') ||
          text.contains('muji') || text.contains('ikea') || text.contains('eveandboy') ||
          text.contains('watsons') || text.contains('boots') || text.contains('เสื้อผ้า') ||
          text.contains('รองเท้า') || text.contains('ของเล่น') || text.contains('ช้อป') ||
          text.contains('กระเป๋า') || text.contains('เครื่องสำอาง')) {
        matchedCatId = 'shopping';
      } else if (text.contains('หนัง') || text.contains('major') || text.contains('sf cinema') ||
          text.contains('เกม') || text.contains('steam') || text.contains('playstation') ||
          text.contains('nintendo') || text.contains('เที่ยว') || text.contains('คอนเสิร์ต') ||
          text.contains('โรงแรม') || text.contains('รีสอร์ท')) {
        matchedCatId = 'entertainment';
      } else if (text.contains('ยา') || text.contains('หมอ') || text.contains('คลินิก') ||
          text.contains('โรงพยาบาล') || text.contains('ฟัน') || text.contains('ทำฟัน') ||
          text.contains('วิตามิน') || text.contains('ฟิตเนส') || text.contains('ตรวจสุขภาพ')) {
        matchedCatId = 'health';
      } else if (text.contains('ออม') || text.contains('กองทุน') || text.contains('หุ้น') ||
          text.contains('crypto') || text.contains('บิตคอยน์') || text.contains('สลาก') ||
          text.contains('ทอง')) {
        matchedCatId = 'savings';
      }
    } else if (_selectedType == TransactionType.income) {
      if (text.contains('เงินเดือน') || text.contains('salary') || text.contains('ค่าจ้าง') ||
          text.contains('เบี้ยเลี้ยง') || text.contains('โอที') || text.contains('ot')) {
        matchedCatId = 'salary';
      } else if (text.contains('โบนัส') || text.contains('bonus') || text.contains('คอมมิชชัน') ||
          text.contains('รางวัล') || text.contains('ถูกหวย') || text.contains('แต๊ะเอีย') ||
          text.contains('อั่งเปา')) {
        matchedCatId = 'bonus';
      } else if (text.contains('ปันผล') || text.contains('ดอกเบี้ย') || text.contains('กำไร') ||
          text.contains('ขายหุ้น') || text.contains('dividend')) {
        matchedCatId = 'investment';
      } else if (text.contains('ขายของ') || text.contains('ยอดขาย') || text.contains('ฟรีแลนซ์') ||
          text.contains('freelance') || text.contains('รับจ้าง') || text.contains('ลูกค้า')) {
        matchedCatId = 'business';
      }
    }

    if (matchedCatId != null) {
      final categories = _selectedType == TransactionType.expense
          ? AppConstants.defaultExpenseCategories
          : AppConstants.defaultIncomeCategories;
      final found = categories.where((c) => c.id == matchedCatId).firstOrNull;
      if (found != null && found.id != _selectedCategory.id) {
        DogSoundHelper.playBark();
        setState(() {
          _selectedCategory = found;
          _dogAutoSuggestedCategoryName = found.name;
        });
      }
    }
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      _hasUserManuallySelectedCategory = false;
      _dogAutoSuggestedCategoryName = null;
      if (type == TransactionType.transfer) {
        _selectedCategory = const CategoryItem(
          id: 'transfer',
          name: 'โอนย้ายเงิน',
          iconCode: 0xe8d4,
          colorValue: 0xFF6366F1,
        );
        final accState = context.read<AccountCubit>().state;
        if (_selectedTargetAccountId == null || _selectedTargetAccountId == _selectedAccountId) {
          final otherAccs = accState.accounts.where((a) => a.id != _selectedAccountId).toList();
          if (otherAccs.isNotEmpty) {
            _selectedTargetAccountId = otherAccs.first.id;
          }
        }
      } else {
        final categories = type == TransactionType.expense
            ? AppConstants.defaultExpenseCategories
            : AppConstants.defaultIncomeCategories;
        _selectedCategory = categories.first;
      }
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

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
      final id = widget.existingTransaction?.id ?? const Uuid().v4();

      final enteredTitle = _titleController.text.trim();
      final isTransferMode = _selectedType == TransactionType.transfer || _selectedCategory.id == 'transfer';
      final finalType = isTransferMode ? TransactionType.transfer : _selectedType;

      final accState = context.read<AccountCubit>().state;
      final matchedAcc = accState.accounts.where((a) => a.id == _selectedAccountId).toList();
      final selectedAcc = matchedAcc.isNotEmpty ? matchedAcc.first : (accState.accounts.isNotEmpty ? accState.accounts.first : null);

      final matchedTargetAcc = isTransferMode
          ? accState.accounts.where((a) => a.id == _selectedTargetAccountId).toList()
          : <BankAccountEntity>[];
      final selectedTargetAcc = matchedTargetAcc.isNotEmpty
          ? matchedTargetAcc.first
          : (accState.accounts.where((a) => a.id != selectedAcc?.id).isNotEmpty
              ? accState.accounts.where((a) => a.id != selectedAcc?.id).first
              : null);

      if (isTransferMode && accState.accounts.length > 1 && selectedAcc?.id == selectedTargetAcc?.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกบัญชีต้นทางและปลายทางให้ไม่ซ้ำกัน')),
        );
        return;
      }

      String finalTitle = enteredTitle.isNotEmpty ? enteredTitle : _selectedCategory.name;
      if (isTransferMode && enteredTitle.isEmpty && selectedAcc != null && selectedTargetAcc != null) {
        finalTitle = 'โอนย้าย: ${selectedAcc.shortName} ➜ ${selectedTargetAcc.shortName}';
      }

      final targetAccId = isTransferMode
          ? (_autoCreateTargetIncome || _matchedTargetTransactionId != null
              ? (selectedTargetAcc?.id ?? _selectedTargetAccountId)
              : null)
          : null;

      final transaction = TransactionEntity(
        id: id,
        title: finalTitle,
        amount: amount,
        type: finalType,
        categoryId: isTransferMode ? 'transfer' : _selectedCategory.id,
        categoryName: isTransferMode ? 'โอนย้ายเงิน' : _selectedCategory.name,
        categoryIconCode: isTransferMode ? 0xe8d4 : _selectedCategory.iconCode,
        categoryColorValue: isTransferMode ? 0xFF6366F1 : _selectedCategory.colorValue,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        bankId: selectedAcc?.bankId ?? widget.existingTransaction?.bankId,
        bankAccountId: selectedAcc?.id ?? widget.existingTransaction?.bankAccountId,
        bankShortName: selectedAcc?.shortName ?? widget.existingTransaction?.bankShortName,
        accountMask: selectedAcc?.accountMask ?? widget.existingTransaction?.accountMask,
        targetAccountId: targetAccId,
      );

      final cubit = context.read<TransactionCubit>();
      final accountCubit = context.read<AccountCubit>();

      // 1. If matched with an existing incoming transaction on the target bank, remove duplicate
      if (isTransferMode && _matchedTargetTransactionId != null) {
        await cubit.deleteTransaction(_matchedTargetTransactionId!);
      }

      // 2. Save current transaction
      if (widget.existingTransaction != null) {
        await cubit.updateTransaction(transaction);
      } else {
        await cubit.addTransaction(transaction);
      }

      // 3. Recalculate balances with the updated transactions list
      await accountCubit.refreshBalancesFromTransactions(cubit.state.transactions);

      if (mounted) {
        DogSoundHelper.playHappyBark();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🐾 ', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Text(
                    widget.existingTransaction != null
                        ? 'แก้ไขเรียบร้อย! เจ้าตูบอัปเดตข้อมูลให้แล้วนะโฮ่ง'
                        : (isTransferMode
                            ? 'ย้ายเงินเรียบร้อย! เจ้าตูบปรับยอดให้ทั้งสองบัญชีแล้วนะโฮ่ง'
                            : 'บันทึกเรียบร้อย! เจ้าตูบจดลงสมุดให้แล้วนะโฮ่ง 🦴'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF0F172A),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // Show Category Picker Bottom Sheet (Compact Grid)
  void _showCategoryPickerSheet(BuildContext context, bool isDark) {
    final categories = _selectedType == TransactionType.expense
        ? AppConstants.defaultExpenseCategories
        : AppConstants.defaultIncomeCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: isDark ? Border.all(color: AppColors.darkBorderSubtle, width: 1) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกหมวดหมู่ (${_selectedType == TransactionType.income ? "รายรับ" : "รายจ่าย"})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 82,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = cat.id == _selectedCategory.id;

                    return GestureDetector(
                      onTap: () {
                        final isTransfer = cat.id == 'transfer';
                        setState(() {
                          _selectedCategory = cat;
                          _hasUserManuallySelectedCategory = true;
                          _dogAutoSuggestedCategoryName = null;
                          if (isTransfer) {
                            _selectedType = TransactionType.transfer;
                            final accState = context.read<AccountCubit>().state;
                            if (_selectedTargetAccountId == null || _selectedTargetAccountId == _selectedAccountId) {
                              final otherAccs = accState.accounts.where((a) => a.id != _selectedAccountId).toList();
                              if (otherAccs.isNotEmpty) {
                                _selectedTargetAccountId = otherAccs.first.id;
                              }
                            }
                          }
                        });
                        Navigator.pop(ctx);
                        if (isTransfer) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) {
                              _showTargetAccountPickerSheet(context, isDark);
                            }
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: isDark ? 0.25 : 0.14)
                              : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? cat.color : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2.0 : 1,
                          ),
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
                                    size: 34,
                                    iconSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 11,
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
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Account Picker Bottom Sheet (Compact List)
  void _showAccountPickerSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocBuilder<AccountCubit, AccountState>(
          builder: (context, accState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.70,
              ),
              padding: EdgeInsets.only(
                top: 12,
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: isDark ? Border.all(color: AppColors.darkBorderSubtle, width: 1) : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เลือกบัญชี / กระเป๋าเงิน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: accState.accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final acc = accState.accounts[idx];
                        final isAccSelected = _selectedAccountId == acc.id;
                        final brandCol = Color(acc.brandColor);

                        return InkWell(
                          onTap: () {
                            setState(() => _selectedAccountId = acc.id);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isAccSelected
                                  ? brandCol.withValues(alpha: isDark ? 0.22 : 0.12)
                                  : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isAccSelected
                                    ? brandCol
                                    : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                                width: isAccSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: brandCol,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      acc.logoAsset,
                                      cacheWidth: 96,
                                      cacheHeight: 96,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.account_balance,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.accountName.isNotEmpty ? acc.accountName : acc.bankName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        acc.accountMask != null
                                            ? '${acc.shortName} • ${acc.accountMask}'
                                            : acc.shortName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isAccSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isAccSelected
                                      ? brandCol
                                      : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show Target Account Picker Bottom Sheet for Transfer
  void _showTargetAccountPickerSheet(BuildContext context, bool isDark) {
    final accState = context.read<AccountCubit>().state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          padding: EdgeInsets.only(
            top: 14,
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกบัญชีปลายทาง (รับเงินเข้า)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: accState.accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final acc = accState.accounts[idx];
                    final isSource = _selectedAccountId == acc.id;
                    final isAccSelected = _selectedTargetAccountId == acc.id;
                    final brandCol = Color(acc.brandColor);

                    return InkWell(
                      onTap: isSource
                          ? null
                          : () {
                              setState(() => _selectedTargetAccountId = acc.id);
                              Navigator.pop(ctx);
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Opacity(
                        opacity: isSource ? 0.45 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAccSelected
                                ? brandCol.withValues(alpha: isDark ? 0.22 : 0.12)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                            border: isAccSelected
                                ? Border.all(color: brandCol, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: brandCol,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    acc.logoAsset,
                                    cacheWidth: 96,
                                    cacheHeight: 96,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.account_balance,
                                      color: Colors.white,
                                      size: 18,
                                    ),
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
                                            acc.accountName.isNotEmpty ? acc.accountName : acc.bankName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSource) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'บัญชีต้นทาง',
                                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      acc.accountMask != null
                                          ? '${acc.shortName} • ${acc.accountMask}'
                                          : acc.shortName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isAccSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 18,
                                color: isAccSelected
                                    ? brandCol
                                    : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TransactionEntity> _getMatchingTargetTransactions(
    List<TransactionEntity> allTransactions,
    BankAccountEntity? targetAccount,
  ) {
    if (targetAccount == null) return [];
    final rawAmount = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount) ?? 0.0;
    if (amount <= 0) return [];

    final existingId = widget.existingTransaction?.id;
    final List<TransactionEntity> result = [];
    for (final t in allTransactions) {
      if (t.id == existingId) continue;
      final tBankId = (t.bankAccountId ?? t.bankId ?? '').toLowerCase();
      final targetAccId = targetAccount.id.toLowerCase();
      final targetBankId = targetAccount.bankId.toLowerCase();

      final isTargetMatch = t.bankAccountId == targetAccount.id ||
          t.bankId == targetAccount.bankId ||
          (tBankId.isNotEmpty &&
              (tBankId.contains(targetAccId) ||
                  tBankId.contains(targetBankId) ||
                  targetAccId.contains(tBankId)));
      if (!isTargetMatch) continue;

      final isAmountMatch = (t.amount - amount).abs() < 0.01;
      if (!isAmountMatch) continue;

      final isIncomeCandidate = t.isIncome || (!t.isTransfer && t.isUnknownCategory);
      if (!isIncomeCandidate) continue;

      final dayDiff = t.date.difference(_selectedDate).inDays.abs();
      if (dayDiff <= 5) {
        result.add(t);
      }
    }
    return result;
  }

  void _showMatchCandidatePickerSheet(
    BuildContext context,
    bool isDark,
    List<TransactionEntity> candidates,
    BankAccountEntity targetAcc,
  ) {
    final fmt = NumberFormat('#,##0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          padding: EdgeInsets.only(
            top: 14,
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกรายการเงินเข้าใน ${targetAcc.shortName}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    if (idx == candidates.length) {
                      final isSelected = _matchedTargetTransactionId == null;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _matchedTargetTransactionId = null;
                            _hasUserManuallyUnlinked = true;
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.22 : 0.12)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF6366F1)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ไม่จับคู่ (สร้างรายการใหม่ไปยังปลายทาง)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 18,
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final candidate = candidates[idx];
                    final isSelected = _matchedTargetTransactionId == candidate.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _matchedTargetTransactionId = candidate.id;
                          _hasUserManuallyUnlinked = false;
                        });
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withValues(alpha: isDark ? 0.22 : 0.12)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate.title.isNotEmpty ? candidate.title : 'เงินเข้า',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatDateTime(candidate.date),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+฿${fmt.format(candidate.amount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransferMatchingWidget(
    BuildContext context,
    bool isDark,
    BankAccountEntity? targetAcc,
  ) {
    if (targetAcc == null) return const SizedBox.shrink();

    final txState = context.watch<TransactionCubit>().state;
    final candidates = _getMatchingTargetTransactions(txState.transactions, targetAcc);

    if (candidates.isNotEmpty && !_hasUserManuallyUnlinked) {
      if (_matchedTargetTransactionId == null ||
          !candidates.any((c) => c.id == _matchedTargetTransactionId)) {
        _matchedTargetTransactionId = candidates.first.id;
      }
    }

    final isAnyMatched = _matchedTargetTransactionId != null &&
        candidates.any((c) => c.id == _matchedTargetTransactionId);

    final fmt = NumberFormat('#,##0.00');

    // Case 1: Matching candidates found in target account!
    if (candidates.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.40 : 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title with Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    candidates.length == 1
                        ? 'ตรวจพบยอดเงินเข้าใน ${targetAcc.shortName}!'
                        : 'ตรวจพบยอดเงินเข้าใน ${targetAcc.shortName} (${candidates.length} รายการ):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Render ALL candidate options directly on screen
            for (int i = 0; i < candidates.length; i++) ...[
              () {
                final candidate = candidates[i];
                final isSelected = _matchedTargetTransactionId == candidate.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _matchedTargetTransactionId = candidate.id;
                      _hasUserManuallyUnlinked = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.6) : Colors.white)
                          : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 16,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                            ),
                            const SizedBox(width: 8),
                            BankLogoBadge(
                              bankId: targetAcc.bankId,
                              fallbackShortName: targetAcc.shortName,
                              size: 20,
                              borderRadius: 6,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate.title.isNotEmpty
                                        ? candidate.title
                                        : 'เงินเข้า ${targetAcc.shortName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormatter.formatDateTime(candidate.date),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+฿${fmt.format(candidate.amount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.income,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            '• จับคู่และรวมยอด (ลบรายการเงินเข้าเดิมออกเพื่อป้องกันยอดใน ${targetAcc.shortName} ซ้ำ)',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }(),
            ],

            // Option: Do not combine (Create new)
            InkWell(
              onTap: () {
                setState(() {
                  _matchedTargetTransactionId = null;
                  _hasUserManuallyUnlinked = true;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: !isAnyMatched
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.3) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isAnyMatched
                        ? const Color(0xFF6366F1)
                        : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                    width: !isAnyMatched ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      !isAnyMatched ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16,
                      color: !isAnyMatched
                          ? const Color(0xFF6366F1)
                          : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไม่รวมรายการ (สร้างรายการใหม่ไปยัง ${targetAcc.shortName})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: No match candidate found -> Show clean auto-create option
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 16,
            color: _autoCreateTargetIncome
                ? const Color(0xFF10B981)
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ปรับยอดเงินเข้า ${targetAcc.shortName} อัตโนมัติ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _autoCreateTargetIncome
                      ? 'คำนวณยอดคงเหลือของทั้งสองบัญชีให้ตรงกัน'
                      : 'บันทึกเฉพาะยอดโอนออกจากต้นทาง',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch.adaptive(
              value: _autoCreateTargetIncome,
              activeColor: const Color(0xFF10B981),
              onChanged: (val) => setState(() => _autoCreateTargetIncome = val),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryThemeColor = _selectedType == TransactionType.income
        ? AppColors.income
        : (_selectedType == TransactionType.transfer
            ? const Color(0xFF6366F1)
            : AppColors.expense);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset > 0
            ? bottomInset + 6
            : (14 + MediaQuery.of(context).padding.bottom),
        left: 14,
        right: 14,
        top: 8,
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
            // Top Bar: Drag Handle
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
            const SizedBox(height: 6),

            // Header Row: Close Button / Title / Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.existingTransaction != null ? 'แก้ไขรายการ' : 'บันทึกรายการ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                ),
                if (widget.existingTransaction != null)
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
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 8),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Strip (Compact)
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: primaryThemeColor),
                            const SizedBox(width: 6),
                            Text(
                              'วันที่: ${DateFormatter.formatRelative(_selectedDate)} (${DateFormatter.formatTimeShort(_selectedDate)} น.)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Type Switcher Row (Equal Width 3 Tabs - รายจ่าย, รายรับ, โอนย้าย)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypePill(
                              type: TransactionType.expense,
                              label: 'รายจ่าย',
                              icon: Icons.arrow_upward_rounded,
                              color: AppColors.expense,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypePill(
                              type: TransactionType.income,
                              label: 'รายรับ',
                              icon: Icons.arrow_downward_rounded,
                              color: AppColors.income,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypePill(
                              type: TransactionType.transfer,
                              label: 'โอนย้าย',
                              icon: Icons.swap_horiz_rounded,
                              color: const Color(0xFF6366F1),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Card 1: Amount Hero Input (Compact)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryThemeColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _selectedType == TransactionType.income
                                  ? Icons.arrow_downward_rounded
                                  : (_selectedType == TransactionType.transfer
                                      ? Icons.swap_horiz_rounded
                                      : Icons.arrow_upward_rounded),
                              color: primaryThemeColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '฿',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryThemeColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              autofocus: widget.existingTransaction == null,
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
                    const SizedBox(height: 8),

                    // Card 2: Category Selector Row (Hidden in Transfer mode)
                    if (_selectedType != TransactionType.transfer) ...[
                      InkWell(
                        onTap: () => _showCategoryPickerSheet(context, isDark),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Image.asset(
                                  _selectedCategory.imageAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => CategoryIconBadge(
                                    icon: _selectedCategory.icon,
                                    color: _selectedCategory.color,
                                    size: 28,
                                    iconSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'หมวดหมู่',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      _selectedCategory.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Card 3: Account Selector Row (บัญชีต้นทาง & บัญชีปลายทาง)
                    BlocBuilder<AccountCubit, AccountState>(
                      builder: (context, accState) {
                        final isTransferMode = _selectedType == TransactionType.transfer || _selectedCategory.id == 'transfer';
                        final matchedAcc = accState.accounts.where((a) => a.id == _selectedAccountId).toList();
                        final selectedAcc = matchedAcc.isNotEmpty
                            ? matchedAcc.first
                            : (accState.accounts.isNotEmpty ? accState.accounts.first : null);

                        final matchedTargetAcc = isTransferMode
                            ? accState.accounts.where((a) => a.id == _selectedTargetAccountId).toList()
                            : <BankAccountEntity>[];
                        final selectedTargetAcc = matchedTargetAcc.isNotEmpty
                            ? matchedTargetAcc.first
                            : (accState.accounts.where((a) => a.id != selectedAcc?.id).isNotEmpty
                                ? accState.accounts.where((a) => a.id != selectedAcc?.id).first
                                : null);

                        if (isTransferMode) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  // Source Account (Left)
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showAccountPickerSheet(context, isDark),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            if (selectedAcc != null) ...[
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: Color(selectedAcc.brandColor),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    selectedAcc.logoAsset,
                                                    cacheWidth: 78,
                                                    cacheHeight: 78,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.account_balance,
                                                      color: Colors.white,
                                                      size: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'ต้นทาง (ออก)',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                    Text(
                                                      selectedAcc.shortName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                              const SizedBox(width: 6),
                                              const Expanded(
                                                child: Text(
                                                  'เลือกต้นทาง',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Arrow Middle Indicator
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                  // Target Account (Right)
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showTargetAccountPickerSheet(context, isDark),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            if (selectedTargetAcc != null) ...[
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  color: Color(selectedTargetAcc.brandColor),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    selectedTargetAcc.logoAsset,
                                                    cacheWidth: 78,
                                                    cacheHeight: 78,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.account_balance,
                                                      color: Colors.white,
                                                      size: 13,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'ปลายทาง (เข้า)',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                    Text(
                                                      selectedTargetAcc.shortName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                              const SizedBox(width: 6),
                                              const Expanded(
                                                child: Text(
                                                  'เลือกปลายทาง',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              _buildTransferMatchingWidget(context, isDark, selectedTargetAcc),
                            ],
                          );
                        }

                        // Normal full-width account selector
                        return InkWell(
                          onTap: () => _showAccountPickerSheet(context, isDark),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                if (selectedAcc != null) ...[
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(selectedAcc.brandColor),
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        selectedAcc.logoAsset,
                                        cacheWidth: 84,
                                        cacheHeight: 84,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.account_balance,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'บัญชี / กระเป๋าเงิน',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        Text(
                                          selectedAcc.accountMask != null
                                              ? '${selectedAcc.shortName} • ${selectedAcc.accountMask}'
                                              : selectedAcc.shortName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'เลือกบัญชี / กระเป๋าเงิน',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Card 4: Title & Notes (Compact)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                          if (_dogAutoSuggestedCategoryName != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🐾', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'เจ้าตูบช่วยเลือกหมวด "$_dogAutoSuggestedCategoryName" ให้แล้วนะโฮ่ง!',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (!_showMoreOptions)
                            GestureDetector(
                              onTap: () => setState(() => _showMoreOptions = true),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 14, color: primaryThemeColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'เพิ่มโน้ตช่วยจำ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryThemeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            const Divider(height: 12, thickness: 0.6),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sticky Bottom Prominent Save Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _onSubmit,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  widget.existingTransaction != null ? 'บันทึกการแก้ไข' : 'บันทึกรายการ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryThemeColor,
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
