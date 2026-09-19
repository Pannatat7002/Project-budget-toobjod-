import 'package:flutter/material.dart';

class BankProfile {
  final String id;
  final String name;
  final String shortName;
  final String packageName;
  final List<String> packageAliases;
  final int brandColor;
  final IconData icon;

  String get logoAsset => 'assets/images/banks/$id.png';

  const BankProfile({
    required this.id,
    required this.name,
    required this.shortName,
    required this.packageName,
    this.packageAliases = const [],
    required this.brandColor,
    required this.icon,
  });

  static const List<BankProfile> supportedBanks = [
    BankProfile(
      id: 'kbank',
      name: 'กสิกรไทย (K PLUS)',
      shortName: 'K PLUS',
      packageName: 'com.kasikorn.retail.mbanking.wap',
      packageAliases: ['com.kasikorn.bank', 'com.kasikornbank.kplus'],
      brandColor: 0xFF138F2D, // Green
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'scb',
      name: 'ไทยพาณิชย์ (SCB EASY)',
      shortName: 'SCB EASY',
      packageName: 'com.scb.phone',
      packageAliases: ['com.scb.easy'],
      brandColor: 0xFF4E2A84, // Purple
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'ktb',
      name: 'กรุงไทย (Krungthai NEXT)',
      shortName: 'Krungthai NEXT',
      packageName: 'ktbcs.netbank',
      packageAliases: ['ktb.cs.mobile.app', 'ktb.cs.netbank'],
      brandColor: 0xFF00A3E0, // Light Blue
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'bbl',
      name: 'กรุงเทพ (Bangkok Bank)',
      shortName: 'Bangkok Bank',
      packageName: 'com.bbl.mobilebanking',
      packageAliases: ['com.bbl.mBanking', 'com.bbl.mobilephone'],
      brandColor: 0xFF1E3A8A, // Deep Blue
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'ttb',
      name: 'ทีทีบี (ttb touch)',
      shortName: 'ttb touch',
      packageName: 'com.TMBTOUCH.PRODUCTION',
      packageAliases: ['com.ttbbank.oneapp', 'com.tmb.mbanking'],
      brandColor: 0xFF0056B3, // Blue/Orange
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'kma',
      name: 'กรุงศรี (KMA)',
      shortName: 'KMA Krungsri',
      packageName: 'com.krungsri.kma',
      packageAliases: ['com.bay.mbanking'],
      brandColor: 0xFFFDB913, // Yellow/Gold
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'truemoney',
      name: 'ทรูมันนี่ (TrueMoney)',
      shortName: 'TrueMoney',
      packageName: 'th.co.truemoney.wallet',
      packageAliases: ['com.truemoney', 'th.co.cenergy.tmn.wallet'],
      brandColor: 0xFFFF5B00, // Orange
      icon: Icons.account_balance_wallet,
    ),
    BankProfile(
      id: 'shopeepay',
      name: 'ช้อปปี้เพย์ (ShopeePay)',
      shortName: 'ShopeePay',
      packageName: 'com.beeasy.airpay',
      packageAliases: ['com.shopeepay.th', 'com.airpay'],
      brandColor: 0xFFEE4D2D, // Red Orange
      icon: Icons.shopping_bag,
    ),
    BankProfile(
      id: 'make_kbank',
      name: 'MAKE by KBank',
      shortName: 'MAKE',
      packageName: 'com.kasikornbank.makebykbank',
      packageAliases: ['com.kasikornbank.make', 'com.kbank.make'],
      brandColor: 0xFF2D8CFF, // Modern Blue
      icon: Icons.savings,
    ),
    BankProfile(
      id: 'gsb',
      name: 'ออมสิน (MyMo)',
      shortName: 'MyMo GSB',
      packageName: 'com.mobilife.gsb.mymo',
      packageAliases: ['com.gsb.mymo', 'com.my.mymo', 'com.dspread.mpos.mymo'],
      brandColor: 0xFFEB008B, // Pink
      icon: Icons.account_balance,
    ),
    BankProfile(
      id: 'dime',
      name: 'ไดม์ (Dime!)',
      shortName: 'Dime!',
      packageName: 'com.dimekkp.dimeapp',
      packageAliases: ['co.th.dime', 'com.kkp.dime'],
      brandColor: 0xFF00C781, // Teal Green
      icon: Icons.candlestick_chart,
    ),
    BankProfile(
      id: 'paotang',
      name: 'เป๋าตัง (Paotang)',
      shortName: 'เป๋าตัง',
      packageName: 'com.ktb.customer.qr',
      packageAliases: ['com.ktb.paotang'],
      brandColor: 0xFF00A3E0, // Cyan Blue
      icon: Icons.account_balance_wallet,
    ),
    BankProfile(
      id: 'kept',
      name: 'เคปท์ (Kept by Krungsri)',
      shortName: 'Kept',
      packageName: 'com.krungsri.kept',
      packageAliases: [],
      brandColor: 0xFF0075FF, // Vivid Blue
      icon: Icons.savings,
    ),
  ];

  /// Get all supported package names including aliases
  static List<String> get allSupportedPackages {
    final list = <String>[];
    for (final b in supportedBanks) {
      list.add(b.packageName);
      list.addAll(b.packageAliases);
    }
    return list;
  }

