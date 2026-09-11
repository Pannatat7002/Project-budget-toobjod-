import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ? const Color(0xFFEA580C)
        : Color(account!.brandColor);

    // Dynamic gradient based on bank color
    final gradient = isAllWallets
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF7A00),
              Color(0xFFEA580C),
              Color(0xFFC2410C),
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Bank Card Container
        Container(
          margin: const EdgeInsets.fromLTRB(1, 22, 1, 4),
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
                color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.05),
                blurRadius: isSelected ? 4 : 2,
                offset: const Offset(0, 2),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header: Brand Badge (Big Logo + Title inside) + Account Mask
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: _buildBrandPill(
                            isAllWallets: isAllWallets,
                            account: account,
                          ),
                        ),
                        // Account Mask Pill (•••• 1234) if available
                        if (account?.accountMask != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '•••• ${account!.accountMask!.replaceAll(RegExp(r'[^0-9]'), '')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                      ],
                    ),

                    // Center: Balance Typography + Eye View Button (Privacy Mode on ยอดเงินคงเหลือ)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onToggleEyeView();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'ยอดเงินคงเหลือ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                // Eye View Button (Privacy Mode)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.28,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isEyeViewHidden
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEyeViewHidden ? 'แตะเพื่อดู' : 'ซ่อน',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer: Inflow / Outflow + Status Badge (Matching user mockup)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                          // Inflow / Outflow Summary
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Monthly Income (Masked if eye view hidden!)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: Color(0xFF34D399),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'เข้า: +${CurrencyFormatter.format(monthlyIncome)}',
                                        style: const TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 5),
                                  // Divider
                                  Container(
                                    width: 1,
                                    height: 11,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  const SizedBox(width: 5),
                                  // Monthly Expense
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Color(0xFFF87171),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'ออก: -${CurrencyFormatter.format(monthlyExpense)}',
                                        style: const TextStyle(
                                          color: Color(0xFFF87171),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Live Sync Status Badge (🟢 ตรวจจับสดเปิด)
                          _buildStatusBadge(isAllWallets, account),
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
          right: 12,
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

  Widget _buildStatusBadge(bool isAllWallets, BankAccountEntity? account) {
    if (isAllWallets) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            width: 0.6,
          ),
        ),
        child: const Text(
          '✨ รวมทุกกระเป๋า',
          style: TextStyle(
            color: Color(0xFFFDE68A),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isAutoSync = account?.isAutoSyncActive ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: isAutoSync
            ? const Color(0xFF10B981).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAutoSync
              ? const Color(0xFF34D399).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAutoSync ? const Color(0xFF34D399) : Colors.white60,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAutoSync ? 'ตรวจจับสดเปิด' : 'ปิดตรวจจับ',
            style: TextStyle(
              color: isAutoSync ? const Color(0xFF6EE7B7) : Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPill({
    required bool isAllWallets,
    required BankAccountEntity? account,
  }) {
    final displayName = isAllWallets ? 'รวมทุกบัญชี' : (account?.shortName ?? 'ธนาคาร');

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 14, 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBankLogo(isAllWallets, account),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankLogo(bool isAllWallets, BankAccountEntity? acc) {
    if (isAllWallets || acc == null) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: Color(0xFFEA580C),
          size: 22,
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Image.asset(
            acc.logoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.account_balance,
              color: Colors.blueGrey,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddAccountCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
        : const Color(0xFF94A3B8);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(1, 22, 1, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onAddAccountTap,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+ เพิ่มบัญชี / เชื่อมต่อธนาคาร',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'เปิดการตรวจจับบัญชีใหม่ หรือเพิ่มธนาคารที่ใช้',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
