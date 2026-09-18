import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
            colors: [Color(0xFFFF7A00), Color(0xFFEA580C), Color(0xFFC2410C)],
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
          margin: const EdgeInsets.fromLTRB(1, 14, 1, 2),
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
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                              style: GoogleFonts.prompt(
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
                    const SizedBox(height: 6),

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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'ยอดเงินคงเหลือ',
                                  style: GoogleFonts.prompt(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      isEyeViewHidden
                                          ? '******'
                                          : CurrencyFormatter.format(balance),
                                      style: GoogleFonts.prompt(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                  child: Icon(
                                    isEyeViewHidden
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bottom Financial Flow Strip (Income & Expense of this month)
                    // Row(
                    //   children: [
                    //     Flexible(
                    //       child: Container(
                    //         padding: const EdgeInsets.symmetric(
                    //           horizontal: 8,
                    //           vertical: 3,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: Colors.black.withValues(alpha: 0.22),
                    //           borderRadius: BorderRadius.circular(8),
                    //           border: Border.all(
                    //             color: Colors.white.withValues(alpha: 0.18),
                    //             width: 0.8,
                    //           ),
                    //         ),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             const Icon(
                    //               Icons.arrow_downward_rounded,
                    //               size: 11,
                    //               color: Color(0xFF6EE7B7),
                    //             ),
                    //             const SizedBox(width: 3),
                    //             Flexible(
                    //               child: FittedBox(
                    //                 fit: BoxFit.scaleDown,
                    //                 child: Text(
                    //                   isEyeViewHidden
                    //                       ? '***'
                    //                       : '+${CurrencyFormatter.format(monthlyIncome)}',
                    //                   style: GoogleFonts.prompt(
                    //                     color: Colors.white,
                    //                     fontSize: 10.5,
                    //                     fontWeight: FontWeight.w700,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Flexible(
                    //       child: Container(
                    //         padding: const EdgeInsets.symmetric(
                    //           horizontal: 8,
                    //           vertical: 3,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: Colors.black.withValues(alpha: 0.22),
                    //           borderRadius: BorderRadius.circular(8),
                    //           border: Border.all(
                    //             color: Colors.white.withValues(alpha: 0.18),
                    //             width: 0.8,
                    //           ),
                    //         ),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             const Icon(
                    //               Icons.arrow_upward_rounded,
                    //               size: 11,
                    //               color: Color(0xFFFCA5A5),
                    //             ),
                    //             const SizedBox(width: 3),
                    //             Flexible(
                    //               child: FittedBox(
                    //                 fit: BoxFit.scaleDown,
                    //                 child: Text(
                    //                   isEyeViewHidden
                    //                       ? '***'
                    //                       : '-${CurrencyFormatter.format(monthlyExpense)}',
                    //                   style: GoogleFonts.prompt(
                    //                     color: Colors.white,
                    //                     fontSize: 10.5,
                    //                     fontWeight: FontWeight.w700,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Overhanging Mascot Dog (โผล่เกาะขอบบนขวาของการ์ด)
        Positioned(
          right: 0,
          top: 50,
          child: IgnorePointer(
            child: SizedBox(
              width: 120,
              height: 120,
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

  // Widget _buildStatusBadge(bool isAllWallets, BankAccountEntity? account) {
  //   if (isAllWallets) {
  //     return Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(
  //           color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
  //           width: 0.6,
  //         ),
  //       ),
  //       child: Text(
  //         '✨ รวมทุกกระเป๋า',
  //         style: GoogleFonts.prompt(
  //           color: const Color(0xFFFDE68A),
  //           fontSize: 9.5,
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //     );
  //   }

  //   final isAutoSync = account?.isAutoSyncActive ?? false;

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
  //     decoration: BoxDecoration(
  //       color: isAutoSync
  //           ? const Color(0xFF10B981).withValues(alpha: 0.25)
  //           : Colors.white.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(
  //         color: isAutoSync
  //             ? const Color(0xFF34D399).withValues(alpha: 0.45)
  //             : Colors.white.withValues(alpha: 0.2),
  //         width: 0.6,
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 6,
  //           height: 6,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: isAutoSync ? const Color(0xFF34D399) : Colors.white60,
  //           ),
  //         ),
  //         const SizedBox(width: 4),
  //         Text(
  //           isAutoSync ? 'ตรวจจับสดเปิด' : 'ปิดตรวจจับ',
  //           style: GoogleFonts.prompt(
  //             color: isAutoSync ? const Color(0xFF6EE7B7) : Colors.white70,
  //             fontSize: 9.5,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBrandPill({
    required bool isAllWallets,

    required BankAccountEntity? account,
  }) {
    final displayName = isAllWallets
        ? 'รวมทุกบัญชี'
        : (account?.shortName ?? 'ธนาคาร');

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 14, 3),
      // decoration: BoxDecoration(
      //   color: Colors.black.withValues(alpha: 0.24),
      //   borderRadius: BorderRadius.circular(28),
      //   border: Border.all(
      //     color: Colors.white.withValues(alpha: 0.28),
      //     width: 0.9,
      //   ),
      // ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBankLogo(isAllWallets, account),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              displayName,
              style: GoogleFonts.prompt(
                color: Colors.white,
                fontSize: 14,
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
        shape: BoxShape.rectangle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
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
      margin: const EdgeInsets.fromLTRB(1, 14, 1, 2),
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
                style: GoogleFonts.prompt(
                  color: titleColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'เปิดการตรวจจับบัญชีใหม่ หรือเพิ่มธนาคารที่ใช้',
                style: GoogleFonts.prompt(
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
