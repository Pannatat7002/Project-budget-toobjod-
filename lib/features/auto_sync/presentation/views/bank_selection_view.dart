import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/bank_profile.dart';
import '../state/auto_sync_cubit.dart';
import '../state/auto_sync_state.dart';
import '../widgets/bank_logo_badge.dart';

class BankSelectionView extends StatefulWidget {
  const BankSelectionView({super.key});

  @override
  State<BankSelectionView> createState() => _BankSelectionViewState();
}

class _BankSelectionViewState extends State<BankSelectionView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final allBanks = BankProfile.supportedBanks;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'เลือกแอปธนาคารตรวจจับ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AutoSyncCubit, AutoSyncState>(
        builder: (context, state) {
          final cubit = context.read<AutoSyncCubit>();

          final enabledCount = state.enabledBankPackages.isEmpty
              ? allBanks.length
              : allBanks.where((b) => state.enabledBankPackages.contains(b.packageName)).length;

          final isAllEnabled = enabledCount == allBanks.length;

          // Filter by search
          final filteredBanks = allBanks.where((b) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return b.name.toLowerCase().contains(q) ||
                b.shortName.toLowerCase().contains(q) ||
                b.id.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              // Search & Master Toggle Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาแอปธนาคาร (เช่น กสิกร, SCB, TrueMoney)...',
                          hintStyle: TextStyle(fontSize: 13, color: subtextColor),
                          prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, color: subtextColor, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Select All Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withAlpha(80)),
                              ),
                              child: Text(
                                'เปิดใช้งาน $enabledCount จาก ${allBanks.length} แอป',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'เปิดทั้งหมด',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Switch.adaptive(
                              value: isAllEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => cubit.toggleAllBankPackages(val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: borderColor),

              // Bank List
              Expanded(
                child: filteredBanks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: subtextColor.withAlpha(120)),
                            const SizedBox(height: 12),
                            Text(
                              'ไม่พบแอปธนาคารที่ตรงกับ "$_searchQuery"',
                              style: TextStyle(fontSize: 14, color: subtextColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filteredBanks.length,
                        itemBuilder: (context, index) {
                          final bank = filteredBanks[index];
                          final isEnabled = state.enabledBankPackages.isEmpty ||
                              state.enabledBankPackages.contains(bank.packageName);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isEnabled
                                    ? Color(bank.brandColor).withAlpha(isDark ? 90 : 120)
                                    : borderColor,
                                width: isEnabled ? 1.3 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isEnabled
                                      ? Color(bank.brandColor).withAlpha(isDark ? 30 : 12)
                                      : Colors.black.withAlpha(isDark ? 30 : 5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => cubit.toggleBankPackage(bank.packageName, !isEnabled),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Real Bank Logo Badge (46px)
                                      BankLogoBadge(
                                        bankId: bank.id,
                                        packageName: bank.packageName,
                                        fallbackShortName: bank.shortName,
                                        fallbackColorValue: bank.brandColor,
                                        size: 46,
                                        borderRadius: 12,
                                      ),
                                      const SizedBox(width: 14),

                                      // Bank Name & Description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bank.name,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(bank.brandColor).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    bank.shortName,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(bank.brandColor),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isEnabled ? 'เปิดตรวจจับอยู่' : 'ปิดการตรวจจับ',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isEnabled
                                                        ? (isDark
                                                            ? const Color(0xFF4ADE80)
                                                            : const Color(0xFF16A34A))
                                                        : subtextColor,
                                                    fontWeight: isEnabled
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Active Switch
                                      Switch.adaptive(
                                        value: isEnabled,
                                        activeThumbColor: Color(bank.brandColor),
                                        onChanged: (val) =>
                                            cubit.toggleBankPackage(bank.packageName, val),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
