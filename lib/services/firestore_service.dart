import 'package:cloud_firestore/cloud_firestore.dart';

import 'audit_log_service.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudents() {
    return db.collection('students').orderBy('studentCode').snapshots();
  }

  Future<void> addStudent(Map<String, dynamic> data) async {
    final ref = await db.collection('students').add(data);
    await AuditLogService.log(
      action: 'create',
      module: 'students',
      targetId: ref.id,
      description: 'Thêm sinh viên ${data['studentCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await db.collection('students').doc(id).update(data);
    await AuditLogService.log(
      action: 'update',
      module: 'students',
      targetId: id,
      description: 'Cập nhật sinh viên ${data['studentCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> deleteStudent(String id) async {
    final old = await db.collection('students').doc(id).get();
    await db.collection('students').doc(id).delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'students',
      targetId: id,
      description: 'Xóa sinh viên ${old.data()?['studentCode'] ?? ''}',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getClasses() {
    return db.collection('classes').orderBy('classCode').snapshots();
  }

  Future<void> addClass(Map<String, dynamic> data) async {
    final ref = await db.collection('classes').add(data);
    await AuditLogService.log(
      action: 'create',
      module: 'classes',
      targetId: ref.id,
      description: 'Thêm lớp ${data['classCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> updateClass(String id, Map<String, dynamic> data) async {
    await db.collection('classes').doc(id).update(data);
    await AuditLogService.log(
      action: 'update',
      module: 'classes',
      targetId: id,
      description: 'Cập nhật lớp ${data['classCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> deleteClass(String id) async {
    final old = await db.collection('classes').doc(id).get();
    await db.collection('classes').doc(id).delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'classes',
      targetId: id,
      description: 'Xóa lớp ${old.data()?['classCode'] ?? ''}',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjects() {
    return db.collection('subjects').orderBy('subjectCode').snapshots();
  }

  Future<void> addSubject(Map<String, dynamic> data) async {
    final ref = await db.collection('subjects').add(data);
    await AuditLogService.log(
      action: 'create',
      module: 'subjects',
      targetId: ref.id,
      description: 'Thêm môn ${data['subjectCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    await db.collection('subjects').doc(id).update(data);
    await AuditLogService.log(
      action: 'update',
      module: 'subjects',
      targetId: id,
      description: 'Cập nhật môn ${data['subjectCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> deleteSubject(String id) async {
    final old = await db.collection('subjects').doc(id).get();
    await db.collection('subjects').doc(id).delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'subjects',
      targetId: id,
      description: 'Xóa môn ${old.data()?['subjectCode'] ?? ''}',
    );
  }
}
