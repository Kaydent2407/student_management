import 'package:cloud_firestore/cloud_firestore.dart';

class TuitionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // ADMIN - TẤT CẢ HỌC PHÍ
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllTuition() {
    return _firestore
        .collection('tuition')
        .snapshots();
  }

  // =========================================================
  // SINH VIÊN - HỌC PHÍ CỦA MÌNH
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentTuition(
    String studentId,
  ) {
    return _firestore
        .collection('tuition')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .snapshots();
  }

  // =========================================================
  // TÍNH TRẠNG THÁI
  // =========================================================

  String calculateStatus({
    required double totalAmount,
    required double paidAmount,
  }) {
    if (paidAmount <= 0) {
      return 'unpaid';
    }

    if (paidAmount >= totalAmount) {
      return 'paid';
    }

    return 'partial';
  }

  // =========================================================
  // THÊM HỌC PHÍ
  // =========================================================

  Future<void> addTuition({
    required String studentId,
    required String studentCode,
    required String studentName,
    required String semester,
    required double totalAmount,
    required double paidAmount,
    required DateTime dueDate,
  }) async {
    if (totalAmount <= 0) {
      throw Exception(
        'Tổng học phí phải lớn hơn 0.',
      );
    }

    if (paidAmount < 0) {
      throw Exception(
        'Số tiền đã đóng không được âm.',
      );
    }

    if (paidAmount > totalAmount) {
      throw Exception(
        'Số tiền đã đóng không được lớn hơn tổng học phí.',
      );
    }

    // Kiểm tra trùng học kỳ của sinh viên
    final existing = await _firestore
        .collection('tuition')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .get();

    final duplicate = existing.docs.any(
      (doc) =>
          doc.data()['semester']
              ?.toString()
              .toLowerCase() ==
          semester.trim().toLowerCase(),
    );

    if (duplicate) {
      throw Exception(
        'Sinh viên đã có học phí cho học kỳ này.',
      );
    }

    final status = calculateStatus(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );

    await _firestore.collection('tuition').add({
      'studentId': studentId,
      'studentCode': studentCode,
      'studentName': studentName,

      'semester': semester.trim(),

      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount':
          totalAmount - paidAmount,

      'status': status,

      'dueDate': Timestamp.fromDate(
        dueDate,
      ),

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // CẬP NHẬT HỌC PHÍ
  // =========================================================

  Future<void> updateTuition({
    required String id,
    required String studentId,
    required String studentCode,
    required String studentName,
    required String semester,
    required double totalAmount,
    required double paidAmount,
    required DateTime dueDate,
  }) async {
    if (totalAmount <= 0) {
      throw Exception(
        'Tổng học phí phải lớn hơn 0.',
      );
    }

    if (paidAmount < 0) {
      throw Exception(
        'Số tiền đã đóng không được âm.',
      );
    }

    if (paidAmount > totalAmount) {
      throw Exception(
        'Số tiền đã đóng không được lớn hơn tổng học phí.',
      );
    }

    final existing = await _firestore
        .collection('tuition')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .get();

    final duplicate = existing.docs.any(
      (doc) =>
          doc.id != id &&
          doc.data()['semester']
                  ?.toString()
                  .toLowerCase() ==
              semester
                  .trim()
                  .toLowerCase(),
    );

    if (duplicate) {
      throw Exception(
        'Sinh viên đã có học phí cho học kỳ này.',
      );
    }

    final status = calculateStatus(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );

    await _firestore
        .collection('tuition')
        .doc(id)
        .update({
      'studentId': studentId,
      'studentCode': studentCode,
      'studentName': studentName,

      'semester': semester.trim(),

      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount':
          totalAmount - paidAmount,

      'status': status,

      'dueDate': Timestamp.fromDate(
        dueDate,
      ),

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // XÓA
  // =========================================================

  Future<void> deleteTuition(
    String id,
  ) async {
    await _firestore
        .collection('tuition')
        .doc(id)
        .delete();
  }
}