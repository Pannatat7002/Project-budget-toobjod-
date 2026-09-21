import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIcon(int code) {
    switch (code) {
      case 0xe532:
        return Icons.restaurant_rounded; // อาหาร & เครื่องดื่ม
      case 0xe1d5:
        return Icons.directions_car_rounded; // การเดินทาง & ค่าน้ำมัน
      case 0xe88a:
        return Icons.home_rounded; // ที่พัก & สาธารณูปโภค
      case 0xe870:
        return Icons.credit_card_rounded; // บัตรเครดิต & หนี้สิน
      case 0xe59c:
        return Icons.shopping_bag_rounded; // ช้อปปิ้ง & ของใช้
      case 0xe40f:
        return Icons.movie_rounded; // ความบันเทิง & ท่องเที่ยว
      case 0xe3fa:
        return Icons.medical_services_rounded; // สุขภาพ & ยา
      case 0xe801:
        return Icons.savings_rounded; // เงินออม & ลงทุน
      case 0xe040:
        return Icons.payments_rounded; // เงินเดือน & รายรับ
      case 0xe11b:
        return Icons.card_giftcard_rounded; // โบนัส & ค่าคอม
      case 0xe66e:
        return Icons.trending_up_rounded; // ลงทุน & ดอกเบี้ย
      case 0xe3e3:
        return Icons.laptop_mac_rounded; // ฟรีแลนซ์ & งานเสริม
      case 0xe41d:
        return Icons.more_horiz_rounded; // อื่นๆ
      case 0xe54e:
        return Icons.pie_chart_rounded; // แผนงบประมาณ
      default:
        return Icons.category_rounded;
    }
  }

  /// Get smart icon based on category name, title, or iconCode
  static IconData getSmartIcon({String? categoryName, String? title, int? code}) {
    if (code != null && code != 0 && code != 0xe41d && code != 0xe574) {
      final icon = getIcon(code);
      if (icon != Icons.category_rounded && icon != Icons.more_horiz_rounded) {
        return icon;
      }
    }

    final query = '${categoryName ?? ''} ${title ?? ''}'.toLowerCase();
    if (query.contains('อาหาร') || query.contains('กิน') || query.contains('ข้าว') || query.contains('food') || query.contains('cafe') || query.contains('กาแฟ') || query.contains('ขนม') || query.contains('ชาบู') || query.contains('kfc')) {
      return Icons.restaurant_rounded;
    }
    if (query.contains('เดินทาง') || query.contains('รถ') || query.contains('น้ำมัน') || query.contains('bts') || query.contains('mrt') || query.contains('grab') || query.contains('taxi') || query.contains('transport')) {
      return Icons.directions_car_rounded;
    }
    if (query.contains('บ้าน') || query.contains('ห้อง') || query.contains('ไฟ') || query.contains('น้ำ') || query.contains('เน็ต') || query.contains('บิล') || query.contains('bills') || query.contains('ที่พัก')) {
      return Icons.home_rounded;
    }
    if (query.contains('บัตร') || query.contains('หนี้') || query.contains('งวด') || query.contains('card') || query.contains('loan') || query.contains('ผ่อน')) {
      return Icons.credit_card_rounded;
    }
    if (query.contains('ช้อป') || query.contains('ซื้อ') || query.contains('shop') || query.contains('เซเว่น') || query.contains('7-eleven') || query.contains('ตลาด') || query.contains('ของใช้')) {
      return Icons.shopping_bag_rounded;
    }
    if (query.contains('เที่ยว') || query.contains('หนัง') || query.contains('เกม') || query.contains('บันเทิง') || query.contains('netflix') || query.contains('entertainment')) {
      return Icons.movie_rounded;
    }
    if (query.contains('ยา') || query.contains('แพทย์') || query.contains('หมอ') || query.contains('สุขภาพ') || query.contains('health') || query.contains('clinic') || query.contains('โรงพยาบาล')) {
      return Icons.medical_services_rounded;
    }
    if (query.contains('ออม') || query.contains('ฝาก') || query.contains('savings')) {
      return Icons.savings_rounded;
    }
    if (query.contains('เดือน') || query.contains('เงินเดือน') || query.contains('salary') || query.contains('ค่าจ้าง')) {
      return Icons.payments_rounded;
    }
    if (query.contains('โบนัส') || query.contains('bonus') || query.contains('ของขวัญ')) {
      return Icons.card_giftcard_rounded;
    }
    if (query.contains('ลงทุน') || query.contains('หุ้น') || query.contains('ปันผล') || query.contains('invest') || query.contains('ดอกเบี้ย')) {
      return Icons.trending_up_rounded;
    }
    if (query.contains('ฟรีแลนซ์') || query.contains('งานเสริม') || query.contains('freelance')) {
      return Icons.laptop_mac_rounded;
    }
    if (query.contains('ถอน') || query.contains('กดเงิน') || query.contains('atm')) {
      return Icons.local_atm_rounded;
    }
    if (query.contains('โอน') || query.contains('transfer')) {
      return Icons.swap_horiz_rounded;
    }
    if (query.contains('อื่นๆ') || query.contains('other') || code == 0xe41d) {
      return Icons.more_horiz_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  /// Get 3D asset image path for category if available
  static String? getCategoryAsset(String? categoryId, {String? categoryName, String? title}) {
    if (categoryId != null &&
        categoryId.isNotEmpty &&
        categoryId != 'other' &&
        categoryId != 'other_income' &&
        categoryId != 'uncategorized' &&
        categoryId != 'unknown') {
      return 'assets/images/categories/cat_$categoryId.png';
    }

    final query = '${categoryName ?? ''} ${title ?? ''}'.toLowerCase();
    if (query.contains('อาหาร') || query.contains('กิน') || query.contains('ข้าว') || query.contains('food') || query.contains('cafe') || query.contains('กาแฟ') || query.contains('ขนม') || query.contains('ชาบู') || query.contains('kfc') || query.contains('grab food')) {
      return 'assets/images/categories/cat_food.png';
    }
    if (query.contains('เดินทาง') || query.contains('รถ') || query.contains('น้ำมัน') || query.contains('bts') || query.contains('mrt') || query.contains('grab') || query.contains('taxi') || query.contains('transport')) {
      return 'assets/images/categories/cat_transport.png';
    }
    if (query.contains('บ้าน') || query.contains('ห้อง') || query.contains('ไฟ') || query.contains('น้ำ') || query.contains('เน็ต') || query.contains('บิล') || query.contains('bills') || query.contains('ที่พัก')) {
      return 'assets/images/categories/cat_bills.png';
    }
    if (query.contains('บัตร') || query.contains('หนี้') || query.contains('งวด') || query.contains('card') || query.contains('loan') || query.contains('ผ่อน')) {
      return 'assets/images/categories/cat_debts.png';
    }
    if (query.contains('ช้อป') || query.contains('ซื้อ') || query.contains('shop') || query.contains('เซเว่น') || query.contains('7-eleven') || query.contains('ตลาด') || query.contains('ของใช้') || query.contains('shopee') || query.contains('lazada')) {
      return 'assets/images/categories/cat_shopping.png';
    }
    if (query.contains('เที่ยว') || query.contains('หนัง') || query.contains('เกม') || query.contains('บันเทิง') || query.contains('netflix') || query.contains('entertainment')) {
      return 'assets/images/categories/cat_entertainment.png';
    }
    if (query.contains('ยา') || query.contains('แพทย์') || query.contains('หมอ') || query.contains('สุขภาพ') || query.contains('health') || query.contains('clinic') || query.contains('โรงพยาบาล')) {
      return 'assets/images/categories/cat_health.png';
    }
    if (query.contains('ออม') || query.contains('ฝาก') || query.contains('savings')) {
      return 'assets/images/categories/cat_savings.png';
    }
    if (query.contains('เดือน') || query.contains('เงินเดือน') || query.contains('salary') || query.contains('ค่าจ้าง')) {
      return 'assets/images/categories/cat_salary.png';
    }
    if (query.contains('โบนัส') || query.contains('bonus') || query.contains('ของขวัญ')) {
      return 'assets/images/categories/cat_bonus.png';
    }
    if (query.contains('ลงทุน') || query.contains('หุ้น') || query.contains('ปันผล') || query.contains('invest') || query.contains('ดอกเบี้ย')) {
      return 'assets/images/categories/cat_investment.png';
    }
    if (query.contains('ฟรีแลนซ์') || query.contains('งานเสริม') || query.contains('freelance')) {
      return 'assets/images/categories/cat_freelance.png';
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      return 'assets/images/categories/cat_$categoryId.png';
    }
    return null;
  }
}
