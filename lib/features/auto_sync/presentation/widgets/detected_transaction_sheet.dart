import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/detected_transaction.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import 'bank_logo_badge.dart';

class DetectedTransactionSheet extends StatefulWidget {
  final DetectedTransaction? initialTransaction;
  final Function(TransactionEntity entity)? onConfirm;
  final VoidCallback? onDiscard;
  final VoidCallback? onDismiss;

  const DetectedTransactionSheet({
    super.key,
    this.initialTransaction,
    this.onConfirm,
    this.onDiscard,
    this.onDismiss,
  });

  static bool isShowing = false;

  static Future<void> show(
    BuildContext context, {
    DetectedTransaction? transaction,
    Function(TransactionEntity entity)? onConfirm,
    VoidCallback? onDiscard,
    VoidCallback? onDismiss,
  }) async {
    if (isShowing) return; // Prevent duplicate overlapping dialogs

    isShowing = true;
    try {
      await showGeneralDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        barrierLabel: 'AI Detected Transaction Bubble',
        barrierColor: Colors.black26,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, anim1, anim2) => DetectedTransactionSheet(
          initialTransaction: transaction,
          onConfirm: onConfirm,
          onDiscard: onDiscard,
          onDismiss: onDismiss,
        ),
        transitionBuilder: (ctx, anim1, anim2, child) {
          final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[DetectedTransactionSheet] Dialog display error: $e');
    } finally {
      isShowing = false;
    }
  }

  @override
  State<DetectedTransactionSheet> createState() => _DetectedTransactionSheetState();
}

class _DetectedTransactionSheetState extends State<DetectedTransactionSheet> {
  int _currentIndex = 0;
  String? _currentTxId;
  bool _isClosed = false;
  DetectedTransaction? _lastRenderedTx;

