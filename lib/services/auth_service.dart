import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
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

  Future<void> logout() async {
    await _auth.signOut();
  }
}