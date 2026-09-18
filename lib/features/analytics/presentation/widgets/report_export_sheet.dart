import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../utils/report_generator.dart';

class ReportExportSheet extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final PeriodRange period;
  final FinancialKpis kpis;
  final List<CategoryShare> categoryShares;

  const ReportExportSheet({
    super.key,
    required this.transactions,
    required this.period,
    required this.kpis,
    required this.categoryShares,
  });

  static Future<void> show(
    BuildContext context, {
    required List<TransactionEntity> transactions,
    required PeriodRange period,
    required FinancialKpis kpis,
    required List<CategoryShare> categoryShares,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportExportSheet(
        transactions: transactions,
        period: period,
        kpis: kpis,
        categoryShares: categoryShares,
      ),
    );
  }

  @override
  State<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends State<ReportExportSheet> {
  static const _channel = MethodChannel('com.toobjod.budgetPlanner/notification_channel');
  bool _isExporting = false;

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final csvData = ReportGenerator.generateCsv(
        transactions: widget.transactions,
        period: widget.period,
        kpis: widget.kpis,
        categoryShares: widget.categoryShares,
      );

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'ToobJod_Financial_Report_$dateStr.csv';

      try {
        await _channel.invokeMethod('shareCsv', {
          'csvContent': csvData,
          'fileName': fileName,
        });
      } catch (nativeError) {
        // Fallback for non-android or emulator
        await Clipboard.setData(ClipboardData(text: csvData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('คัดลอกข้อมูล CSV ลงคลิปบอร์ดแล้ว (พร้อมวางใน Excel/Sheets)'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้างไฟล์: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _copySummary() async {
    HapticFeedback.lightImpact();
    final summaryText = ReportGenerator.generateExecutiveSummary(
      period: widget.period,
      kpis: widget.kpis,
      categoryShares: widget.categoryShares,
    );

    await Clipboard.setData(ClipboardData(text: summaryText));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'คัดลอกสรุปรายงานเรียบร้อยแล้ว (พร้อมแชร์ใน LINE / Notes)',
                  style: GoogleFonts.prompt(fontSize: 12),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _shareSummary() async {
    HapticFeedback.lightImpact();
    final summaryText = ReportGenerator.generateExecutiveSummary(
      period: widget.period,
      kpis: widget.kpis,
      categoryShares: widget.categoryShares,
    );

    try {
      await _channel.invokeMethod('shareText', {
        'text': summaryText,
        'subject': 'สรุปรายงานสุขภาพการเงิน - เจ้าตูบจด (${widget.period.label})',
      });
    } catch (_) {
      // Fallback to clipboard
      await Clipboard.setData(ClipboardData(text: summaryText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คัดลอกสรุปรายงานลงคลิปบอร์ดแล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? Border.all(color: AppColors.darkBorderSubtle, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ส่งออกรายงานการเงิน',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.period.label,
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Executive Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ตัวอย่างสรุปผล (Preview)',
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: widget.kpis.healthStatusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ออม ${widget.kpis.savingsRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.kpis.healthStatusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPreviewItem(
                        'รายรับรวม',
                        '+${CurrencyFormatter.format(widget.kpis.totalIncome)}',
                        AppColors.income,
                      ),
                    ),
                    Expanded(
                      child: _buildPreviewItem(
                        'รายจ่ายรวม',
                        '-${CurrencyFormatter.format(widget.kpis.totalExpense)}',
                        AppColors.expense,
                      ),
                    ),
                    Expanded(
                      child: _buildPreviewItem(
                        'สุทธิ',
                        '${widget.kpis.netCashFlow >= 0 ? "+" : ""}${CurrencyFormatter.format(widget.kpis.netCashFlow)}',
                        widget.kpis.netCashFlow >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '📊 รวมทั้งหมด ${widget.kpis.totalCount} รายการ • หมวดจ่ายสูงสุด: ${widget.categoryShares.isNotEmpty ? widget.categoryShares.first.categoryName : "ไม่มี"}',
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: Export CSV (Primary Action)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCsv,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart_rounded, size: 20),
              label: Text(
                _isExporting ? 'กำลังประมวลผล...' : 'ส่งออกเป็นไฟล์ CSV (Excel / Sheets)',
                style: GoogleFonts.prompt(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Actions Row: Copy Text & Share Text
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _copySummary,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: Text(
                      'คัดลอกสรุป',
                      style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _shareSummary,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 17),
                    label: Text(
                      'แชร์ข้อความ',
                      style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'ไฟล์ CSV รองรับภาษาไทยสมบูรณ์ (UTF-8 BOM) เปิดบน Excel ได้ทันที',
              style: GoogleFonts.prompt(
                fontSize: 10.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.prompt(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
