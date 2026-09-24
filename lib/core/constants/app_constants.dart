import 'package:flutter/material.dart';
import '../utils/icon_helper.dart';

class AppConstants {
  static const String appName = 'เจ้าตูบจด';
  static const String appTagline = 'ผู้ช่วยวางแผนคุมงบการเงิน 🐾';

  // Storage Keys (Clean Production Live v1 - No Mock Data)
  static const String transactionsStorageKey = 'bp_transactions_live_v1';
  static const String budgetsStorageKey = 'bp_budgets_live_v1';
  static const String userPreferencesStorageKey = 'bp_user_prefs_live_v1';
  static const String accountsStorageKey = 'bp_bank_accounts_live_v1';
  static const String accountEyeViewKey = 'bp_account_eye_view_live_v1';
  static const String customDogNameKey = 'bp_custom_dog_name_live_v1';
  static const String lastSplashDateKey = 'bp_last_splash_date_v1';
  static const String recurringTransactionsStorageKey = 'bp_recurring_transactions_live_v1';

  // Unified Default Categories for Expense (Rich & Vibrant Semantic Palette)
  static const List<CategoryItem> defaultExpenseCategories = [
    CategoryItem(
      id: 'food',
      name: 'อาหาร & เครื่องดื่ม',
      iconCode: 0xe532, // restaurant
      colorValue: 0xFFEF4444, // Red
      macroPillar: MacroPillar.needs,
      defaultTags: ['#มื้อเที่ยง', '#กาแฟ', '#มื้อเย็น', '#ของกินเล่น', '#เดลิเวอรี่'],
    ),
    CategoryItem(
      id: 'transport',
      name: 'การเดินทาง & ค่าน้ำมัน',
      iconCode: 0xe1d5, // directions_car
      colorValue: 0xFFF59E0B, // Amber
      macroPillar: MacroPillar.needs,
      defaultTags: ['#ค่าน้ำมัน', '#รถไฟฟ้า', '#แท็กซี่', '#ค่าทางด่วน', '#ซ่อมรถ'],
    ),
    CategoryItem(
      id: 'bills',
      name: 'ที่พัก & สาธารณูปโภค',
      iconCode: 0xe88a, // home
      colorValue: 0xFF6366F1, // Indigo
      macroPillar: MacroPillar.needs,
      defaultTags: ['#ค่าไฟ', '#ค่าน้ำ', '#ค่าเน็ต', '#ค่าเช่าหอ', '#ส่วนกลาง'],
    ),
    CategoryItem(
      id: 'debts',
      name: 'ภาระประจำ & หนี้สิน',
      iconCode: 0xe870, // credit_card
      colorValue: 0xFF2563EB, // Blue
      macroPillar: MacroPillar.needs,
      defaultTags: ['#ผ่อนบ้าน', '#ผ่อนรถ', '#บัตรเครดิต', '#กู้กยศ'],
    ),
    CategoryItem(
      id: 'shopping',
      name: 'ช้อปปิ้ง & ของใช้',
      iconCode: 0xe59c, // shopping_bag
      colorValue: 0xFFEC4899, // Pink
      macroPillar: MacroPillar.wants,
      defaultTags: ['#เสื้อผ้า', '#Shopee', '#Lazada', '#ของใช้ส่วนตัว', '#เครื่องสำอาง'],
    ),
    CategoryItem(
      id: 'entertainment',
      name: 'ความบันเทิง & ท่องเที่ยว',
      iconCode: 0xe40f, // movie
      colorValue: 0xFF8B5CF6, // Purple
      macroPillar: MacroPillar.wants,
      defaultTags: ['#ดูหนัง', '#Netflix', '#เกม', '#คอนเสิร์ต', '#ปาร์ตี้'],
    ),
    CategoryItem(
      id: 'health',
      name: 'สุขภาพ & ยา',
      iconCode: 0xe3fa, // medical_services
      colorValue: 0xFF10B981, // Emerald
      macroPillar: MacroPillar.needs,
      defaultTags: ['#ค่ายา', '#หาหมอ', '#ตรวจสุขภาพ', '#อาหารเสริม'],
    ),
    CategoryItem(
      id: 'savings',
      name: 'เงินออม & ลงทุน',
      iconCode: 0xe801, // savings
      colorValue: 0xFF14B8A6, // Teal
      macroPillar: MacroPillar.savings,
      defaultTags: ['#เงินออม', '#กองทุน', '#หุ้น', '#คริปโต', '#สำรองฉุกเฉิน'],
    ),
    CategoryItem(
      id: 'other',
      name: 'อื่นๆ',
      iconCode: 0xe41d, // more_horiz
      colorValue: 0xFF64748B, // Slate
      macroPillar: MacroPillar.wants,
      defaultTags: ['#เบ็ดเตล็ด', '#ทำบุญ', '#ของขวัญ'],
    ),
  ];

  static const CategoryItem transferCategory = CategoryItem(
    id: 'transfer',
    name: 'โอนย้ายเงิน',
    iconCode: 0xe8d4, // swap_horiz
    colorValue: 0xFF6366F1, // Indigo
    macroPillar: MacroPillar.savings,
    defaultTags: ['#โอนย้ายเงิน', '#เก็บเงิน', '#บัญชีสำรอง'],
  );

