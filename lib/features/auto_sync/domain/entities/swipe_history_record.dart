import 'package:equatable/equatable.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// ผลลัพธ์การปัด (Swipe Result)
enum SwipeResult {
  confirmed,  // ปัดขวา: ยืนยันบันทึก ✅
  discarded,  // ปัดซ้าย: ไม่ถูกต้อง / ลบ ❌
}

extension SwipeResultExtension on SwipeResult {
  String get label => this == SwipeResult.confirmed ? 'ยืนยัน' : 'ไม่ถูกต้อง';
  String get labelEn => this == SwipeResult.confirmed ? 'confirmed' : 'discarded';
  String get emoji => this == SwipeResult.confirmed ? '✅' : '❌';
}

/// บันทึกประวัติการปัดรายการตรวจพบแต่ละครั้ง
class SwipeHistoryRecord extends Equatable {
  final String id;

  /// เวลาที่ปัด
  final DateTime swipedAt;

  /// รายการ (ชื่อ)
  final String title;

  /// ธนาคาร
  final String bankShortName;

  /// ประเภทรายการ (income/expense)
  final TransactionType type;

  /// จำนวนเงิน
  final double amount;

  /// หมวดหมู่ที่ระบบแนะนำ (ก่อนปัด)
  final String suggestedCategoryName;
  final String suggestedCategoryId;

  /// หมวดหมู่ที่ user เลือกจริง (อาจเปลี่ยนจากที่แนะนำ)
  final String confirmedCategoryName;
  final String confirmedCategoryId;

  /// ผลการปัด
  final SwipeResult swipeResult;

  /// ข้อความดิบจาก Notification
  final String? rawText;

  const SwipeHistoryRecord({
    required this.id,
    required this.swipedAt,
    required this.title,
    required this.bankShortName,
    required this.type,
    required this.amount,
    required this.suggestedCategoryName,
    required this.suggestedCategoryId,
    required this.confirmedCategoryName,
    required this.confirmedCategoryId,
    required this.swipeResult,
    this.rawText,
  });

  bool get isIncome => type == TransactionType.income;
  bool get categoryChanged => suggestedCategoryId != confirmedCategoryId;

  /// แปลงเป็น CSV row
  String toCsvRow() {
    String esc(String? s) {
      if (s == null || s.isEmpty) return '';
      // ถ้ามีเครื่องหมาย , หรือ " ให้ครอบด้วย quotes
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    final dateStr = '${swipedAt.day.toString().padLeft(2, '0')}/'
        '${swipedAt.month.toString().padLeft(2, '0')}/'
        '${swipedAt.year} '
        '${swipedAt.hour.toString().padLeft(2, '0')}:'
        '${swipedAt.minute.toString().padLeft(2, '0')}:'
        '${swipedAt.second.toString().padLeft(2, '0')}';

    return [
      esc(id),
      esc(dateStr),
      esc(title),
      esc(bankShortName),
      isIncome ? 'รายรับ' : 'รายจ่าย',
      amount.toStringAsFixed(2),
      esc(suggestedCategoryName),
      esc(confirmedCategoryName),
      categoryChanged ? 'ใช่' : 'ไม่',
      swipeResult.labelEn,
      esc(rawText),
    ].join(',');
  }

  /// CSV Header
  static String get csvHeader =>
      'id,swipedAt,title,bankShortName,type,amount,suggestedCategory,confirmedCategory,categoryChanged,swipeResult,rawText';

  @override
  List<Object?> get props => [
        id,
        swipedAt,
        title,
        bankShortName,
        type,
        amount,
        suggestedCategoryName,
        suggestedCategoryId,
        confirmedCategoryName,
        confirmedCategoryId,
        swipeResult,
        rawText,
      ];
}
