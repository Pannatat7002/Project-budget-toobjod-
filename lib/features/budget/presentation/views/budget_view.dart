import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../dashboard/presentation/widgets/safe_to_spend_detail_sheet.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../state/budget_cubit.dart';
import '../state/budget_state.dart';
import '../widgets/budget_progress_card.dart';
import 'set_budget_dialog.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'วางแผนงบประมาณ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () => SetBudgetDialog.show(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
            tooltip: 'ตั้งงบประมาณใหม่',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<BudgetCubit, BudgetState>(
        // Rebuild only when budgets or status changes
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.budgets != curr.budgets,
        builder: (context, state) {
          if (state.status == BudgetStatus.loading && state.budgets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = state.budgets;
          final totalLimit = state.totalBudgetLimit;
          final totalSpent = state.totalBudgetSpent;
          final totalRemaining = state.totalBudgetRemaining;
          final progress = state.totalProgressPercentage;

          return BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, txState) {
              final currentBalance = txState.totalBalance;
              final isBalanceSufficient = currentBalance >= totalLimit;
              final safeToSpendToday = state.getSafeToSpendToday(
                txState.todayExpense.abs(),
                currentBalance,
              );
              final isExceededToday = safeToSpendToday < 0;
              final isCashConstrained = currentBalance < totalRemaining;

              final effectiveRemaining = (currentBalance < totalRemaining)
                  ? (currentBalance > 0 ? currentBalance : 0.0)
                  : totalRemaining;

              final String safeStatusTitle;
              final String safeAmountText;
              final String safeSubText;
              final String mascotAdvice;
              final Color safeColor;

              if (isExceededToday) {
                final overSpent = safeToSpendToday.abs();
                safeStatusTitle = '🐾 วันนี้ใช้เกินงบแล้ว';
                safeAmountText = 'เกินไป ฿${CurrencyFormatter.format(overSpent)}';
                safeSubText = '(ใช้วันนี้ไป ฿${CurrencyFormatter.format(txState.todayExpense.abs())})';
                mascotAdvice =
                    'วันนี้ใช้เกินโควต้าไป ฿${CurrencyFormatter.format(overSpent)} พักก่อนน้า พรุ่งนี้ค่อยเริ่มใหม่โฮ่ง! 🦴';
                safeColor = const Color(0xFFFBBF24);
              } else if (isCashConstrained) {
                safeStatusTitle = '🛡️ งบที่ใช้ได้วันนี้ (จำกัดตามเงินจริง)';
                safeAmountText = '฿${CurrencyFormatter.format(safeToSpendToday)}';
                safeSubText = '(ใช้วันนี้ไป ฿${CurrencyFormatter.format(txState.todayExpense.abs())})';
                mascotAdvice =
                    '⚠️ เงินในบัญชีจริง (฿${CurrencyFormatter.formatNumber(effectiveRemaining, showDecimals: false)}) น้อยกว่างบ ระบบจึงคำนวณงบรายวันจากยอดเหลือจริงให้น้า 🐾';
                safeColor = const Color(0xFFFBBF24);
              } else {
                safeStatusTitle = '🛡️ งบที่ใช้ได้วันนี้';
                safeAmountText = '฿${CurrencyFormatter.format(safeToSpendToday)}';
                safeSubText = '(ใช้วันนี้ไป ฿${CurrencyFormatter.format(txState.todayExpense.abs())})';
                mascotAdvice =
                    'วันนี้กินช้อปได้สบายใจ ยังอยู่ในงบโฮ่ง! 🍖';
                safeColor = const Color(0xFF6EE7B7);
              }

              return RefreshIndicator(
                onRefresh: () => context.read<BudgetCubit>().loadBudgets(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Budget Summary Hero Card (Refined & Balanced)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF18264A), // Midnight Deep Navy
                                    const Color(0xFF131E3A), // Dark Surface Navy
                                  ]
                                : [
                                    const Color(0xFFFF7A00), // ToobJod Brand Orange
                                    const Color(0xFFEA580C), // Warm Rich Orange
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : const Color(0xFFEA580C).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Avatar + Title & Month + Progress Badge
                                    Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.20),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/images/mascot_dog_peek.png',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.pets,
                                                color: Colors.white,
                                                size: 20,
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
                                                'งบประมาณรวมประจำเดือน',
                                                style: GoogleFonts.prompt(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.95,
                                                  ),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                DateFormatter.formatMonthYear(
                                                  DateTime.now(),
                                                ),
                                                style: GoogleFonts.prompt(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.78,
                                                  ),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.25,
                                              ),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            '${(progress * 100).toInt()}% ใช้ไปแล้ว',
                                            style: GoogleFonts.prompt(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Budget Amount & Base Daily Rate Pill
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 10,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(totalLimit),
                                          style: GoogleFonts.prompt(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.8,
                                          ),
                                        ),
                                        if (totalLimit > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              'เกณฑ์ ~${state.dailyBaseAllowance.toStringAsFixed(0)} บ./วัน',
                                              style: GoogleFonts.prompt(
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Single Clean Progress Bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        minHeight: 7,
                                        backgroundColor: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          progress > 1.0
                                              ? const Color(0xFFF59E0B)
                                              : (progress >= 0.8
                                                  ? const Color(0xFFFBBF24)
                                                  : Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    // ─── 2 คอลัมน์ ไร้กรอบ (แถว 1: งบรายวัน & งบทั้งเดือน / เหลือจริง) ───
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildCleanStat(
                                            label: 'งบรายวัน',
                                            amount: safeAmountText,
                                            color: safeColor,
                                            trailing: const Icon(
                                              Icons.info_outline_rounded,
                                              size: 13,
                                              color: Colors.white70,
                                            ),
                                            onTap: () {
                                              SafeToSpendDetailSheet.show(
                                                context,
                                                totalBudgetLimit: totalLimit,
                                                totalBudgetSpent: totalSpent.abs(),
                                                totalBudgetRemaining: totalRemaining,
                                                effectiveRemaining: isCashConstrained
                                                    ? effectiveRemaining
                                                    : null,
                                                daysRemainingInMonth:
                                                    state.daysRemainingInMonth,
                                                totalDaysInMonth:
                                                    state.daysInCurrentMonth,
                                                dailyBaseAllowance:
                                                    state.dailyBaseAllowance,
                                                todaySpent: txState.todayExpense.abs(),
                                                safeToSpendToday: safeToSpendToday,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildCleanStat(
                                            label: 'งบทั้งเดือน / เหลือจริง',
                                            amount:
                                                '${CurrencyFormatter.formatNumber(totalLimit, showDecimals: false)} / ${CurrencyFormatter.formatNumber(effectiveRemaining, showDecimals: false)}',
                                            color: isCashConstrained
                                                ? const Color(0xFFFBBF24)
                                                : (effectiveRemaining > 0
                                                    ? const Color(0xFF6EE7B7)
                                                    : const Color(0xFFFBBF24)),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    // ─── 2 คอลัมน์ ไร้กรอบ (แถว 2: ใช้จริง & เงินในบัญชีรวม) ───
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildCleanStat(
                                            label: 'ใช้จริง (วันนี้)',
                                            amount: CurrencyFormatter.format(
                                              txState.todayExpense.abs(),
                                            ),
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildCleanStat(
                                            label: 'เงินในบัญชีรวม',
                                            amount: CurrencyFormatter.format(
                                              currentBalance,
                                            ),
                                            color: isBalanceSufficient
                                                ? const Color(0xFF6EE7B7)
                                                : const Color(0xFFFBBF24),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    // ─── คำแนะนำจากน้องหมา (Strip ไร้กรอบ) ───
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.22),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text(
                                            '💬 ',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          Expanded(
                                            child: Text(
                                              mascotAdvice,
                                              style: GoogleFonts.prompt(
                                                fontSize: 11.5,
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                                fontWeight: FontWeight.w500,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 22),

                      // Section Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'งบประมาณตามหมวดหมู่',
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            InkWell(
                              onTap: () => SetBudgetDialog.show(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'เพิ่มงบ',
                                      style: GoogleFonts.prompt(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Budget items list or empty state
                      if (budgets.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.pie_chart_outline,
                          title: 'ยังไม่ได้ตั้งงบประมาณ',
                          // message: 'วางแผนและคุมค่าใช้จ่ายล่วงหน้าเพื่อไม่ให้ใช้เงินเกินตัว!',
                          // actionText: 'ตั้งงบประมาณแรก',
                          onAction: () => SetBudgetDialog.show(context),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: budgets.length,
                          itemBuilder: (context, index) {
                            final b = budgets[index];
                            return BudgetProgressCard(
                              budget: b,
                              onEdit: () =>
                                  SetBudgetDialog.show(context, existingBudget: b),
                              onDelete: () {
                                context.read<BudgetCubit>().deleteBudget(b.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ลบงบประมาณ "${b.categoryName}" แล้ว',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

  Widget _buildCleanStat({
    required String label,
    required String amount,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
    double fontSize = 17.5,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.prompt(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: GoogleFonts.prompt(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
