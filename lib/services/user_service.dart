import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot =
        await db.collection('users').doc(user.uid).get();

    return snapshot.data();
  }

  Future<String> getRole() async {
    final data = await getCurrentUser();

    return data?['role'] ?? 'student';
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      currentUserStream() {
    final uid = auth.currentUser!.uid;

    return db.collection('users').doc(uid).snapshots();
  }
}