  static BankProfile? findByPackage(String pkg) {
    if (pkg.isEmpty) return null;
    final lowerPkg = pkg.toLowerCase().trim();
    try {
      // 1. Exact match on main packageName
      for (final b in supportedBanks) {
        if (b.packageName.toLowerCase() == lowerPkg) {
          return b;
        }
      }

      // 2. Exact match on packageAliases
      for (final b in supportedBanks) {
        if (b.packageAliases.any((a) => a.toLowerCase() == lowerPkg)) {
          return b;
        }
      }

      // 3. Fallback to package keyword matching
      if (lowerPkg.contains('kasikorn') || lowerPkg.contains('kplus')) return findById('kbank');
      if (lowerPkg.contains('scb')) return findById('scb');
      if (lowerPkg.contains('ktb')) return findById('ktb');
      if (lowerPkg.contains('bbl')) return findById('bbl');
      if (lowerPkg.contains('ttb') || lowerPkg.contains('tmb')) return findById('ttb');
      if (lowerPkg.contains('krungsri') || lowerPkg.contains('kma')) return findById('kma');
      if (lowerPkg.contains('truemoney')) return findById('truemoney');
      if (lowerPkg.contains('shopee') || lowerPkg.contains('airpay')) return findById('shopeepay');
      if (lowerPkg.contains('mymo') || lowerPkg.contains('gsb')) return findById('gsb');
      if (lowerPkg.contains('dime')) return findById('dime');
      if (lowerPkg.contains('paotang')) return findById('paotang');
      if (lowerPkg.contains('kept')) return findById('kept');

      return null;
    } catch (_) {
      return null;
    }
  }

  static BankProfile? findById(String id) {
    try {
      return supportedBanks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Resolves a BankProfile from various sources: bankId, bankName/shortName, packageName, or transaction note.
  static BankProfile? resolveBank({
    String? bankId,
    String? bankName,
    String? packageName,
    String? note,
  }) {
    // 1. Exact or normalized ID match
    if (bankId != null && bankId.trim().isNotEmpty) {
      final normalizedId = bankId.trim().toLowerCase();
      final found = findById(normalizedId);
      if (found != null) return found;
      for (final b in supportedBanks) {
        if (b.id.toLowerCase() == normalizedId || b.shortName.toLowerCase() == normalizedId) {
          return b;
        }
      }
    }

    // 2. Exact or normalized Package match
    if (packageName != null && packageName.trim().isNotEmpty) {
      final found = findByPackage(packageName.trim());
      if (found != null) return found;
    }

    // 3. Match from bankName / shortName
    if (bankName != null && bankName.trim().isNotEmpty) {
      final lower = bankName.trim().toLowerCase();
      for (final b in supportedBanks) {
        if (b.shortName.toLowerCase() == lower ||
            b.name.toLowerCase() == lower ||
            b.id.toLowerCase() == lower ||
            b.shortName.toLowerCase().contains(lower) ||
            b.name.toLowerCase().contains(lower) ||
            lower.contains(b.shortName.toLowerCase()) ||
            lower.contains(b.name.toLowerCase()) ||
            lower.contains(b.id.toLowerCase())) {
          return b;
        }
      }
    }

    // 4. Extract from note if available
    if (note != null && note.trim().isNotEmpty) {
      final lower = note.toLowerCase();
      if (lower.contains('k plus') || lower.contains('kplus') || lower.contains('kbank') || lower.contains('กสิกร')) {
        return findById('kbank');
      }
      if (lower.contains('scb') || lower.contains('ไทยพาณิชย์')) {
        return findById('scb');
      }
      if (lower.contains('ktb') || lower.contains('krungthai') || lower.contains('next') || lower.contains('กรุงไทย')) {
        return findById('ktb');
      }
      if (lower.contains('bbl') || lower.contains('bangkok bank') || lower.contains('บัวหลวง') || lower.contains('กรุงเทพ')) {
        return findById('bbl');
      }
      if (lower.contains('ttb') || lower.contains('tmb') || lower.contains('ทีทีบี')) {
        return findById('ttb');
      }
      if (lower.contains('kma') || lower.contains('krungsri') || lower.contains('กรุงศรี')) {
        return findById('kma');
      }
      if (lower.contains('truemoney') || lower.contains('true money') || lower.contains('ทรูมันนี่')) {
        return findById('truemoney');
      }
      if (lower.contains('shopee') || lower.contains('airpay') || lower.contains('ช้อปปี้')) {
        return findById('shopeepay');
      }
      if (lower.contains('mymo') || lower.contains('gsb') || lower.contains('ออมสิน')) {
        return findById('gsb');
      }
      if (lower.contains('dime') || lower.contains('ไดม์')) {
        return findById('dime');
      }
      if (lower.contains('paotang') || lower.contains('เป๋าตัง')) {
        return findById('paotang');
      }
      if (lower.contains('make') || lower.contains('เมค')) {
        return findById('make_kbank');
      }
      if (lower.contains('kept') || lower.contains('เคปท์')) {
        return findById('kept');
      }
    }

    return null;
  }
}
