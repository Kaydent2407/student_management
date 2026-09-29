import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // DEPARTMENTS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getDepartments() {
    return _firestore
        .collection('departments')
        .orderBy('departmentCode')
        .snapshots();
  }

  Future<void> addDepartment({
    required String departmentCode,
    required String departmentName,
  }) async {
    final code = departmentCode.trim().toUpperCase();
    final name = departmentName.trim();

    final existing = await _firestore
        .collection('departments')
        .where(
          'departmentCode',
          isEqualTo: code,
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Mã khoa đã tồn tại.');
    }

    await _firestore.collection('departments').add({
      'departmentCode': code,
      'departmentName': name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDepartment({
    required String id,
    required String departmentCode,
    required String departmentName,
  }) async {
    final code = departmentCode.trim().toUpperCase();
    final name = departmentName.trim();

    final existing = await _firestore
        .collection('departments')
        .where(
          'departmentCode',
          isEqualTo: code,
        )
        .get();

    final duplicate = existing.docs.any(
      (doc) => doc.id != id,
    );

    if (duplicate) {
      throw Exception('Mã khoa đã tồn tại.');
    }

    await _firestore
        .collection('departments')
        .doc(id)
        .update({
      'departmentCode': code,
      'departmentName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDepartment(String id) async {
    final majors = await _firestore
        .collection('majors')
        .where(
          'departmentId',
          isEqualTo: id,
        )
        .limit(1)
        .get();

    if (majors.docs.isNotEmpty) {
      throw Exception(
        'Không thể xóa khoa vì vẫn còn chuyên ngành thuộc khoa này.',
      );
    }

    await _firestore
        .collection('departments')
        .doc(id)
        .delete();
  }

  // =========================================================
  // MAJORS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getMajors() {
    return _firestore
        .collection('majors')
        .orderBy('majorCode')
        .snapshots();
  }

  Future<void> addMajor({
    required String majorCode,
    required String majorName,
    required String departmentId,
  }) async {
    final code = majorCode.trim().toUpperCase();
    final name = majorName.trim();

    final existing = await _firestore
        .collection('majors')
        .where(
          'majorCode',
          isEqualTo: code,
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
        'Mã chuyên ngành đã tồn tại.',
      );
    }

    await _firestore.collection('majors').add({
      'majorCode': code,
      'majorName': name,
      'departmentId': departmentId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMajor({
    required String id,
    required String majorCode,
    required String majorName,
    required String departmentId,
  }) async {
    final code = majorCode.trim().toUpperCase();
    final name = majorName.trim();

    final existing = await _firestore
        .collection('majors')
        .where(
          'majorCode',
          isEqualTo: code,
        )
        .get();

    final duplicate = existing.docs.any(
      (doc) => doc.id != id,
    );

    if (duplicate) {
      throw Exception(
        'Mã chuyên ngành đã tồn tại.',
      );
    }

    await _firestore
        .collection('majors')
        .doc(id)
        .update({
      'majorCode': code,
      'majorName': name,
      'departmentId': departmentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMajor(String id) async {
    final students = await _firestore
        .collection('students')
        .where(
          'majorId',
          isEqualTo: id,
        )
        .limit(1)
        .get();

    if (students.docs.isNotEmpty) {
      throw Exception(
        'Không thể xóa chuyên ngành vì đang có sinh viên sử dụng.',
      );
    }

    final classes = await _firestore
        .collection('classes')
        .where(
          'majorId',
          isEqualTo: id,
        )
        .limit(1)
        .get();

    if (classes.docs.isNotEmpty) {
      throw Exception(
        'Không thể xóa chuyên ngành vì đang có lớp học sử dụng.',
      );
    }

    await _firestore
        .collection('majors')
        .doc(id)
        .delete();
  }
}