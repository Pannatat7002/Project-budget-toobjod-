import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/bank_account_entity.dart';

class BankCardItem extends StatelessWidget {
  final BankAccountEntity? account; // null = "ภาพรวมทุกบัญชี" (Net Worth)
  final double balance;
  final double monthlyIncome;
  final double monthlyExpense;
  final bool isEyeViewHidden;
  final VoidCallback onToggleEyeView;
  final bool isSelected;
  final bool isAddAccountCard;
  final VoidCallback? onAddAccountTap;

  const BankCardItem({
    super.key,
    this.account,
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.isEyeViewHidden,
    required this.onToggleEyeView,
    this.isSelected = false,
    this.isAddAccountCard = false,
    this.onAddAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isAddAccountCard) {
      return _buildAddAccountCard(context);
    }

    final isAllWallets = account == null;
    final primaryColor = isAllWallets
        ? const Color(0xFF1E293B)
        : Color(account!.brandColor);

    // Dynamic gradient based on bank color
    final gradient = isAllWallets
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              Color.lerp(primaryColor, Colors.black, 0.35) ?? primaryColor,
              Color.lerp(primaryColor, Colors.black, 0.55) ?? primaryColor,
            ],
          );

    final title = isAllWallets ? 'รวมทุกบัญชี (Net Worth)' : account!.bankName;
    final subtitle = isAllWallets
        ? 'สินทรัพย์รวมทั้งหมด'
        : (account!.accountMask != null
            ? '${account!.accountName} • ${account!.accountMask}'
            : account!.accountName);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Bank Card Container
        Container(
          margin: const EdgeInsets.fromLTRB(6, 24, 6, 4),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isSelected ? 0.35 : 0.2),
                blurRadius: isSelected ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle background decorative watermark circles
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header: Bank Logo + Title + Mask (with padding on the right for mascot dog)
                    Row(
                      children: [
                        _buildBankLogo(isAllWallets, account),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Breathing space so bank text does not collide with the dog's paws on the right
                        const SizedBox(width: 65),
                      ],
                    ),

                    // Center: Balance Typography + Eye View Button (Privacy Mode beside label)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ยอดเงินคงเหลือ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Eye View Button (Privacy Mode)
                              GestureDetector(
                                onTap: onToggleEyeView,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isEyeViewHidden
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEyeViewHidden ? 'ซ่อน' : 'แสดง',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isEyeViewHidden
                                  ? '฿ ••••••••'
                                  : CurrencyFormatter.format(balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer: Inflow / Outflow Monthly Summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Monthly Income (Masked if eye view hidden!)
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, color: Color(0xFF34D399), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isEyeViewHidden
                                    ? 'รับเข้า: +฿ •••••'
                                    : 'รับเข้า: +${CurrencyFormatter.format(monthlyIncome)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Divider
                          Container(
                            width: 1,
                            height: 12,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          // Monthly Expense
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF87171), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'จ่ายออก: -${CurrencyFormatter.format(monthlyExpense)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

        // 2. Overhanging Mascot Dog (ตัวใหญ่ 88px โผล่เกาะขอบบนขวาของการ์ด)
        Positioned(
          right: 14,
          top: -6, // Sticks out above the card (card top is at 24)
          child: IgnorePointer(
            child: SizedBox(
              width: 88,
              height: 88,
              child: Image.asset(
                'assets/images/mascot_dog_peek.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/mascot_avatar.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankLogo(bool isAllWallets, BankAccountEntity? acc) {
    if (isAllWallets) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
      );
    }

    if (acc!.bankId == 'cash') {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: const Icon(Icons.payments_rounded, color: Colors.white, size: 20),
      );
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            acc.logoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: Colors.blueGrey, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 24, 6, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: onAddAccountTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              const Text(
                '+ เพิ่มบัญชี / เชื่อมต่อธนาคาร',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'เปิดการตรวจจับบัญชีใหม่',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
