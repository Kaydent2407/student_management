import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'audit_log_service.dart';

class AccountService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Danh sách tài khoản
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('fullName')
        .snapshots();
  }

  /// Tạo tài khoản sinh viên nhưng KHÔNG làm admin bị logout.
  Future<void> createStudentAccount({
    required String email,
    required String password,
    required String fullName,
    required String studentCode,
    required String studentId,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);

      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'email': email.trim(),
        'fullName': fullName.trim(),
        'role': 'student',
        'studentCode': studentCode.trim(),
        'studentId': studentId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await AuditLogService.log(
        action: 'create',
        module: 'account',
        targetId: uid,
        description: 'Tạo tài khoản sinh viên ${studentCode.trim()}',
        details: {'email': email.trim(), 'studentId': studentId},
      );

      await secondaryAuth.signOut();
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  Future<void> changeAccountStatus({
    required String uid,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogService.log(
      action: 'update',
      module: 'account',
      targetId: uid,
      description: isActive ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
      details: {'isActive': isActive},
    );
  }

  Future<void> changeRole({
    required String uid,
    required String role,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogService.log(
      action: 'update',
      module: 'account',
      targetId: uid,
      description: 'Đổi vai trò tài khoản thành $role',
      details: {'role': role},
    );
  }
}