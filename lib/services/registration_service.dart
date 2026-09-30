import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'audit_log_service.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjects() {
    return _firestore.collection('subjects').orderBy('subjectCode').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCourseSections() {
    return _firestore.collection('course_sections').snapshots();
  }

  Future<Map<String, dynamic>> getActiveSemester() async {
    final snapshot = await _firestore
        .collection('tuition_rates')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw Exception('Chưa cấu hình học kỳ hiện tại.');
    }
    final doc = snapshot.docs.first;
    return {'semesterCode': doc.id, ...doc.data()};
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyRegistrations({
    required String semesterCode,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập.');
    return _firestore
        .collection('registrations')
        .where('userId', isEqualTo: user.uid)
        .where('semesterCode', isEqualTo: semesterCode)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllRegistrations() {
    return _firestore.collection('registrations').snapshots();
  }

  Future<Map<String, dynamic>> _currentStudentContext() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập.');
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception('Không tìm thấy tài khoản.');
    final userData = userDoc.data()!;
    if (userData['role'] != 'student') {
      throw Exception('Chỉ sinh viên mới được đăng ký.');
    }
    if ((userData['isActive'] as bool? ?? true) == false) {
      throw Exception('Tài khoản đã bị khóa.');
    }
    final studentId = userData['studentId']?.toString() ?? '';
    if (studentId.isEmpty) {
      throw Exception('Tài khoản chưa liên kết sinh viên.');
    }
    final studentDoc = await _firestore.collection('students').doc(studentId).get();
    return {
      'user': user,
      'userData': userData,
      'studentId': studentId,
      'studentData': studentDoc.data() ?? <String, dynamic>{},
    };
  }

  Future<int> _maxCredits() async {
    final doc = await _firestore.collection('academic_settings').doc('general').get();
    return (doc.data()?['maxCreditsPerSemester'] as num? ?? 24).toInt();
  }

  Future<void> _checkPrerequisites({
    required String userId,
    required String subjectId,
  }) async {
    final subjectDoc = await _firestore.collection('subjects').doc(subjectId).get();
    final requiredIds = (subjectDoc.data()?['prerequisiteIds'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (requiredIds.isEmpty) return;

    final grades = await _firestore.collection('grades').where('userId', isEqualTo: userId).get();
    final passed = grades.docs
        .where((doc) => (doc.data()['averageScore'] as num? ?? 0).toDouble() >= 4.0)
        .map((doc) => doc.data()['subjectId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final missing = requiredIds.difference(passed);
    if (missing.isEmpty) return;
    final codes = <String>[];
    for (final id in missing) {
      final doc = await _firestore.collection('subjects').doc(id).get();
      codes.add(doc.data()?['subjectCode']?.toString() ?? id);
    }
    throw Exception('Chưa đạt môn tiên quyết: ${codes.join(', ')}.');
  }

  bool _overlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart <= bEnd && bStart <= aEnd;
  }

  Future<void> registerSection({
    required String sectionId,
    required Map<String, dynamic> sectionData,
  }) async {
    final context = await _currentStudentContext();
    final user = context['user'] as User;
    final userData = context['userData'] as Map<String, dynamic>;
    final studentData = context['studentData'] as Map<String, dynamic>;
    final studentId = context['studentId'] as String;
    final semester = await getActiveSemester();
    final semesterCode = semester['semesterCode'].toString();

    if (sectionData['semesterCode']?.toString() != semesterCode) {
      throw Exception('Lớp học phần không thuộc học kỳ hiện tại.');
    }
    if ((sectionData['isOpen'] as bool? ?? true) == false) {
      throw Exception('Lớp học phần đã đóng đăng ký.');
    }

    final studentClassId = studentData['classId']?.toString() ?? '';
    final sectionClassId = sectionData['classId']?.toString() ?? '';
    if (studentClassId.isNotEmpty && sectionClassId.isNotEmpty && studentClassId != sectionClassId) {
      throw Exception('Lớp học phần này không áp dụng cho lớp của bạn.');
    }

    final subjectId = sectionData['subjectId']?.toString() ?? '';
    if (subjectId.isEmpty) throw Exception('Lớp học phần chưa liên kết môn học.');
    await _checkPrerequisites(userId: user.uid, subjectId: subjectId);

    final registrations = await _firestore
        .collection('registrations')
        .where('userId', isEqualTo: user.uid)
        .where('semesterCode', isEqualTo: semesterCode)
        .get();

    if (registrations.docs.any((doc) => doc.data()['subjectId']?.toString() == subjectId)) {
      throw Exception('Bạn đã đăng ký môn học này trong học kỳ hiện tại.');
    }

    final credits = (sectionData['credits'] as num? ?? 0).toInt();
    final currentCredits = registrations.docs.fold<int>(
      0,
      (sum, doc) => sum + (doc.data()['credits'] as num? ?? 0).toInt(),
    );
    final maxCredits = await _maxCredits();
    if (currentCredits + credits > maxCredits) {
      throw Exception('Vượt giới hạn $maxCredits tín chỉ/học kỳ. Hiện tại: $currentCredits tín chỉ.');
    }

    final capacity = (sectionData['capacity'] as num? ?? 0).toInt();
    if (capacity > 0) {
      final enrolled = await _firestore
          .collection('registrations')
          .where('sectionId', isEqualTo: sectionId)
          .get();
      if (enrolled.docs.length >= capacity) {
        throw Exception('Lớp học phần đã đủ sĩ số ($capacity sinh viên).');
      }
    }

    final day = (sectionData['dayIndex'] as num? ?? 0).toInt();
    final start = (sectionData['startPeriod'] as num? ?? 0).toInt();
    final end = (sectionData['endPeriod'] as num? ?? 0).toInt();
    for (final reg in registrations.docs) {
      final d = reg.data();
      final otherDay = (d['dayIndex'] as num? ?? 0).toInt();
      final otherStart = (d['startPeriod'] as num? ?? 0).toInt();
      final otherEnd = (d['endPeriod'] as num? ?? 0).toInt();
      if (day != 0 && otherDay == day && _overlap(start, end, otherStart, otherEnd)) {
        throw Exception(
          'Trùng lịch với ${d['subjectCode'] ?? ''} - ${d['subjectName'] ?? ''} '
          '(Tiết $otherStart-$otherEnd).',
        );
      }
    }

    final registrationId = '${user.uid}_${semesterCode}_$sectionId';
    final payload = <String, dynamic>{
      'userId': user.uid,
      'studentId': studentId,
      'studentCode': userData['studentCode'] ?? studentData['studentCode'] ?? '',
      'studentName': userData['fullName'] ?? studentData['fullName'] ?? '',
      'sectionId': sectionId,
      'sectionCode': sectionData['sectionCode'] ?? '',
      'subjectId': subjectId,
      'subjectCode': sectionData['subjectCode'] ?? '',
      'subjectName': sectionData['subjectName'] ?? '',
      'credits': credits,
      'semesterCode': semesterCode,
      'semesterName': semester['semesterName'] ?? semesterCode,
      'classId': sectionData['classId'] ?? '',
      'classCode': sectionData['classCode'] ?? '',
      'roomId': sectionData['roomId'] ?? '',
      'roomCode': sectionData['roomCode'] ?? '',
      'dayIndex': day,
      'dayName': sectionData['dayName'] ?? '',
      'startPeriod': start,
      'endPeriod': end,
      'startTime': sectionData['startTime'] ?? '',
      'endTime': sectionData['endTime'] ?? '',
      'status': 'registered',
      'registeredAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('registrations').doc(registrationId).set(payload);
    await AuditLogService.log(
      action: 'register',
      module: 'registrations',
      targetId: registrationId,
      description: 'Đăng ký ${sectionData['sectionCode'] ?? ''} - ${sectionData['subjectCode'] ?? ''}',
      details: {'sectionId': sectionId, 'subjectId': subjectId, 'semesterCode': semesterCode},
    );
  }

  Future<void> registerSubject({
    required String subjectId,
    required Map<String, dynamic> subjectData,
  }) async {
    final context = await _currentStudentContext();
    final user = context['user'] as User;
    final userData = context['userData'] as Map<String, dynamic>;
    final studentId = context['studentId'] as String;
    final semester = await getActiveSemester();
    final semesterCode = semester['semesterCode'].toString();

    await _checkPrerequisites(userId: user.uid, subjectId: subjectId);
    final registrations = await _firestore
        .collection('registrations')
        .where('userId', isEqualTo: user.uid)
        .where('semesterCode', isEqualTo: semesterCode)
        .get();
    if (registrations.docs.any((doc) => doc.data()['subjectId']?.toString() == subjectId)) {
      throw Exception('Bạn đã đăng ký môn học này.');
    }
    final credits = (subjectData['credits'] as num? ?? 0).toInt();
    final currentCredits = registrations.docs.fold<int>(0, (sum, doc) => sum + (doc.data()['credits'] as num? ?? 0).toInt());
    final maxCredits = await _maxCredits();
    if (currentCredits + credits > maxCredits) {
      throw Exception('Vượt giới hạn $maxCredits tín chỉ/học kỳ.');
    }

    final registrationId = '${user.uid}_${semesterCode}_$subjectId';
    await _firestore.collection('registrations').doc(registrationId).set({
      'userId': user.uid,
      'studentId': studentId,
      'studentCode': userData['studentCode'] ?? '',
      'studentName': userData['fullName'] ?? '',
      'subjectId': subjectId,
      'subjectCode': subjectData['subjectCode'] ?? '',
      'subjectName': subjectData['subjectName'] ?? '',
      'credits': credits,
      'semesterCode': semesterCode,
      'semesterName': semester['semesterName'] ?? semesterCode,
      'status': 'registered',
      'registeredAt': FieldValue.serverTimestamp(),
    });
    await AuditLogService.log(
      action: 'register',
      module: 'registrations',
      targetId: registrationId,
      description: 'Đăng ký môn ${subjectData['subjectCode'] ?? ''}',
    );
  }

  Future<void> cancelMyRegistration({
    required String subjectId,
    String? sectionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập.');
    final semester = await getActiveSemester();
    final semesterCode = semester['semesterCode'].toString();
    final key = sectionId?.isNotEmpty == true ? sectionId! : subjectId;
    final registrationId = '${user.uid}_${semesterCode}_$key';
    final ref = _firestore.collection('registrations').doc(registrationId);
    final current = await ref.get();
    if (!current.exists && sectionId != null) {
      final legacyId = '${user.uid}_${semesterCode}_$subjectId';
      await _firestore.collection('registrations').doc(legacyId).delete();
      await AuditLogService.log(
        action: 'cancel_registration',
        module: 'registrations',
        targetId: legacyId,
        description: 'Hủy đăng ký môn $subjectId',
      );
      return;
    }
    await ref.delete();
    await AuditLogService.log(
      action: 'cancel_registration',
      module: 'registrations',
      targetId: registrationId,
      description: 'Hủy đăng ký ${current.data()?['sectionCode'] ?? current.data()?['subjectCode'] ?? subjectId}',
    );
  }

  Future<void> deleteRegistration(String registrationId) async {
    await _firestore.collection('registrations').doc(registrationId).delete();
    await AuditLogService.log(
      action: 'delete',
      module: 'registrations',
      targetId: registrationId,
      description: 'Quản trị viên xóa đăng ký môn học',
    );
  }
}
