import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ================= STUDENTS =================

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudents() {
    return db
        .collection('students')
        .orderBy('studentCode')
        .snapshots();
  }

  Future<void> addStudent(
    Map<String, dynamic> data,
  ) async {
    await db.collection('students').add(data);
  }

  Future<void> updateStudent(
    String id,
    Map<String, dynamic> data,
  ) async {
    await db.collection('students').doc(id).update(data);
  }

  Future<void> deleteStudent(String id) async {
    await db.collection('students').doc(id).delete();
  }

  // ================= CLASSES =================

  Stream<QuerySnapshot<Map<String, dynamic>>> getClasses() {
    return db
        .collection('classes')
        .orderBy('classCode')
        .snapshots();
  }

  Future<void> addClass(
    Map<String, dynamic> data,
  ) async {
    await db.collection('classes').add(data);
  }

  Future<void> updateClass(
    String id,
    Map<String, dynamic> data,
  ) async {
    await db.collection('classes').doc(id).update(data);
  }

  Future<void> deleteClass(String id) async {
    await db.collection('classes').doc(id).delete();
  }

  // ================= SUBJECTS =================

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjects() {
    return db
        .collection('subjects')
        .orderBy('subjectCode')
        .snapshots();
  }

  Future<void> addSubject(
    Map<String, dynamic> data,
  ) async {
    await db.collection('subjects').add(data);
  }

  Future<void> updateSubject(
    String id,
    Map<String, dynamic> data,
  ) async {
    await db.collection('subjects').doc(id).update(data);
  }

  Future<void> deleteSubject(String id) async {
    await db.collection('subjects').doc(id).delete();
  }
}