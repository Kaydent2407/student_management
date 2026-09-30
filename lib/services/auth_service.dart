import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'audit_log_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    await AuditLogService.log(
      action: 'login',
      module: 'account',
      targetId: credential.user?.uid ?? '',
      description: 'Đăng nhập hệ thống',
    );
    return credential;
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String studentCode = '',
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = credential.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'fullName': fullName.trim(),
      'role': role,
      'studentCode': studentCode.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }

  Future<String?> getCurrentUserRole() async {
    final data = await getCurrentUserData();

    if (data == null) {
      return null;
    }

    return data['role'];
  }


  Future<void> sendPasswordResetEmail(String email) async {
    final value = email.trim();
    if (value.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Email không được để trống.',
      );
    }
    await _auth.sendPasswordResetEmail(email: value);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Không tìm thấy tài khoản đang đăng nhập.');
    }
    if (newPassword.trim().length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid ?? '';
    await AuditLogService.log(
      action: 'logout',
      module: 'account',
      targetId: uid,
      description: 'Đăng xuất hệ thống',
    );
    await _auth.signOut();
  }
}