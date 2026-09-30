import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'audit_log_service.dart';

class TuitionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // CẤU HÌNH HỌC KỲ
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getTuitionRates() {
    return _firestore
        .collection('tuition_rates')
        .orderBy(
          'semesterName',
          descending: true,
        )
        .snapshots();
  }

  Future<Map<String, dynamic>?> getActiveRate() async {
    final snapshot = await _firestore
        .collection('tuition_rates')
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return {
      'id': doc.id,
      ...doc.data(),
    };
  }

  // =========================================================
  // LƯU CẤU HÌNH HỌC KỲ
  // =========================================================

  Future<void> saveTuitionRate({
    required String semesterCode,
    required String semesterName,
    required double pricePerCredit,
    required DateTime dueDate,
    required bool isActive,
  }) async {
    final code = semesterCode
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_');

    if (code.isEmpty) {
      throw Exception(
        'Mã học kỳ không được để trống.',
      );
    }

    if (code.contains('/')) {
      throw Exception(
        'Mã học kỳ không được chứa dấu "/".',
      );
    }

    if (semesterName.trim().isEmpty) {
      throw Exception(
        'Tên học kỳ không được để trống.',
      );
    }

    if (pricePerCredit <= 0) {
      throw Exception(
        'Đơn giá tín chỉ phải lớn hơn 0.',
      );
    }

    final rateRef = _firestore
        .collection('tuition_rates')
        .doc(code);

    final oldRate = await rateRef.get();

    final batch = _firestore.batch();

    // Nếu học kỳ mới được đặt active
    // thì tắt active các học kỳ khác
    if (isActive) {
      final activeRates = await _firestore
          .collection('tuition_rates')
          .where(
            'isActive',
            isEqualTo: true,
          )
          .get();

      for (final doc in activeRates.docs) {
        if (doc.id != code) {
          batch.update(
            doc.reference,
            {
              'isActive': false,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      }
    }

    batch.set(
      rateRef,
      {
        'semesterCode': code,
        'semesterName':
            semesterName.trim(),
        'pricePerCredit':
            pricePerCredit,
        'dueDate':
            Timestamp.fromDate(
          dueDate,
        ),
        'isActive':
            isActive,
        'updatedAt':
            FieldValue.serverTimestamp(),

        if (!oldRate.exists)
          'createdAt':
              FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();
    await AuditLogService.log(
      action: oldRate.exists ? 'update' : 'create',
      module: 'tuition',
      targetId: code,
      description: '${oldRate.exists ? 'Cập nhật' : 'Tạo'} cấu hình học kỳ $code',
      details: {
        'semesterName': semesterName.trim(),
        'pricePerCredit': pricePerCredit,
        'dueDate': dueDate.toIso8601String(),
        'isActive': isActive,
      },
    );
  }

  // =========================================================
  // DANH SÁCH HỌC PHÍ
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllTuition() {
    return _firestore
        .collection('tuition')
        .snapshots();
  }

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
  // TÍNH HỌC PHÍ THEO TÍN CHỈ
  // =========================================================

  Future<Map<String, dynamic>> calculateTuition({
    required String studentId,
    required String semesterCode,
  }) async {
    // Lấy cấu hình học kỳ
    final rateDoc = await _firestore
        .collection('tuition_rates')
        .doc(semesterCode)
        .get();

    if (!rateDoc.exists) {
      throw Exception(
        'Không tìm thấy cấu hình học phí của học kỳ.',
      );
    }

    final rateData =
        rateDoc.data()!;

    final pricePerCredit =
        (rateData['pricePerCredit'] as num? ?? 0)
            .toDouble();

    if (pricePerCredit <= 0) {
      throw Exception(
        'Đơn giá tín chỉ không hợp lệ.',
      );
    }

    // Lấy toàn bộ môn sinh viên đã đăng ký
    final registrations = await _firestore
        .collection('registrations')
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .get();

    // Lọc đúng học kỳ
    final semesterRegistrations =
        registrations.docs.where(
      (doc) {
        final data = doc.data();

        return data['semesterCode']
                ?.toString() ==
            semesterCode;
      },
    ).toList();

    int totalCredits = 0;

    for (final doc in semesterRegistrations) {
      final credits =
          doc.data()['credits']
                  as num? ??
              0;

      totalCredits +=
          credits.toInt();
    }

    final totalAmount =
        totalCredits *
            pricePerCredit;

    return {
      'semesterCode':
          semesterCode,

      'semesterName':
          rateData['semesterName'] ??
              semesterCode,

      'pricePerCredit':
          pricePerCredit,

      'totalCredits':
          totalCredits,

      'subjectCount':
          semesterRegistrations.length,

      'totalAmount':
          totalAmount,

      'dueDate':
          rateData['dueDate'],
    };
  }

  // =========================================================
  // ADMIN - TẠO / CẬP NHẬT HỌC PHÍ
  // =========================================================

  Future<void> saveStudentTuition({
    required String studentId,
    required String studentCode,
    required String studentName,
    required String semesterCode,
    required double paidAmount,
  }) async {
    final calculated =
        await calculateTuition(
      studentId:
          studentId,
      semesterCode:
          semesterCode,
    );

    final totalCredits =
        calculated['totalCredits']
            as int;

    final subjectCount =
        calculated['subjectCount']
            as int;

    final totalAmount =
        (calculated['totalAmount']
                as num)
            .toDouble();

    final pricePerCredit =
        (calculated['pricePerCredit']
                as num)
            .toDouble();

    if (totalCredits <= 0) {
      throw Exception(
        'Sinh viên chưa đăng ký môn nào trong học kỳ này.',
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

    final remainingAmount =
        totalAmount -
            paidAmount;

    String status = 'unpaid';

    if (paidAmount >= totalAmount) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    }

    final tuitionId =
        '${studentId}_$semesterCode';

    final ref = _firestore
        .collection('tuition')
        .doc(tuitionId);

    final old =
        await ref.get();

    await ref.set(
      {
        'studentId':
            studentId,

        'studentCode':
            studentCode,

        'studentName':
            studentName,

        'semesterCode':
            semesterCode,

        'semesterName':
            calculated['semesterName'],

        'subjectCount':
            subjectCount,

        'totalCredits':
            totalCredits,

        'pricePerCredit':
            pricePerCredit,

        'totalAmount':
            totalAmount,

        'paidAmount':
            paidAmount,

        'remainingAmount':
            remainingAmount,

        'status':
            status,

        'dueDate':
            calculated['dueDate'],

        'updatedAt':
            FieldValue.serverTimestamp(),

        if (!old.exists)
          'createdAt':
              FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    final oldPaid = (old.data()?['paidAmount'] as num? ?? 0).toDouble();
    final paymentDelta = paidAmount - oldPaid;
    if (paymentDelta > 0) {
      await _firestore.collection('tuition_payments').add({
        'tuitionId': tuitionId,
        'studentId': studentId,
        'studentCode': studentCode,
        'studentName': studentName,
        'semesterCode': semesterCode,
        'semesterName': calculated['semesterName'],
        'amount': paymentDelta,
        'method': 'admin_update',
        'transactionCode': '',
        'status': 'success',
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    }

    await AuditLogService.log(
      action: old.exists ? 'update' : 'create',
      module: 'tuition',
      targetId: tuitionId,
      description: '${old.exists ? 'Cập nhật' : 'Tạo'} học phí $studentCode - $semesterCode',
      details: {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'status': status,
      },
    );
  }

  // =========================================================
  // SINH VIÊN - THANH TOÁN GIẢ LẬP
  // =========================================================

  Future<void> mockPayTuition({
    required String tuitionId,
  }) async {
    final ref = _firestore
        .collection('tuition')
        .doc(tuitionId);

    final snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw Exception(
        'Không tìm thấy thông tin học phí.',
      );
    }

    final data =
        snapshot.data()!;

    final totalAmount =
        (data['totalAmount']
                    as num? ??
                0)
            .toDouble();

    final status =
        data['status']
                ?.toString() ??
            'unpaid';

    if (totalAmount <= 0) {
      throw Exception(
        'Tổng học phí không hợp lệ.',
      );
    }

    if (status == 'paid') {
      throw Exception(
        'Học phí này đã được thanh toán.',
      );
    }

    final previousPaid = (data['paidAmount'] as num? ?? 0).toDouble();
    final paymentAmount = (totalAmount - previousPaid).clamp(0, double.infinity).toDouble();
    final batch = _firestore.batch();
    batch.update(ref, {
      'paidAmount': totalAmount,
      'remainingAmount': 0,
      'status': 'paid',
      'paymentMethod': 'mock',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (paymentAmount > 0) {
      final paymentRef = _firestore.collection('tuition_payments').doc();
      batch.set(paymentRef, {
        'tuitionId': tuitionId,
        'studentId': data['studentId'] ?? '',
        'studentCode': data['studentCode'] ?? '',
        'studentName': data['studentName'] ?? '',
        'semesterCode': data['semesterCode'] ?? '',
        'semesterName': data['semesterName'] ?? '',
        'amount': paymentAmount,
        'method': 'mock',
        'transactionCode': 'DEMO-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
    }

    await batch.commit();
    await AuditLogService.log(
      action: 'create_payment',
      module: 'tuition',
      targetId: tuitionId,
      description: 'Thanh toán demo học phí ${data['studentCode'] ?? ''}',
      details: {'amount': paymentAmount, 'method': 'mock'},
    );
  }

  // =========================================================
  // ADMIN - XÓA
  // =========================================================

  Future<void> deleteTuition(
    String id,
  ) async {
    await _firestore
        .collection('tuition')
        .doc(id)
        .delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'tuition',
      targetId: id,
      description: 'Xóa hồ sơ học phí',
    );
  }
}