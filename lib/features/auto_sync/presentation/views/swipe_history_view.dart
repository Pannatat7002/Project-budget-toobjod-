import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/swipe_history_record.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import '../widgets/bank_logo_badge.dart';

class SwipeHistoryView extends StatefulWidget {
  const SwipeHistoryView({super.key});

  static Future<void> show(BuildContext context) {
    final autoSyncCubit = context.read<AutoSyncCubit>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: autoSyncCubit,
          child: const SwipeHistoryView(),
        ),
      ),
    );
  }

  @override
  State<SwipeHistoryView> createState() => _SwipeHistoryViewState();
}

class _SwipeHistoryViewState extends State<SwipeHistoryView> {
  SwipeResult? _filterResult;  // null = ทั้งหมด
  bool _isExporting = false;

  List<SwipeHistoryRecord> _filtered(List<SwipeHistoryRecord> all) {
    if (_filterResult == null) return all;
    return all.where((r) => r.swipeResult == _filterResult).toList();
  }

  Future<void> _exportCsv(BuildContext context, List<SwipeHistoryRecord> records) async {
    setState(() => _isExporting = true);
    try {
      final csv = StringBuffer();
      csv.writeln(SwipeHistoryRecord.csvHeader);
      for (final r in records) {
        csv.writeln(r.toCsvRow());
      }
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'swipe_history_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv.toString());

      if (context.mounted) {
        _showExportSuccessDialog(context, file.path, records.length);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportSuccessDialog(BuildContext context, String path, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Export สำเร็จ!',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'บันทึก $count รายการลงไฟล์ CSV เรียบร้อยแล้ว',
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightBorderSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path,
                      style: GoogleFonts.prompt(
                        fontSize: 10.5,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: path));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอก path แล้ว')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ปิด',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AutoSyncCubit, AutoSyncState>(
      buildWhen: (prev, curr) => prev.swipeHistory != curr.swipeHistory,
      builder: (context, state) {
        final filtered = _filtered(state.swipeHistory);
        final allHistory = state.swipeHistory;
        final confirmedCount = allHistory.where((r) => r.swipeResult == SwipeResult.confirmed).length;
        final discardedCount = allHistory.where((r) => r.swipeResult == SwipeResult.discarded).length;
        final changedCatCount = allHistory.where((r) => r.categoryChanged && r.swipeResult == SwipeResult.confirmed).length;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 0,
            title: Text(
              'ประวัติการตรวจสอบ',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            actions: [
              if (allHistory.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 22),
                  tooltip: 'ล้างประวัติทั้งหมด',
                  onPressed: () => _confirmClear(context, isDark),
                ),
              if (filtered.isNotEmpty)
                _isExporting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download_rounded, size: 22),
                        tooltip: 'Export CSV',
                        onPressed: () => _exportCsv(context, filtered),
                      ),
            ],
          ),
          body: Column(
            children: [
              // ── Summary Chips Bar ──
              if (allHistory.isNotEmpty)
                _buildSummaryBar(context, isDark, confirmedCount, discardedCount, changedCatCount),

              // ── Filter Tabs ──
              _buildFilterBar(context, isDark, allHistory),

              // ── List / Empty State ──
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildList(context, filtered, isDark),
              ),
            ],
          ),
          bottomNavigationBar: filtered.isNotEmpty
              ? _buildExportFooter(context, filtered, isDark)
              : null,
        );
      },
    );
  }

  // ─── Summary Stats ───────────────────────────────────────────────────────────
  Widget _buildSummaryBar(
    BuildContext context,
    bool isDark,
    int confirmed,
    int discarded,
    int changedCat,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _chip(
              icon: Icons.check_circle_rounded,
              label: '$confirmed ยืนยัน',
              color: AppColors.success,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            _chip(
              icon: Icons.cancel_rounded,
              label: '$discarded ลบ',
              color: AppColors.error,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            _chip(
              icon: Icons.edit_rounded,
              label: '$changedCat เปลี่ยนหมวด',
              color: AppColors.primary,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.prompt(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ──────────────────────────────────────────────────────────────
  Widget _buildFilterBar(BuildContext context, bool isDark, List<SwipeHistoryRecord> all) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _filterTab(null, 'ทั้งหมด (${all.length})', isDark),
          _filterTab(
            SwipeResult.confirmed,
            '✅ ยืนยัน (${all.where((r) => r.swipeResult == SwipeResult.confirmed).length})',
            isDark,
          ),
          _filterTab(
            SwipeResult.discarded,
            '❌ ลบ (${all.where((r) => r.swipeResult == SwipeResult.discarded).length})',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _filterTab(SwipeResult? result, String label, bool isDark) {
    final isSelected = _filterResult == result;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterResult = result),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: GoogleFonts.prompt(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Compact List ────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<SwipeHistoryRecord> records, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 80),
      itemCount: records.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.7,
        indent: 48,
        color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        // Most recent first
        final r = records[records.length - 1 - index];
        return _buildHistoryItem(r, isDark);
      },
    );
  }

  Widget _buildHistoryItem(SwipeHistoryRecord r, bool isDark) {
    final isConfirmed = r.swipeResult == SwipeResult.confirmed;
    final resultColor = isConfirmed ? AppColors.success : AppColors.error;
    final amountColor = r.isIncome ? AppColors.income : AppColors.expense;
    final timeStr =
        '${r.swipedAt.day}/${r.swipedAt.month} ${r.swipedAt.hour.toString().padLeft(2, '0')}:${r.swipedAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => _showRecordDetailDialog(context, r, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bank Logo Badge
            BankLogoBadge(
              fallbackShortName: r.bankShortName,
              size: 26,
              borderRadius: 6,
              showBorder: false,
            ),
            const SizedBox(width: 10),

            // Middle Column: Title & Subtitle (Date + Category + Changed Badge)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Title
                  Text(
                    r.title,
                    style: GoogleFonts.prompt(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Row 2: Date + Category chip + Changed tag
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 8,
                          color: (isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8)).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Category Chip
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightBorderSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.confirmedCategoryName,
                            style: GoogleFonts.prompt(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (r.categoryChanged && isConfirmed) ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'เปลี่ยน Cat.',
                            style: GoogleFonts.prompt(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Column: Amount + Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount
                Text(
                  '${r.isIncome ? '+' : '-'}${CurrencyFormatter.format(r.amount)} ฿',
                  style: GoogleFonts.prompt(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isConfirmed ? '✅ ยืนยัน' : '❌ ลบ',
                    style: GoogleFonts.prompt(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: resultColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Record Detail BottomSheet Dialog ─────────────────────────────────────────
  void _showRecordDetailDialog(BuildContext context, SwipeHistoryRecord r, bool isDark) {
    final isConfirmed = r.swipeResult == SwipeResult.confirmed;
    final resultColor = isConfirmed ? AppColors.success : AppColors.error;
    final amountColor = r.isIncome ? AppColors.income : AppColors.expense;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  BankLogoBadge(fallbackShortName: r.bankShortName, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.title,
                      style: GoogleFonts.prompt(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isConfirmed ? '✅ ยืนยันบันทึก' : '❌ ลบออก',
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              _detailRow('จำนวนเงิน', '${r.isIncome ? '+' : '-'}${CurrencyFormatter.format(r.amount)} บาท', valueColor: amountColor, isBold: true, isDark: isDark),
              _detailRow('ธนาคาร', r.bankShortName, isDark: isDark),
              _detailRow('หมวดหมู่', r.confirmedCategoryName + (r.categoryChanged ? ' (เปลี่ยนจาก: ${r.suggestedCategoryName})' : ''), isDark: isDark),
              _detailRow('เวลาที่ปัด', '${r.swipedAt.day}/${r.swipedAt.month}/${r.swipedAt.year} ${r.swipedAt.hour.toString().padLeft(2, '0')}:${r.swipedAt.minute.toString().padLeft(2, '0')} น.', isDark: isDark),
              if (r.rawText != null && r.rawText!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'ข้อความแจ้งเตือนดิบ:',
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    r.rawText!,
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor, bool isBold = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 11.5,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.prompt(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? (isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.history_rounded, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีประวัติการตรวจสอบ',
            style: GoogleFonts.prompt(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ประวัติจะปรากฏหลังจากปัดรายการตรวจพบ',
            style: GoogleFonts.prompt(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Export Footer ────────────────────────────────────────────────────────────
  Widget _buildExportFooter(BuildContext context, List<SwipeHistoryRecord> records, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : () => _exportCsv(context, records),
            icon: _isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, size: 16),
            label: Text(
              _isExporting
                  ? 'กำลัง Export...'
                  : 'Export CSV (${records.length} รายการ)',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Confirm Clear Dialog ─────────────────────────────────────────────────────
  void _confirmClear(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ล้างประวัติทั้งหมด?',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'ประวัติการปัดทั้งหมดจะถูกลบออก ไม่สามารถกู้คืนได้',
          style: GoogleFonts.prompt(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              context.read<AutoSyncCubit>().clearSwipeHistory();
              Navigator.pop(ctx);
            },
            child: Text('ล้างประวัติ', style: GoogleFonts.prompt(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
