import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/category_icon_badge.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../domain/entities/budget_entity.dart';
import '../state/budget_cubit.dart';

class SetBudgetDialog extends StatefulWidget {
  final BudgetEntity? existingBudget;

  const SetBudgetDialog({super.key, this.existingBudget});

  static Future<void> show(BuildContext context, {BudgetEntity? existingBudget}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<BudgetCubit>(),
        child: SetBudgetDialog(existingBudget: existingBudget),
      ),
    );
  }

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  late CategoryItem _selectedCategory;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBudget;
    _limitController = TextEditingController(
      text: existing != null ? existing.limitAmount.toStringAsFixed(0) : '',
    );

    if (existing != null) {
      _selectedCategory = AppConstants.defaultExpenseCategories.firstWhere(
        (c) => c.id == existing.categoryId,
        orElse: () => AppConstants.defaultExpenseCategories.first,
      );
    } else {
      _selectedCategory = AppConstants.defaultExpenseCategories.first;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _onCategorySelected(CategoryItem cat) {
    setState(() {
      _selectedCategory = cat;
      // When changing category, auto-sync limit if this category already has a budget set
      final budgets = context.read<BudgetCubit>().state.budgets;
      final existingCatBudget = budgets.cast<BudgetEntity?>().firstWhere(
        (b) => b?.categoryId == cat.id,
        orElse: () => null,
      );
      if (existingCatBudget != null) {
        _limitController.text = existingCatBudget.limitAmount.toStringAsFixed(0);
      } else if (widget.existingBudget == null) {
        _limitController.clear();
      }
    });
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final limit = double.tryParse(_limitController.text.replaceAll(',', '')) ?? 0.0;
      final budgets = context.read<BudgetCubit>().state.budgets;
      final existingCatBudget = budgets.cast<BudgetEntity?>().firstWhere(
        (b) => b?.categoryId == _selectedCategory.id,
        orElse: () => null,
      );
      final id = existingCatBudget?.id ?? widget.existingBudget?.id ?? const Uuid().v4();

      final budget = BudgetEntity(
        id: id,
        categoryId: _selectedCategory.id,
        categoryName: _selectedCategory.name,
        categoryIconCode: _selectedCategory.iconCode,
        categoryColorValue: _selectedCategory.colorValue,
        limitAmount: limit,
      );

      context.read<BudgetCubit>().setBudget(budget);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingBudget != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/action_budget.png',
                        width: 32,
                        height: 32,
                        cacheWidth: 96,
                        cacheHeight: 96,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEditing ? 'แก้ไขงบประมาณ' : 'ตั้งงบประมาณใหม่',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16),
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Picker Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกหมวดหมู่รายจ่าย',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                  ),
                  Text(
                    _selectedCategory.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedCategory.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Picker Grid (4 columns)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 86,
                ),
                itemCount: AppConstants.defaultExpenseCategories.length,
                itemBuilder: (context, index) {
                  final cat = AppConstants.defaultExpenseCategories[index];
                  final isSelected = cat.id == _selectedCategory.id;

                  return GestureDetector(
                    onTap: () => _onCategorySelected(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: isDark ? 0.22 : 0.12)
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
                                cacheWidth: 114,
                                cacheHeight: 114,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => CategoryIconBadge(
                                  icon: cat.icon,
                                  color: cat.color,
                                  size: 38,
                                  iconSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? cat.color : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
              const SizedBox(height: 18),

              // Limit Amount Input (Thai Baht Currency Only)
              CustomTextField(
                controller: _limitController,
                label: 'วงเงินงบประมาณ (บาท/เดือน)',
                hint: 'เช่น 5000',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                prefix: Container(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: const Text(
                    '฿',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'กรุณาระบุวงเงิน';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'วงเงินต้องมากกว่า 0';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Action Buttons
              CustomButton(
                text: isEditing ? 'บันทึกการแก้ไข' : 'ตั้งงบประมาณ',
                color: AppColors.primary,
                icon: Icons.check,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
