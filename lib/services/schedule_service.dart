import 'package:cloud_firestore/cloud_firestore.dart';

import 'audit_log_service.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getSchedules() {
    return _firestore.collection('schedules').snapshots();
  }

  Future<void> addSchedule(Map<String, dynamic> data) async {
    final ref = await _firestore.collection('schedules').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogService.log(
      action: 'create',
      module: 'schedules',
      targetId: ref.id,
      description: 'Thêm lịch học ${data['subjectCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> updateSchedule({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('schedules').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogService.log(
      action: 'update',
      module: 'schedules',
      targetId: id,
      description: 'Cập nhật lịch học ${data['subjectCode'] ?? ''}',
      details: data,
    );
  }

  Future<void> deleteSchedule(String id) async {
    final old = await _firestore.collection('schedules').doc(id).get();
    await _firestore.collection('schedules').doc(id).delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'schedules',
      targetId: id,
      description: 'Xóa lịch học ${old.data()?['subjectCode'] ?? ''}',
    );
  }
}
