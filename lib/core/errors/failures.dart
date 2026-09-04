import 'package:equatable/equatable.dart';

/// Base class for Failures across the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Cache / Local storage related failure
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'เกิดข้อผิดพลาดในการเข้าถึงหน่วยความจำในเครื่อง']);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง']);
}

/// General unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง']);
}
