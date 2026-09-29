import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // DANH SÁCH MÔN HỌC
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjects() {
    return _firestore
        .collection('subjects')
        .orderBy('subjectCode')
        .snapshots();
  }

  // =========================================================
  // DANH SÁCH ĐĂNG KÝ CỦA SINH VIÊN HIỆN TẠI
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getMyRegistrations() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    return _firestore
        .collection('registrations')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  // =========================================================
  // ADMIN - XEM TẤT CẢ ĐĂNG KÝ
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllRegistrations() {
    return _firestore
        .collection('registrations')
        .orderBy(
          'registeredAt',
          descending: true,
        )
        .snapshots();
  }

  // =========================================================
  // SINH VIÊN ĐĂNG KÝ MÔN HỌC
  // =========================================================

  Future<void> registerSubject({
    required String subjectId,
    required Map<String, dynamic> subjectData,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    // =======================================================
    // LẤY THÔNG TIN TÀI KHOẢN
    // =======================================================

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception(
        'Không tìm thấy thông tin tài khoản.',
      );
    }

    final userData = userDoc.data();

    if (userData == null) {
      throw Exception(
        'Dữ liệu tài khoản không hợp lệ.',
      );
    }

    // =======================================================
    // KIỂM TRA ROLE
    // =======================================================

    final role =
        userData['role']?.toString() ?? '';

    if (role != 'student') {
      throw Exception(
        'Chỉ sinh viên mới được đăng ký môn học.',
      );
    }

    // =======================================================
    // KIỂM TRA TRẠNG THÁI
    // =======================================================

    final isActive =
        userData['isActive'] as bool? ?? false;

    if (!isActive) {
      throw Exception(
        'Tài khoản của bạn đã bị khóa.',
      );
    }

    // =======================================================
    // THÔNG TIN SINH VIÊN
    // =======================================================

    final studentId =
        userData['studentId']
                ?.toString()
                .trim() ??
            '';

    final studentCode =
        userData['studentCode']
                ?.toString()
                .trim() ??
            '';

    final studentName =
        userData['fullName']
                ?.toString()
                .trim() ??
            '';

    if (studentId.isEmpty) {
      throw Exception(
        'Tài khoản chưa được liên kết với hồ sơ sinh viên.',
      );
    }

    if (studentCode.isEmpty) {
      throw Exception(
        'Tài khoản chưa có mã sinh viên.',
      );
    }

    // =======================================================
    // THÔNG TIN MÔN HỌC
    // =======================================================

    final subjectCode =
        subjectData['subjectCode']
                ?.toString()
                .trim() ??
            '';

    final subjectName =
        subjectData['subjectName']
                ?.toString()
                .trim() ??
            '';

    final credits =
        subjectData['credits'] ?? 0;

    if (subjectCode.isEmpty ||
        subjectName.isEmpty) {
      throw Exception(
        'Thông tin môn học không hợp lệ.',
      );
    }

    // =======================================================
    // ID ĐĂNG KÝ
    //
    // Mỗi sinh viên + mỗi môn chỉ có duy nhất 1 document.
    //
    // Ví dụ:
    // UIDabc_subject123
    // =======================================================

    final registrationId =
        '${user.uid}_$subjectId';

    final registrationRef =
        _firestore
            .collection('registrations')
            .doc(registrationId);

    // =======================================================
    // TẠO ĐĂNG KÝ
    //
    // KHÔNG dùng transaction.get()
    // vì document chưa tồn tại sẽ bị Firestore Rules chặn read.
    // =======================================================

    try {
      await registrationRef.set({
        'userId': user.uid,

        'studentId': studentId,
        'studentCode': studentCode,
        'studentName': studentName,

        'subjectId': subjectId,
        'subjectCode': subjectCode,
        'subjectName': subjectName,

        'credits': credits,

        'status': 'registered',

        'registeredAt':
            FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Không có quyền đăng ký môn học hoặc môn này đã được đăng ký.',
        );
      }

      rethrow;
    }
  }

  // =========================================================
  // SINH VIÊN HỦY ĐĂNG KÝ
  // =========================================================

  Future<void> cancelMyRegistration({
    required String subjectId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    final registrationId =
        '${user.uid}_$subjectId';

    final registrationRef =
        _firestore
            .collection('registrations')
            .doc(registrationId);

    try {
      await registrationRef.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Bạn không có quyền hủy đăng ký này.',
        );
      }

      rethrow;
    }
  }

  // =========================================================
  // ADMIN HỦY ĐĂNG KÝ
  // =========================================================

  Future<void> deleteRegistration(
    String registrationId,
  ) async {
    if (registrationId.trim().isEmpty) {
      throw Exception(
        'Mã đăng ký không hợp lệ.',
      );
    }

    try {
      await _firestore
          .collection('registrations')
          .doc(registrationId)
          .delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Bạn không có quyền xóa đăng ký này.',
        );
      }

      rethrow;
    }
  }
}