import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();

    print('FCM TOKEN: $token');

    if (token != null) {
      await saveToken(userId, token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      print('NEW FCM TOKEN: $newToken');
      await saveToken(userId, newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });
  }

  Future<void> saveToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveNotification({
    required String userId,
    required String tripId,
    required String title,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'tripId': tripId,
      'title': title,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}