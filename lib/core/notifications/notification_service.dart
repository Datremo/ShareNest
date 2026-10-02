import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../presentation/widgets/in_app_notification.dart';
import '../routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Handles the Firebase Cloud Messaging (FCM) integration
/// as outlined in the ShareNest push notification architecture.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    // 1. Check current permission status (don't request yet)
    NotificationSettings settings = await _messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User previously granted notification permissions');
      await _registerDeviceToken();
    }

    // 2. Listen to token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        final context = appRouter.routerDelegate.navigatorKey.currentContext;
        if (context != null) {
          InAppNotification.show(context, message);
        }
      }
    });
  }

  /// Called when the user clicks 'Enable' on our custom UX dialog
  Future<bool> requestPermissionAndRegister() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
      await _registerDeviceToken();
      return true;
    } else {
      debugPrint('User declined notification permissions');
      return false;
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String fcmToken) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Must be logged in

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';
      String platformStr = kIsWeb ? 'web' : Platform.operatingSystem;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown';
        }
      }

      await _supabase.from('user_devices').upsert({
        'user_id': user.id,
        'device_id': deviceId,
        'fcm_token': fcmToken,
        'platform': platformStr,
        'app_version': '1.0.0', // Can use package_info_plus to get real version
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, device_id'); // Assuming composite key or unique constraint
      debugPrint('Successfully registered device token in Supabase.');
    } catch (e) {
      debugPrint('Error saving token to Supabase: $e');
    }
  }

  Future<void> deactivateToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'unknown';
        }
      }

      await _supabase.from('user_devices').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).match({
        'user_id': user.id,
        'device_id': deviceId,
      });
      debugPrint('Deactivated device token in Supabase.');
    } catch (e) {
      debugPrint('Error deactivating token: $e');
    }
  }
}
