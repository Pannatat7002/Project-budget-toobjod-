import 'package:flutter/material.dart';
import '../../domain/entities/bank_account_entity.dart';
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
    _pageController = widget.externalPageController ??
        PageController(viewportFraction: 0.96, initialPage: _getInitialPage());
  }

  int _getInitialPage() {
    if (widget.selectedBankId == null) return 0;
    final idx = widget.accounts.indexWhere((a) => a.bankId == widget.selectedBankId);
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
    // Total items = 1 (All Wallets) + accounts.length + 1 (Add Card)
    final totalCount = 1 + widget.accounts.length + 1;

    return SizedBox(
      height: 208,
      child: PageView.builder(
        controller: _pageController,
        clipBehavior: Clip.none,
        itemCount: totalCount,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          if (index == 0) {
            widget.onBankSelected(null); // All Wallets
          } else if (index <= widget.accounts.length) {
            final acc = widget.accounts[index - 1];
            widget.onBankSelected(acc.bankId);
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
          if (index <= widget.accounts.length) {
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
          }

          // 3. Last index: Add Account Card
          return BankCardItem(
            balance: 0,
            monthlyIncome: 0,
            monthlyExpense: 0,
            isEyeViewHidden: widget.isEyeViewHidden,
            onToggleEyeView: widget.onToggleEyeView,
            isAddAccountCard: true,
            onAddAccountTap: widget.onAddBankTap,
          );
        },
      ),
    );
  }
}
