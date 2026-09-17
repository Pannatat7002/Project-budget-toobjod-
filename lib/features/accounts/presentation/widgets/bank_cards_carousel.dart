import 'package:flutter/material.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'bank_card_item.dart';

class BankCardsCarousel extends StatefulWidget {
  final List<BankAccountEntity> accounts;
  final String? selectedBankId; // null = All Wallets
  final double totalBalance;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final double Function(String? bankId) getBankBalance;
  final double Function(String? bankId) getBankIncome;
  final double Function(String? bankId) getBankExpense;
  final bool isEyeViewHidden;
  final VoidCallback onToggleEyeView;
  final ValueChanged<String?> onBankSelected;
  final VoidCallback? onAddBankTap;
  final PageController? externalPageController;

  const BankCardsCarousel({
    super.key,
    required this.accounts,
    this.selectedBankId,
    required this.totalBalance,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.getBankBalance,
    required this.getBankIncome,
    required this.getBankExpense,
    required this.isEyeViewHidden,
    required this.onToggleEyeView,
    required this.onBankSelected,
    this.onAddBankTap,
    this.externalPageController,
  });

  @override
  State<BankCardsCarousel> createState() => _BankCardsCarouselState();
}

class _BankCardsCarouselState extends State<BankCardsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController =
        widget.externalPageController ??
        PageController(viewportFraction: 0.985, initialPage: _getInitialPage());
  }

  int _getInitialPage() {
    if (widget.selectedBankId == null) return 0;
    final idx = widget.accounts.indexWhere(
      (a) => a.bankId == widget.selectedBankId,
    );
    return idx != -1 ? idx + 1 : 0;
  }

  @override
  void didUpdateWidget(covariant BankCardsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBankId != widget.selectedBankId) {
      final targetPage = _getInitialPage();
      if (_pageController.hasClients && _currentPage != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    if (widget.externalPageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Total items = 1 (All Wallets) + accounts.length (No extra Add Card)
    final totalCount = 1 + widget.accounts.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            itemCount: totalCount,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // Guard: only call onBankSelected if the bank actually changed
              if (index == 0) {
                if (widget.selectedBankId != null) {
                  widget.onBankSelected(null); // All Wallets
                }
              } else if (index <= widget.accounts.length) {
                final acc = widget.accounts[index - 1];
                if (widget.selectedBankId != acc.bankId) {
                  widget.onBankSelected(acc.bankId);
                }
              }
            },
            itemBuilder: (context, index) {
              // 1. Index 0: Net Worth / All Wallets
              if (index == 0) {
                return BankCardItem(
                  account: null,
                  balance: widget.totalBalance,
                  monthlyIncome: widget.totalMonthlyIncome,
                  monthlyExpense: widget.totalMonthlyExpense,
                  isEyeViewHidden: widget.isEyeViewHidden,
                  onToggleEyeView: widget.onToggleEyeView,
                  isSelected: widget.selectedBankId == null,
                );
              }

              // 2. Index 1..N: Individual Bank Accounts
              final acc = widget.accounts[index - 1];
              final bal = widget.getBankBalance(acc.bankId);
              final inc = widget.getBankIncome(acc.bankId);
              final exp = widget.getBankExpense(acc.bankId);

              return BankCardItem(
                account: acc,
                balance: bal,
                monthlyIncome: inc,
                monthlyExpense: exp,
                isEyeViewHidden: widget.isEyeViewHidden,
                onToggleEyeView: widget.onToggleEyeView,
                isSelected: widget.selectedBankId == acc.bankId,
              );
            },
          ),
        ),
        if (totalCount > 1) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCount, (idx) {
              final isCurrent = _currentPage == idx;
              final dist = (idx - _currentPage).abs();

              double dotWidth = isCurrent ? 16 : 5.5;
              double dotHeight = isCurrent ? 5 : 4.5;
              double opacity = 1.0;

              if (totalCount > 5 && !isCurrent) {
                if (dist == 1) {
                  dotWidth = 5.5;
                  dotHeight = 4.5;
                } else if (dist == 2) {
                  dotWidth = 4;
                  dotHeight = 3.5;
                  opacity = 0.7;
                } else {
                  dotWidth = 3;
                  dotHeight = 2.5;
                  opacity = 0.35;
                }
              }

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: dotWidth,
                  height: dotHeight,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (isDark
                              ? const Color(0xFFF97316)
                              : const Color(0xFFEA580C))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.25 * opacity)
                              : Colors.black.withValues(alpha: 0.15 * opacity)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 10),

        // Inflow / Outflow Section (below carousel)
        Builder(
          builder: (context) {
            final isDarkSection = Theme.of(context).brightness == Brightness.dark;
            final income = _currentPage == 0
                ? widget.totalMonthlyIncome
                : (_currentPage <= widget.accounts.length
                    ? widget.getBankIncome(widget.accounts[_currentPage - 1].bankId)
                    : 0.0);
            final expense = _currentPage == 0
                ? widget.totalMonthlyExpense
                : (_currentPage <= widget.accounts.length
                    ? widget.getBankExpense(widget.accounts[_currentPage - 1].bankId)
                    : 0.0);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkSection ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDarkSection ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // เข้า (Inflow) — Royal Blue
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: isDarkSection ? 0.15 : 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            color: AppColors.accent,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'เข้า',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDarkSection
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              widget.isEyeViewHidden
                                  ? '••••'
                                  : CurrencyFormatter.format(income),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDarkSection
                                    ? AppColors.accentLight
                                    : AppColors.accent,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 28,
                    color: isDarkSection
                        ? AppColors.darkBorderSubtle
                        : AppColors.lightBorder,
                  ),

                  // ออก (Outflow) — Shiba Orange
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ออก',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDarkSection
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              widget.isEyeViewHidden
                                  ? '••••'
                                  : CurrencyFormatter.format(expense),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDarkSection
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDarkSection ? 0.15 : 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: AppColors.primary,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
