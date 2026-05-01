import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user != null) {
      await user.updateDisplayName(fullName);

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _notificationService.initialize(user.uid);
    }

    return user;
  }

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;

    if (user != null) {
      await _notificationService.initialize(user.uid);
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}