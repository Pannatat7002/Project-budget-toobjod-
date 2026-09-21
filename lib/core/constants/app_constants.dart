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

  // Unified Default Categories for Expense (Rich & Vibrant Semantic Palette)
  static const List<CategoryItem> defaultExpenseCategories = [
    CategoryItem(
      id: 'food',
      name: 'อาหาร & เครื่องดื่ม',
      iconCode: 0xe532, // restaurant
      colorValue: 0xFFEF4444, // Red
    ),
    CategoryItem(
      id: 'transport',
      name: 'การเดินทาง & ค่าน้ำมัน',
      iconCode: 0xe1d5, // directions_car
      colorValue: 0xFFF59E0B, // Amber
    ),
    CategoryItem(
      id: 'bills',
      name: 'ที่พัก & สาธารณูปโภค',
      iconCode: 0xe88a, // home
      colorValue: 0xFF6366F1, // Indigo
    ),
    CategoryItem(
      id: 'debts',
      name: 'ภาระประจำ & หนี้สิน',
      iconCode: 0xe870, // credit_card
      colorValue: 0xFF2563EB, // Blue
    ),
    CategoryItem(
      id: 'shopping',
      name: 'ช้อปปิ้ง & ของใช้',
      iconCode: 0xe59c, // shopping_bag
      colorValue: 0xFFEC4899, // Pink
    ),
    CategoryItem(
      id: 'entertainment',
      name: 'ความบันเทิง & ท่องเที่ยว',
      iconCode: 0xe40f, // movie
      colorValue: 0xFF8B5CF6, // Purple
    ),
    CategoryItem(
      id: 'health',
      name: 'สุขภาพ & ยา',
      iconCode: 0xe3fa, // medical_services
      colorValue: 0xFF10B981, // Emerald
    ),
    CategoryItem(
      id: 'savings',
      name: 'เงินออม & ลงทุน',
      iconCode: 0xe801, // savings
      colorValue: 0xFF14B8A6, // Teal
    ),
    CategoryItem(
      id: 'other',
      name: 'อื่นๆ',
      iconCode: 0xe41d, // more_horiz
      colorValue: 0xFF64748B, // Slate
    ),
  ];

  static const CategoryItem transferCategory = CategoryItem(
    id: 'transfer',
    name: 'โอนย้ายเงิน',
    iconCode: 0xe8d4, // swap_horiz
    colorValue: 0xFF6366F1, // Indigo
  );

  // Default Categories for Income
  static const List<CategoryItem> defaultIncomeCategories = [
    CategoryItem(
      id: 'salary',
      name: 'เงินเดือน & ค่าจ้าง',
      iconCode: 0xe040, // payments
      colorValue: 0xFF10B981, // Emerald
    ),
    CategoryItem(
      id: 'bonus',
      name: 'โบนัส & ค่าคอมมิชชัน',
      iconCode: 0xe11b, // card_giftcard
      colorValue: 0xFF14B8A6, // Teal
    ),
    CategoryItem(
      id: 'investment',
      name: 'ปันผล & ดอกเบี้ย/ลงทุน',
      iconCode: 0xe66e, // trending_up
      colorValue: 0xFF3B82F6, // Blue
    ),
    CategoryItem(
      id: 'freelance',
      name: 'งานเสริม & ฟรีแลนซ์',
      iconCode: 0xe3e3, // laptop_mac
      colorValue: 0xFF8B5CF6, // Purple
    ),
    CategoryItem(
      id: 'transfer',
      name: 'โอนย้ายเงิน',
      iconCode: 0xe8d4, // swap_horiz
      colorValue: 0xFF6366F1, // Indigo
    ),
    CategoryItem(
      id: 'other_income',
      name: 'รายรับอื่นๆ',
      iconCode: 0xe41d, // more_horiz
      colorValue: 0xFF64748B, // Slate
    ),
    CategoryItem(
      id: 'reconciliation_income',
      name: 'ปรับปรุงยอดเงินเพิ่ม',
      iconCode: 0xe8af, // tune
      colorValue: 0xFF10B981, // Emerald
    ),
  ];
}

class CategoryItem {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String? assetPath;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.assetPath,
  });

  IconData get icon => IconHelper.getIcon(iconCode);
  Color get color => Color(colorValue);
  String get imageAsset => assetPath ?? 'assets/images/categories/cat_$id.png';
}
