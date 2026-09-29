import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Lấy toàn bộ lịch học
  Stream<QuerySnapshot<Map<String, dynamic>>>
      getSchedules() {
    return _firestore
        .collection('schedules')
        .snapshots();
  }

  // Thêm lịch học
  Future<void> addSchedule(
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('schedules')
        .add({
      ...data,
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật lịch học
  Future<void> updateSchedule({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('schedules')
        .doc(id)
        .update({
      ...data,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // Xóa lịch học
  Future<void> deleteSchedule(
    String id,
  ) async {
    await _firestore
        .collection('schedules')
        .doc(id)
        .delete();
  }
}