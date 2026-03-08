import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final _api = ApiService();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('🔔 Push notifications denied');
      return;
    }

    // Setup local notifications (for foreground)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'taphoa_orders',
      'Đơn hàng',
      description: 'Thông báo về đơn hàng',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Get FCM token and register
    await _registerToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) => _registerToken(token: token));

    _initialized = true;
    debugPrint('🔔 Push notification service initialized');
  }

  Future<void> _registerToken({String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      debugPrint('🔔 FCM Token: ${fcmToken.substring(0, 20)}...');

      // Register with backend
      await _api.post('/notifications/device-token', body: {
        'fcm_token': fcmToken,
        'device_type': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('🔔 Token registration error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'taphoa_orders',
          'Đơn hàng',
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> removeToken() async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await _api.delete('/notifications/device-token/$fcmToken');
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('🔔 Token removal error: $e');
    }
  }
}