  late TextEditingController _titleController;
  late TransactionType _type;
  late String _categoryId;
  late String _categoryName;
  late int _categoryIconCode;
  late int _categoryColorValue;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    if (widget.initialTransaction != null) {
      _loadTransactionData(widget.initialTransaction!);
    } else {
      _type = TransactionType.expense;
      _categoryId = 'other';
      _categoryName = 'อื่นๆ';
      _categoryIconCode = Icons.category_rounded.codePoint;
      _categoryColorValue = AppColors.primary.toARGB32();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _safeCloseDialog() {
    if (_isClosed) return;
    _isClosed = true;
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  void _loadTransactionData(DetectedTransaction tx) {
    _currentTxId = tx.id;
    _lastRenderedTx = tx;
    _titleController.text = tx.title;
    _type = tx.type;
    _categoryId = tx.suggestedCategoryId;
    _categoryName = tx.suggestedCategoryName;
    _categoryIconCode = tx.suggestedCategoryIconCode;
    _categoryColorValue = tx.suggestedCategoryColorValue;
  }

  List<CategoryItem> get _currentCategories => _type == TransactionType.income
      ? AppConstants.defaultIncomeCategories
      : AppConstants.defaultExpenseCategories;

  void _onCategorySelected(CategoryItem category) {
    setState(() {
      _categoryId = category.id;
      _categoryName = category.name;
      _categoryIconCode = category.iconCode;
      _categoryColorValue = category.colorValue;
    });
  }

  /// User taps "✅ ถูกต้อง"
  void _handleConfirm(DetectedTransaction currentTx, int pendingCount) {
    final entity = TransactionEntity(
      id: currentTx.id,
      title: _titleController.text.trim().isEmpty ? currentTx.title : _titleController.text.trim(),
      amount: currentTx.amount,
      type: _type,
      categoryId: _categoryId,
      categoryName: _categoryName,
      categoryIconCode: _categoryIconCode,
      categoryColorValue: _categoryColorValue,
      date: currentTx.timestamp,
      note: currentTx.rawText,
      bankId: currentTx.bankId,
      bankAccountId: currentTx.bankAccountId,
      bankShortName: currentTx.bankShortName,
      accountMask: currentTx.accountMask,
    );

    context.read<AutoSyncCubit>().confirmTransaction(
          currentTx,
          customEntity: entity,
        );

    if (pendingCount <= 1) {
      _safeCloseDialog();
    } else {
      setState(() {
        if (_currentIndex >= pendingCount - 1) {
          _currentIndex = 0;
        }
      });
    }
  }

  /// User taps "❌ ไม่ถูกต้อง" -> Delete from database!
  void _handleDiscard(DetectedTransaction currentTx, int pendingCount) {
    context.read<AutoSyncCubit>().discardTransaction(currentTx);

    if (pendingCount <= 1) {
      _safeCloseDialog();
    } else {
      setState(() {
        if (_currentIndex >= pendingCount - 1) {
          _currentIndex = 0;
        }
      });
    }
  }

  /// User dismisses / closes X -> Keep auto-saved transaction
  void _handleDismiss(DetectedTransaction currentTx, int pendingCount) {
    context.read<AutoSyncCubit>().dismissReview(currentTx);

    if (pendingCount <= 1) {
      _safeCloseDialog();
    } else {
      setState(() {
        if (_currentIndex >= pendingCount - 1) {
          _currentIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkSurface : AppColors.lightBackground;

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return BlocBuilder<AutoSyncCubit, AutoSyncState>(
      builder: (context, state) {
        final pendingList = state.pendingTransactions.isNotEmpty
            ? state.pendingTransactions
            : (widget.initialTransaction != null ? [widget.initialTransaction!] : <DetectedTransaction>[]);

        if (pendingList.isEmpty) {
          if (!_isClosed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _safeCloseDialog();
            });
          }
        }

        // Clamp index
        if (_currentIndex >= pendingList.length && pendingList.isNotEmpty) {
          _currentIndex = pendingList.length - 1;
        }
        if (_currentIndex < 0) {
          _currentIndex = 0;
        }

        final currentTx = pendingList.isNotEmpty
            ? pendingList[_currentIndex]
            : (_lastRenderedTx ?? widget.initialTransaction);

        if (currentTx == null) {
          return const SizedBox.shrink();
        }

        // Sync local form state if id changed
        if (_currentTxId != currentTx.id) {
          _currentTxId = currentTx.id;
          _lastRenderedTx = currentTx;
          _titleController.text = currentTx.title;
          _type = currentTx.type;
          _categoryId = currentTx.suggestedCategoryId;
          _categoryName = currentTx.suggestedCategoryName;
          _categoryIconCode = currentTx.suggestedCategoryIconCode;
          _categoryColorValue = currentTx.suggestedCategoryColorValue;
        }

        final isIncome = _type == TransactionType.income;
        final typeColor = isIncome ? AppColors.income : AppColors.expense;
        final totalCount = pendingList.isNotEmpty ? pendingList.length : 1;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 92 + bottomSafe + viewInsetsBottom),
              child: RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Main Compact Speech Bubble Container
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: cardBorderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 60 : 15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header: Avatar + AI Name + Bank + Counter + Close (X)
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFF8A00), Color(0xFF38BDF8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(1.2),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/mascot_ai_dog_avatar.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Colors.white, size: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // AI Name
                              Text(
                                'ตูบจด AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.primaryLight : AppColors.primaryOrange,
                                ),
                              ),                              const SizedBox(width: 8),
                              // Bank Logo Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(currentTx.bankColorValue).withAlpha(isDark ? 45 : 20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(currentTx.bankColorValue).withAlpha(90),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BankLogoBadge(
                                      packageName: currentTx.packageName,
                                      fallbackShortName: currentTx.bankShortName,
                                      fallbackColorValue: currentTx.bankColorValue,
                                      size: 16,
                                      borderRadius: 4,
                                      showBorder: false,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentTx.bankShortName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(currentTx.bankColorValue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Multi-item counter (e.g. 1/3)
                              if (totalCount > 1) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(isDark ? 40 : 20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                                  ),
                                  child: Text(
                                    '${_currentIndex + 1}/$totalCount',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],

                              const Spacer(),

                              // Pagination Buttons
                              if (totalCount > 1) ...[
                                InkWell(
                                  onTap: _currentIndex > 0
                                      ? () => setState(() => _currentIndex--)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      size: 16,
                                      color: _currentIndex > 0 ? textColor : subtextColor.withAlpha(80),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _currentIndex < totalCount - 1
                                      ? () => setState(() => _currentIndex++)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: _currentIndex < totalCount - 1 ? textColor : subtextColor.withAlpha(80),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                              ],

                              // Time
                              Text(
                                '${DateFormatter.formatTime(currentTx.timestamp)} น.',
                                style: TextStyle(fontSize: 10, color: subtextColor),
                              ),
                              const SizedBox(width: 4),

                              // Close X button (Dismiss & keep auto-saved)
                              InkWell(
                                onTap: () => _handleDismiss(currentTx, totalCount),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: subtextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // 2. Compact Amount & Title Row
                          Row(
                            children: [
                              // Amount Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: typeColor.withAlpha(isDark ? 30 : 15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: typeColor.withAlpha(50)),
                                ),
                                child: Text(
                                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(currentTx.amount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: typeColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Title Input (ชื่อรายการจาก Notification Title)
                              Expanded(
                                child: Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorderColor),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: TextField(
                                    controller: _titleController,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintText: 'ชื่อรายการ / ร้านค้า',
                                      hintStyle: TextStyle(fontSize: 11.5, color: subtextColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // รายละเอียด (Text จาก Notification)
                          if (currentTx.rawText != null && currentTx.rawText!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currentTx.rawText!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subtextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),

                          // 3. Compact Category Selector (Mini chips)
                          SizedBox(
                            height: 30,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _currentCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 5),
                              itemBuilder: (context, index) {
                                final cat = _currentCategories[index];
                                final isSelected = cat.id == _categoryId;

                                return InkWell(
                                  onTap: () => _onCategorySelected(cat),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(cat.colorValue)
                                          : (isDark ? AppColors.darkSurface : AppColors.lightBorderSubtle),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? Color(cat.colorValue) : cardBorderColor,
                                        width: isSelected ? 1.2 : 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          cat.imageAsset,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            cat.icon,
                                            size: 12,
                                            color: isSelected ? Colors.white : Color(cat.colorValue),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? Colors.white : textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 4. Action Buttons: "❌ ไม่ถูกต้อง" vs "✅ ถูกต้อง"
                          Row(
                            children: [
                              // Left: "❌ ไม่ถูกต้อง" (Discard & delete from DB)
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () => _handleDiscard(currentTx, totalCount),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.expense,
                                    side: BorderSide(color: AppColors.expense.withAlpha(90), width: 1),
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    '❌ ไม่ถูกต้อง',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Right: "✅ ถูกต้อง" (Confirm & update)
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () => _handleConfirm(currentTx, totalCount),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.income,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    totalCount > 1 ? '✅ ถูกต้อง (${_currentIndex + 1}/$totalCount)' : '✅ ถูกต้อง',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Downward Pointer Tail
                    Positioned(
                      bottom: -7,
                      child: CustomPaint(
                        size: const Size(14, 8),
                        painter: _BubbleTailPainter(
                          color: cardBgColor,
                          borderColor: cardBorderColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _BubbleTailPainter({required this.color, required this.borderColor});

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
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
