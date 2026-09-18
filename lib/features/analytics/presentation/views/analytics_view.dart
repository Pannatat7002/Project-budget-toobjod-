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

              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.primary,
                    size: 19,
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
              );
            },
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Horizontal Time Horizon Period Selector
                _buildPeriodFilterRow(isDark),
                const SizedBox(height: 14),

                // 2. Financial Health Status Assessment Card (CFP Standard)
                _buildFinancialHealthBanner(kpis, isDark),
                const SizedBox(height: 14),

                // 3. International Standard 4-KPI Metric Cards
                _buildKpiMetricsGrid(kpis, isDark),
                const SizedBox(height: 20),

                // 4. Inflows vs Outflows Cash Flow Comparison Bar Chart
                _buildSectionCard(
                  title: 'กระแสเงินสด (Cash Flow)',
                  subtitle: period.label,
                  isDark: isDark,
                  child: CashFlowBarChart(
                    transactions: periodTxs,
                    period: period,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Category Spending Breakdown (Donut Chart)
                _buildSectionCard(
                  title: 'สัดส่วนรายจ่ายตามหมวดหมู่ (Breakdown)',
                  subtitle: 'รวม ${CurrencyFormatter.format(kpis.totalExpense)} บ.',
                  isDark: isDark,
                  child: CategoryPieChart(transactions: periodTxs),
                ),
                const SizedBox(height: 20),

                // 6. Pareto 80/20 Spending Drivers
                if (categoryShares.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'หมวดหมู่ที่ใช้เงินมากที่สุด (Top Drivers)',
                    subtitle: 'เรียงตามยอดค่าใช้จ่ายสูงสุด',
                    isDark: isDark,
                    child: _buildTopCategoryDrivers(categoryShares, isDark),
                  ),
                  const SizedBox(height: 20),
                ],

                // 7. Action CTA Button: Export Report
                Container(
                  width: double.infinity,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 24),
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
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 20),
                    label: Text(
                      'ส่งออกรายงานฉบับสมบูรณ์ (Excel / CSV)',
                      style: GoogleFonts.prompt(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilterRow(bool isDark) {
    final periods = [
      AnalyticsPeriod.thisMonth,
      AnalyticsPeriod.lastMonth,
      AnalyticsPeriod.last3Months,
      AnalyticsPeriod.thisYear,
      AnalyticsPeriod.allTime,
      AnalyticsPeriod.custom,
    ];

    return SingleChildScrollView(
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
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
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
    );
  }

  Widget _buildFinancialHealthBanner(FinancialKpis kpis, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kpis.healthStatusColor.withValues(alpha: isDark ? 0.45 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0 : 0.03),
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
              color: kpis.healthStatusColor.withValues(alpha: 0.14),
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
                    fontSize: 13.5,
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
    final netColor = kpis.netCashFlow >= 0 ? AppColors.income : AppColors.expense;

    return Column(
      children: [
        Row(
          children: [
            // KPI 1: Net Cash Flow
            Expanded(
              child: _buildMetricCard(
                title: 'กระแสเงินสดสุทธิ (Net)',
                value: '${kpis.netCashFlow >= 0 ? "+" : ""}${CurrencyFormatter.format(kpis.netCashFlow)} บ.',
                subtext: kpis.netCashFlow >= 0 ? 'เกินดุล (Surplus)' : 'ขาดดุล (Deficit)',
                valueColor: netColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // KPI 2: Savings Rate
            Expanded(
              child: _buildMetricCard(
                title: 'อัตราการออมสุทธิ',
                value: '${kpis.savingsRate.toStringAsFixed(1)}%',
                subtext: 'เกณฑ์มาตรฐานสากล ≥ 20%',
                valueColor: kpis.savingsRate >= 20 ? AppColors.income : (kpis.savingsRate >= 10 ? const Color(0xFF0EA5E9) : AppColors.warning),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // KPI 3: Expense Ratio
            Expanded(
              child: _buildMetricCard(
                title: 'สัดส่วนค่าใช้จ่าย/รายรับ',
                value: '${kpis.expenseRatio.toStringAsFixed(1)}%',
                subtext: 'ไม่ควรเกิน 70-80%',
                valueColor: kpis.expenseRatio <= 70 ? AppColors.income : (kpis.expenseRatio <= 85 ? AppColors.warning : AppColors.expense),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // KPI 4: Daily Burn Rate
            Expanded(
              child: _buildMetricCard(
                title: 'ค่าใช้จ่ายเฉลี่ยต่อวัน',
                value: '${CurrencyFormatter.format(kpis.dailyBurnRate)} บ.',
                subtext: 'วินัยการใช้เงินรายวัน',
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
    required String title,
    required String value,
    required String subtext,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 3),
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
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  subtitle,
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
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

  Widget _buildTopCategoryDrivers(List<CategoryShare> categoryShares, bool isDark) {
    final topItems = categoryShares.take(5).toList();

    return Column(
      children: topItems.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final color = Color(item.colorValue != 0 ? item.colorValue : 0xFF2563EB);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.prompt(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.categoryName,
                      style: GoogleFonts.prompt(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.format(item.amount)} บ.',
                    style: GoogleFonts.prompt(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${item.percentage.toStringAsFixed(1)}%)',
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.percentage / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
