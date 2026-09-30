import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'audit_log_service.dart';

class GradeService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // ADMIN - DANH SÁCH ĐĂNG KÝ MÔN
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getRegistrations() {
    return _firestore
        .collection('registrations')
        .orderBy(
          'registeredAt',
          descending: true,
        )
        .snapshots();
  }

  // =========================================================
  // ADMIN - TẤT CẢ ĐIỂM
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllGrades() {
    return _firestore
        .collection('grades')
        .snapshots();
  }

  // =========================================================
  // SINH VIÊN - ĐIỂM CỦA MÌNH
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getMyGrades() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    return _firestore
        .collection('grades')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  // =========================================================
  // TÍNH ĐIỂM TỔNG KẾT
  // =========================================================

  double calculateAverage({
    required double midterm,
    required double finalScore,
  }) {
    final result =
        (midterm * 0.4) +
        (finalScore * 0.6);

    return double.parse(
      result.toStringAsFixed(2),
    );
  }

  // =========================================================
  // XẾP LOẠI
  // =========================================================

  String calculateLetterGrade(
    double average,
  ) {
    if (average >= 8.5) {
      return 'A';
    }

    if (average >= 7.0) {
      return 'B';
    }

    if (average >= 5.5) {
      return 'C';
    }

    if (average >= 4.0) {
      return 'D';
    }

    return 'F';
  }

  // =========================================================
  // THÊM / CẬP NHẬT ĐIỂM
  // =========================================================

  Future<void> saveGrade({
    required String registrationId,
    required Map<String, dynamic> registration,
    required double midterm,
    required double finalScore,
  }) async {
    if (midterm < 0 || midterm > 10) {
      throw Exception(
        'Điểm giữa kỳ phải từ 0 đến 10.',
      );
    }

    if (finalScore < 0 ||
        finalScore > 10) {
      throw Exception(
        'Điểm cuối kỳ phải từ 0 đến 10.',
      );
    }

    final average = calculateAverage(
      midterm: midterm,
      finalScore: finalScore,
    );

    final letterGrade =
        calculateLetterGrade(
      average,
    );

    await _firestore
        .collection('grades')
        .doc(registrationId)
        .set(
      {
        'registrationId':
            registrationId,

        'userId':
            registration['userId'] ?? '',

        'studentId':
            registration['studentId'] ?? '',

        'studentCode':
            registration['studentCode'] ?? '',

        'studentName':
            registration['studentName'] ?? '',

        'subjectId':
            registration['subjectId'] ?? '',

        'subjectCode':
            registration['subjectCode'] ?? '',

        'subjectName':
            registration['subjectName'] ?? '',

        'credits':
            registration['credits'] ?? 0,

        'semesterCode':
            registration['semesterCode'] ?? '',

        'semesterName':
            registration['semesterName'] ?? '',

        'sectionId':
            registration['sectionId'] ?? '',

        'sectionCode':
            registration['sectionCode'] ?? '',

        'midtermScore':
            midterm,

        'finalScore':
            finalScore,

        'averageScore':
            average,

        'letterGrade':
            letterGrade,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await AuditLogService.log(
      action: 'update',
      module: 'grades',
      targetId: registrationId,
      description: 'Cập nhật điểm ${registration['studentCode'] ?? ''} - ${registration['subjectCode'] ?? ''}',
      details: {
        'midtermScore': midterm,
        'finalScore': finalScore,
        'averageScore': average,
        'letterGrade': letterGrade,
      },
    );
  }

  // =========================================================
  // XÓA ĐIỂM
  // =========================================================

  Future<void> deleteGrade(
    String registrationId,
  ) async {
    await _firestore
        .collection('grades')
        .doc(registrationId)
        .delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'grades',
      targetId: registrationId,
      description: 'Xóa điểm của một đăng ký môn học',
    );
  }
}