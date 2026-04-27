import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _db = FirebaseFirestore.instance;

  Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    const channel = AndroidNotificationChannel(
      'borrowit_channel',
      'BorrowIT Notifications',
      description: 'Pinjaman & pesan BorrowIT',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocal(title: notification.title ?? 'BorrowIT', body: notification.body ?? '');
      }
    });

    final token = await _fcm.getToken();
    if (token != null) await _saveFcmToken(token);
    _fcm.onTokenRefresh.listen(_saveFcmToken);
  }

  Future<void> _saveFcmToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  void _showLocal({required String title, required String body}) {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'borrowit_channel',
        'BorrowIT Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    _local.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    await _db.collection(AppConstants.notificationsCollection).add({
      'toUserId': toUserId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> unreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> markRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
}
