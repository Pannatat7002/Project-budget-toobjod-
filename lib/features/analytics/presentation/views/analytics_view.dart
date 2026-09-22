import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/state/transaction_cubit.dart';
import '../../../transactions/presentation/state/transaction_state.dart';
import '../../utils/report_generator.dart';
import '../widgets/cash_flow_bar_chart.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/report_export_sheet.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.thisMonth;
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = AnalyticsPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = PeriodRange.fromType(_selectedPeriod, customRange: _customRange);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'วิเคราะห์ & รายงาน',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          BlocBuilder<TransactionCubit, TransactionState>(
            builder: (context, state) {
              final periodTxs = _filterTransactions(state.transactions, period);
              final kpis = ReportGenerator.calculateKpis(periodTxs, period);
              final categoryShares = ReportGenerator.calculateCategoryShares(periodTxs);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ส่งออก',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  tooltip: 'ส่งออกรายงานการเงิน',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ReportExportSheet.show(
                      context,
                      transactions: periodTxs,
                      period: period,
                      kpis: kpis,
                      categoryShares: categoryShares,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        buildWhen: (prev, curr) =>
            prev.transactions != curr.transactions || prev.status != curr.status,
        builder: (context, state) {
          final periodTxs = _filterTransactions(state.transactions, period);
          final kpis = ReportGenerator.calculateKpis(periodTxs, period);
          final categoryShares = ReportGenerator.calculateCategoryShares(periodTxs);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Horizontal Time Horizon Period Selector & Active Date Badge
                _buildPeriodFilterRow(period, isDark),
                const SizedBox(height: 16),

                // 2. HERO: สัดส่วนรายจ่าย (Category Spending Breakdown Donut & Ranking)
                _buildSectionCard(
                  icon: Icons.donut_large_rounded,
                  iconColor: AppColors.primary,
                  title: 'สัดส่วนรายจ่าย',
                  badgeText: 'ยอดรวม ${CurrencyFormatter.format(kpis.totalExpense)} บ.',
                  badgeColor: AppColors.expense,
                  isDark: isDark,
                  child: CategoryPieChart(
                    transactions: periodTxs,
                    categoryShares: categoryShares,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. ภาพรวมกระแสเงินสด 3 มิติ (Inflow, Outflow, Net Balance)
                _buildCashFlowOverviewCard(kpis, isDark),
                const SizedBox(height: 16),

                // 4. การประเมินสุขภาพการเงิน (CFP Financial Health Assessment)
                _buildFinancialHealthBanner(kpis, isDark),
                const SizedBox(height: 16),

                // 5. ดัชนีชี้วัดหลัก 4 มิติ (Key Financial Metrics 2x2)
                _buildKpiMetricsGrid(kpis, isDark),
                const SizedBox(height: 16),

                // 6. แนวโน้มกระแสเงินสด (Cash Flow Comparison Bar Chart)
                _buildSectionCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppColors.accent,
                  title: 'กระแสเงินสด (Cash Flow)',
                  badgeText: period.label,
                  badgeColor: AppColors.accent,
                  isDark: isDark,
                  child: CashFlowBarChart(
                    transactions: periodTxs,
                    period: period,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Action CTA Button: Export Complete Report
                Container(
                  width: double.infinity,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 28),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ReportExportSheet.show(
                        context,
                        transactions: periodTxs,
                        period: period,
                        kpis: kpis,
                        categoryShares: categoryShares,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: isDark ? 0 : 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: Text(
                      'ส่งออกรายงานฉบับสมบูรณ์ (Excel / CSV / ข้อความ)',
                      style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilterRow(PeriodRange period, bool isDark) {
    final periods = [
      AnalyticsPeriod.thisMonth,
      AnalyticsPeriod.lastMonth,
      AnalyticsPeriod.last3Months,
      AnalyticsPeriod.thisYear,
      AnalyticsPeriod.allTime,
      AnalyticsPeriod.custom,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: periods.map((p) {
              final isSelected = _selectedPeriod == p;
              String label;
              switch (p) {
                case AnalyticsPeriod.thisMonth:
                  label = 'เดือนนี้';
                  break;
                case AnalyticsPeriod.lastMonth:
                  label = 'เดือนที่แล้ว';
                  break;
                case AnalyticsPeriod.last3Months:
                  label = '3 เดือน';
                  break;
                case AnalyticsPeriod.thisYear:
                  label = 'ปีนี้';
                  break;
                case AnalyticsPeriod.allTime:
                  label = 'ทั้งหมด';
                  break;
                case AnalyticsPeriod.custom:
                  label = _customRange != null ? 'กำหนดเอง 📅' : 'เลือกช่วงวัน 📅';
                  break;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (p == AnalyticsPeriod.custom) {
                      _pickCustomRange();
                    } else {
                      setState(() => _selectedPeriod = p);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : (isDark ? AppColors.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Date Range Subtitle Info
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(width: 5),
            Text(
              '${period.label} • รวม ${period.dayCount} วัน',
              style: GoogleFonts.prompt(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashFlowOverviewCard(FinancialKpis kpis, bool isDark) {
    final netColor = kpis.netCashFlow >= 0 ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'สรุปกระแสเงินสด',
                style: GoogleFonts.prompt(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Inflow (รายรับ)
              Expanded(
                child: _buildCashPillar(
                  title: 'รายรับ (Inflow)',
                  amount: '+${CurrencyFormatter.format(kpis.totalIncome)}',
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Outflow (รายจ่าย)
              Expanded(
                child: _buildCashPillar(
                  title: 'รายจ่าย (Outflow)',
                  amount: '-${CurrencyFormatter.format(kpis.totalExpense)}',
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Net Balance (สุทธิ)
              Expanded(
                child: _buildCashPillar(
                  title: 'สุทธิ (Net)',
                  amount: '${kpis.netCashFlow >= 0 ? "+" : ""}${CurrencyFormatter.format(kpis.netCashFlow)}',
                  color: netColor,
                  icon: kpis.netCashFlow >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashPillar({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.prompt(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: GoogleFonts.prompt(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFinancialHealthBanner(FinancialKpis kpis, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kpis.healthStatusColor.withValues(alpha: isDark ? 0.45 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kpis.healthStatusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              kpis.healthStatus == FinancialHealthStatus.deficit
                  ? Icons.warning_rounded
                  : Icons.health_and_safety_rounded,
              color: kpis.healthStatusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpis.healthStatusTitle,
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kpis.healthStatusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kpis.healthStatusAdvice,
                  style: GoogleFonts.prompt(
                    fontSize: 11.5,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid(FinancialKpis kpis, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            // KPI 1: Savings Rate (อัตราการออม)
            Expanded(
              child: _buildMetricCard(
                icon: Icons.savings_outlined,
                iconColor: AppColors.income,
                title: 'อัตราการออมสุทธิ',
                value: '${kpis.savingsRate.toStringAsFixed(1)}%',
                subtext: 'เกณฑ์มาตรฐานสากล ≥ 20%',
                valueColor: kpis.savingsRate >= 20
                    ? AppColors.success
                    : (kpis.savingsRate >= 10 ? const Color(0xFF0EA5E9) : AppColors.warning),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // KPI 2: Expense Ratio (สัดส่วนค่าใช้จ่าย)
            Expanded(
              child: _buildMetricCard(
                icon: Icons.pie_chart_outline_rounded,
                iconColor: AppColors.expense,
                title: 'สัดส่วนรายจ่าย/รายรับ',
                value: '${kpis.expenseRatio.toStringAsFixed(1)}%',
                subtext: 'เกณฑ์ไม่ควรเกิน 70-80%',
                valueColor: kpis.expenseRatio <= 70
                    ? AppColors.success
                    : (kpis.expenseRatio <= 85 ? AppColors.warning : AppColors.expense),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // KPI 3: Daily Burn Rate (ค่าใช้จ่ายต่อวัน)
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_fire_department_outlined,
                iconColor: const Color(0xFFF97316),
                title: 'ค่าใช้จ่ายเฉลี่ยต่อวัน',
                value: '${CurrencyFormatter.format(kpis.dailyBurnRate)} บ.',
                subtext: 'วินัยการใช้เงินเฉลี่ยต่อวัน',
                valueColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // KPI 4: Transaction Count (จำนวนรายการ)
            Expanded(
              child: _buildMetricCard(
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'ธุรกรรมทั้งหมด',
                value: '${kpis.totalCount} รายการ',
                subtext: 'รับ ${kpis.incomeCount} • จ่าย ${kpis.expenseCount}',
                valueColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtext,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.prompt(
              fontSize: 9.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.prompt(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  List<TransactionEntity> _filterTransactions(
    List<TransactionEntity> transactions,
    PeriodRange period,
  ) {
    if (period.type == AnalyticsPeriod.allTime) {
      return transactions;
    }
    return transactions.where((t) {
      return !t.date.isBefore(period.startDate) && !t.date.isAfter(period.endDate);
    }).toList();
  }
}

