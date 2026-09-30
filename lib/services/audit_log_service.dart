import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  AuditLogService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> log({
    required String action,
    required String module,
    required String description,
    String targetId = '',
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      String actorName = '';
      String actorRole = '';
      String actorEmail = user?.email ?? '';

      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        final data = doc.data();
        actorName = data?['fullName']?.toString() ?? '';
        actorRole = data?['role']?.toString() ?? '';
        actorEmail = data?['email']?.toString() ?? actorEmail;
      }

      await _db.collection('audit_logs').add({
        'actorUid': user?.uid ?? '',
        'actorName': actorName,
        'actorEmail': actorEmail,
        'actorRole': actorRole,
        'action': action,
        'module': module,
        'description': description,
        'targetId': targetId,
        'details': details ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Nhật ký không được làm gián đoạn nghiệp vụ chính.
    }
  }
}