  // Default Categories for Income
  static const List<CategoryItem> defaultIncomeCategories = [
    CategoryItem(
      id: 'salary',
      name: 'เงินเดือน & ค่าจ้าง',
      iconCode: 0xe040, // payments
      colorValue: 0xFF10B981, // Emerald
      macroPillar: MacroPillar.income,
      defaultTags: ['#เงินเดือน', '#ค่าจ้าง', '#OT'],
    ),
    CategoryItem(
      id: 'bonus',
      name: 'โบนัส & ค่าคอมมิชชัน',
      iconCode: 0xe11b, // card_giftcard
      colorValue: 0xFF14B8A6, // Teal
      macroPillar: MacroPillar.income,
      defaultTags: ['#โบนัส', '#ค่าคอม', '#รางวัล'],
    ),
    CategoryItem(
      id: 'investment',
      name: 'ปันผล & ดอกเบี้ย/ลงทุน',
      iconCode: 0xe66e, // trending_up
      colorValue: 0xFF3B82F6, // Blue
      macroPillar: MacroPillar.income,
      defaultTags: ['#เงินปันผล', '#ดอกเบี้ย', '#กำไรหุ้น'],
    ),
    CategoryItem(
      id: 'freelance',
      name: 'งานเสริม & ฟรีแลนซ์',
      iconCode: 0xe3e3, // laptop_mac
      colorValue: 0xFF8B5CF6, // Purple
      macroPillar: MacroPillar.income,
      defaultTags: ['#งานเสริม', '#ฟรีแลนซ์', '#ขายของ'],
    ),
    CategoryItem(
      id: 'transfer',
      name: 'โอนย้ายเงิน',
      iconCode: 0xe8d4, // swap_horiz
      colorValue: 0xFF6366F1, // Indigo
      macroPillar: MacroPillar.savings,
      defaultTags: ['#โอนย้ายเงิน', '#รับโอน'],
    ),
    CategoryItem(
      id: 'other_income',
      name: 'รายรับอื่นๆ',
      iconCode: 0xe41d, // more_horiz
      colorValue: 0xFF64748B, // Slate
      macroPillar: MacroPillar.income,
      defaultTags: ['#รายรับอื่นๆ', '#เงินคืน'],
    ),
    CategoryItem(
      id: 'reconciliation_income',
      name: 'ปรับปรุงยอดเงินเพิ่ม',
      iconCode: 0xe8af, // tune
      colorValue: 0xFF10B981, // Emerald
      macroPillar: MacroPillar.income,
      defaultTags: ['#ปรับปรุงยอด'],
    ),
  ];
}

enum MacroPillar {
  needs,    // สิ่งจำเป็น (Needs / 50% - Fixed & Essentials)
  wants,    // ความสุข & ไลฟ์สไตล์ (Wants / 30% - Flexible & Joy)
  savings,  // เพื่ออนาคต (Savings / 20% - Future & Investment)
  income,   // รายรับ (Income)
}

extension MacroPillarX on MacroPillar {
  String get title {
    switch (this) {
      case MacroPillar.needs:
        return 'สิ่งจำเป็น (Needs)';
      case MacroPillar.wants:
        return 'ความสุข & ไลฟ์สไตล์ (Wants)';
      case MacroPillar.savings:
        return 'เพื่ออนาคต (Savings)';
      case MacroPillar.income:
        return 'รายรับ (Income)';
    }
  }

  String get shortTitle {
    switch (this) {
      case MacroPillar.needs:
        return 'สิ่งจำเป็น';
      case MacroPillar.wants:
        return 'ความสุข';
      case MacroPillar.savings:
        return 'เพื่ออนาคต';
      case MacroPillar.income:
        return 'รายรับ';
    }
  }

  IconData get icon {
    switch (this) {
      case MacroPillar.needs:
        return Icons.home_rounded;
      case MacroPillar.wants:
        return Icons.shopping_bag_rounded;
      case MacroPillar.savings:
        return Icons.savings_rounded;
      case MacroPillar.income:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color get color {
    switch (this) {
      case MacroPillar.needs:
        return const Color(0xFF2563EB); // Royal Blue
      case MacroPillar.wants:
        return const Color(0xFFEC4899); // Vibrant Pink
      case MacroPillar.savings:
        return const Color(0xFF10B981); // Emerald Green
      case MacroPillar.income:
        return const Color(0xFFFF7A00); // Shiba Orange
    }
  }
}

class CategoryItem {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String? assetPath;
  final MacroPillar macroPillar;
  final List<String> defaultTags;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.assetPath,
    this.macroPillar = MacroPillar.needs,
    this.defaultTags = const [],
  });

  IconData get icon => IconHelper.getIcon(iconCode);
  Color get color => Color(colorValue);
  String get imageAsset =>
      assetPath ??
      (IconHelper.getCategoryAsset(id, categoryName: name) ??
          'assets/images/categories/cat_other.png');
}
