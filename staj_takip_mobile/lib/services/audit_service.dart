import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> logAction({
    required String action, // e.g., 'CUSTOMER_DELETE', 'PRICE_CHANGE'
    required String companyId,
    required Map<String, dynamic> details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('audit_logs').add({
        'action': action,
        'companyId': companyId,
        'userId': user.uid,
        'userEmail': user.email,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Audit log failed quietly in production
    }
  }
}
