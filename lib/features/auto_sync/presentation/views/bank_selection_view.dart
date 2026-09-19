import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../accounts/domain/entities/bank_account_entity.dart';
import '../../../accounts/presentation/state/account_cubit.dart';
import '../../../accounts/presentation/state/account_state.dart';
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
          'เพิ่มบัญชีธนาคาร & เชื่อมต่อ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: textColor,
          ),
        ),
      ),
      body: BlocBuilder<AccountCubit, AccountState>(
        builder: (context, accState) {
          return BlocBuilder<AutoSyncCubit, AutoSyncState>(
            builder: (context, syncState) {
              final autoCubit = context.read<AutoSyncCubit>();
              final accCubit = context.read<AccountCubit>();

              final filteredBanks = allBanks.where((b) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return b.name.toLowerCase().contains(q) ||
                    b.shortName.toLowerCase().contains(q) ||
                    b.id.toLowerCase().contains(q);
              }).toList();

              return Column(
                children: [
                  // Search & Info Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              hintText: 'ค้นหาธนาคาร (เช่น กสิกร, SCB, TrueMoney)...',
                              hintStyle: TextStyle(fontSize: 13, color: subtextColor),
                              prefixIcon: Icon(Icons.search, size: 20, color: subtextColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 18, color: subtextColor),
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
                        const SizedBox(height: 8),
                        Text(
                          '💡 เลือกธนาคารเพื่อเพิ่มบัญชีลงในแดชบอร์ด และเปิดระบบตรวจจับแจ้งเตือนอัตโนมัติ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
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
                                  'ไม่พบธนาคารที่ตรงกับ "$_searchQuery"',
                                  style: TextStyle(fontSize: 14, color: subtextColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
                            itemCount: filteredBanks.length,
                            itemBuilder: (context, index) {
                              final bank = filteredBanks[index];

                              // Check if user already added an account for this bank
                              final existingAccounts = accState.accounts.where((a) => a.bankId == bank.id).toList();
                              final isAccountAdded = existingAccounts.isNotEmpty;
                              final existingAcc = isAccountAdded ? existingAccounts.first : null;

                              // Check if auto-sync package is enabled
                              final isSyncEnabled = syncState.enabledBankPackages.isEmpty ||
                                  syncState.enabledBankPackages.contains(bank.packageName) ||
                                  bank.packageAliases.any((a) => syncState.enabledBankPackages.contains(a));

                              final brandColor = Color(bank.brandColor);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isAccountAdded
                                        ? brandColor.withAlpha(isDark ? 90 : 120)
                                        : borderColor,
                                    width: isAccountAdded ? 1.4 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isAccountAdded
                                          ? brandColor.withAlpha(isDark ? 25 : 10)
                                          : Colors.black.withAlpha(isDark ? 20 : 4),
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
                                    onTap: () {
                                      if (isAccountAdded) {
                                        _showManageAccountSheet(context, bank, existingAcc!);
                                      } else {
                                        _showAddAccountSheet(context, bank);
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Bank Logo Badge
                                          BankLogoBadge(
                                            bankId: bank.id,
                                            packageName: bank.packageName,
                                            fallbackShortName: bank.shortName,
                                            fallbackColorValue: bank.brandColor,
                                            size: 46,
                                            borderRadius: 12,
                                          ),
                                          const SizedBox(width: 14),

                                          // Bank Name & Account Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        bank.name,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: textColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                if (isAccountAdded) ...[
                                                   Wrap(
                                                     spacing: 6,
                                                     runSpacing: 2,
                                                     crossAxisAlignment: WrapCrossAlignment.center,
                                                     children: [
                                                       Container(
                                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                         decoration: BoxDecoration(
                                                           color: brandColor.withAlpha(25),
                                                           borderRadius: BorderRadius.circular(6),
                                                         ),
                                                         child: Text(
                                                           existingAcc!.accountMask != null
                                                               ? '${existingAcc.accountName} • ${existingAcc.accountMask}'
                                                               : existingAcc.accountName,
                                                           style: TextStyle(
                                                             fontSize: 10.5,
                                                             fontWeight: FontWeight.w700,
                                                             color: brandColor,
                                                           ),
                                                           maxLines: 1,
                                                           overflow: TextOverflow.ellipsis,
                                                         ),
                                                       ),
                                                       Text(
                                                         isSyncEnabled ? '🟢 ตรวจจับสดเปิด' : '⚪ ปิดตรวจจับ',
                                                         style: TextStyle(
                                                           fontSize: 11,
                                                           color: isSyncEnabled
                                                               ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                                               : subtextColor,
                                                           fontWeight: FontWeight.w600,
                                                         ),
                                                         maxLines: 1,
                                                         overflow: TextOverflow.ellipsis,
                                                       ),
                                                     ],
                                                   ),
                                                ] else ...[
                                                  Text(
                                                    'แตะเพื่อเพิ่มบัญชีและเชื่อมต่อ',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: subtextColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),

                                          // Action Widget: Switch if added, or "+ เพิ่ม" pill button
                                          if (isAccountAdded) ...[
                                            Switch.adaptive(
                                              value: isSyncEnabled,
                                              activeThumbColor: brandColor,
                                              onChanged: (val) {
                                                autoCubit.toggleBankPackage(bank.packageName, val);
                                                for (final alias in bank.packageAliases) {
                                                  autoCubit.toggleBankPackage(alias, val);
                                                }
                                                accCubit.addOrUpdateAccount(
                                                  existingAcc!.copyWith(isAutoSyncActive: val),
                                                );
                                              },
                                            ),
                                          ] else ...[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: brandColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () => _showAddAccountSheet(context, bank),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.add, size: 15),
                                                  SizedBox(width: 2),
                                                  Text('เพิ่มบัญชี', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
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
          );
        },
      ),
    );
  }

  /// Bottom Sheet to Add Bank Account & Connect Auto-Sync
  void _showAddAccountSheet(BuildContext context, BankProfile bank) {
    final nameController = TextEditingController(text: bank.shortName);
    final maskController = TextEditingController();
    bool enableAutoSync = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = Color(bank.brandColor);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: bottomInset > 0
                    ? bottomInset + 16
                    : (28 + MediaQuery.of(ctx).padding.bottom),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header: Logo + Title
                  Row(
                    children: [
                      BankLogoBadge(
                        bankId: bank.id,
                        packageName: bank.packageName,
                        fallbackShortName: bank.shortName,
                        fallbackColorValue: bank.brandColor,
                        size: 44,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เพิ่มบัญชี ${bank.shortName}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bank.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Nickname input
                  const Text(
                    'ชื่อเรียกบัญชี:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'เช่น ${bank.shortName} เงินเดือน, บัญชีหลัก',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account mask input
                  const Text(
                    'เลขบัญชี 4 ตัวท้าย (ถ้ามี):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: maskController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'เช่น 1234 (ช่วยจับคู่สลิปให้ตรงบัญชี)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Auto-sync switch toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorderSubtle : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: brandColor, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('เปิดตรวจจับแจ้งเตือนอัตโนมัติ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text('ตรวจจับสลิป/เงินเข้าออกของแอปนี้', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                              ],
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: enableAutoSync,
                          activeThumbColor: brandColor,
                          onChanged: (val) => setSheetState(() => enableAutoSync = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final enteredName = nameController.text.trim();
                        final enteredMask = maskController.text.trim();

                        final accCubit = context.read<AccountCubit>();
                        final autoCubit = context.read<AutoSyncCubit>();

                        final newAccount = BankAccountEntity(
                          id: 'acc_${bank.id}_${DateTime.now().millisecondsSinceEpoch % 10000}',
                          bankId: bank.id,
                          bankName: bank.name,
                          accountName: enteredName.isEmpty ? bank.shortName : enteredName,
                          accountMask: enteredMask.isNotEmpty ? 'x-$enteredMask' : null,
                          currentBalance: 0.0,
                          brandColor: bank.brandColor,
                          isAutoSyncActive: enableAutoSync,
                          createdAt: DateTime.now(),
                        );

                        await accCubit.addOrUpdateAccount(newAccount);
                        if (enableAutoSync) {
                          autoCubit.toggleBankPackage(bank.packageName, true);
                        }
                        accCubit.selectBank(bank.id);

                        if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                        }

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ เพิ่มบัญชี "${newAccount.accountName}" เรียบร้อยแล้ว พร้อมใช้งานบนแดชบอร์ด'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        '+ เพิ่มบัญชีธนาคารนี้',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet to Manage / Edit Existing Bank Account
  void _showManageAccountSheet(BuildContext context, BankProfile bank, BankAccountEntity account) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = Color(bank.brandColor);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  BankLogoBadge(
                    bankId: bank.id,
                    packageName: bank.packageName,
                    fallbackShortName: bank.shortName,
                    fallbackColorValue: bank.brandColor,
                    size: 44,
                    borderRadius: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountName,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${bank.name} ${account.accountMask != null ? '• ${account.accountMask}' : ''}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // View on Dashboard button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandColor,
                    side: BorderSide(color: brandColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    context.read<AccountCubit>().selectBank(bank.id);
                    Navigator.of(sheetCtx).pop();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.credit_card_rounded, size: 18),
                  label: const Text('ดูบัตรบัญชีนี้บนแดชบอร์ด', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              // Delete Account button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _showDeleteConfirmDialog(context, account);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('ลบบัญชีนี้ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, BankAccountEntity account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันลบบัญชี'),
        content: Text('คุณต้องการลบบัญชี "${account.accountName}" ออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final accCubit = context.read<AccountCubit>();
              await accCubit.deleteAccount(account.id);
              if (accCubit.state.selectedBankId == account.bankId) {
                accCubit.selectBank(null);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ ลบบัญชี "${account.accountName}" แล้ว'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
  }
}
