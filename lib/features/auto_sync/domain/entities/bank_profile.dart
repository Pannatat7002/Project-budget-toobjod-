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
}
