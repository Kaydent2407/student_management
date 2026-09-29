import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // MÔN HỌC
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjects() {
    return _firestore
        .collection('subjects')
        .orderBy('subjectCode')
        .snapshots();
  }

  // =========================================================
  // HỌC KỲ HIỆN TẠI
  // =========================================================

  Future<Map<String, dynamic>>
      getActiveSemester() async {
    final snapshot = await _firestore
        .collection('tuition_rates')
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'Chưa cấu hình học kỳ hiện tại.',
      );
    }

    final doc =
        snapshot.docs.first;

    return {
      'semesterCode':
          doc.id,
      ...doc.data(),
    };
  }

  // =========================================================
  // ĐĂNG KÝ CỦA SINH VIÊN THEO HỌC KỲ
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getMyRegistrations({
    required String semesterCode,
  }) {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    return _firestore
        .collection('registrations')
        .where(
          'userId',
          isEqualTo:
              user.uid,
        )
        .where(
          'semesterCode',
          isEqualTo:
              semesterCode,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getAllRegistrations() {
    return _firestore
        .collection('registrations')
        .snapshots();
  }

  // =========================================================
  // ĐĂNG KÝ
  // =========================================================

  Future<void> registerSubject({
    required String subjectId,
    required Map<String, dynamic>
        subjectData,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    final userDoc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    if (!userDoc.exists) {
      throw Exception(
        'Không tìm thấy tài khoản.',
      );
    }

    final userData =
        userDoc.data()!;

    if (userData['role'] !=
        'student') {
      throw Exception(
        'Chỉ sinh viên mới được đăng ký.',
      );
    }

    if ((userData['isActive']
                as bool? ??
            false) ==
        false) {
      throw Exception(
        'Tài khoản đã bị khóa.',
      );
    }

    final studentId =
        userData['studentId']
                ?.toString() ??
            '';

    final studentCode =
        userData['studentCode']
                ?.toString() ??
            '';

    final studentName =
        userData['fullName']
                ?.toString() ??
            '';

    if (studentId.isEmpty) {
      throw Exception(
        'Tài khoản chưa liên kết sinh viên.',
      );
    }

    final semester =
        await getActiveSemester();

    final semesterCode =
        semester[
                'semesterCode']
            .toString();

    final semesterName =
        semester[
                    'semesterName']
                ?.toString() ??
            semesterCode;

    final subjectCode =
        subjectData[
                    'subjectCode']
                ?.toString() ??
            '';

    final subjectName =
        subjectData[
                    'subjectName']
                ?.toString() ??
            '';

    final credits =
        subjectData['credits'] ??
            0;

    final registrationId =
        '${user.uid}_${semesterCode}_$subjectId';

    final ref =
        _firestore
            .collection(
              'registrations',
            )
            .doc(
              registrationId,
            );

    try {
      await ref.set({
        'userId':
            user.uid,

        'studentId':
            studentId,
        'studentCode':
            studentCode,
        'studentName':
            studentName,

        'subjectId':
            subjectId,
        'subjectCode':
            subjectCode,
        'subjectName':
            subjectName,
        'credits':
            credits,

        'semesterCode':
            semesterCode,
        'semesterName':
            semesterName,

        'status':
            'registered',

        'registeredAt':
            FieldValue
                .serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code ==
          'permission-denied') {
        throw Exception(
          'Môn này đã được đăng ký hoặc bạn không có quyền đăng ký.',
        );
      }

      rethrow;
    }
  }

  // =========================================================
  // HỦY ĐĂNG KÝ
  // =========================================================

  Future<void> cancelMyRegistration({
    required String subjectId,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Người dùng chưa đăng nhập.',
      );
    }

    final semester =
        await getActiveSemester();

    final semesterCode =
        semester[
                'semesterCode']
            .toString();

    final registrationId =
        '${user.uid}_${semesterCode}_$subjectId';

    await _firestore
        .collection(
          'registrations',
        )
        .doc(
          registrationId,
        )
        .delete();
  }

  Future<void> deleteRegistration(
    String registrationId,
  ) async {
    await _firestore
        .collection('registrations')
        .doc(registrationId)
        .delete();
  }
}