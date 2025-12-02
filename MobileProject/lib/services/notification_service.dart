import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 🔒 Don't initialize notifications on macOS for now
    if (Platform.isMacOS) {
      return;
    }

    // ANDROID init settings
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init settings
    const DarwinInitializationSettings darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      // You can wire this later if you really want macOS notifications.
      // macOS: darwinInit,
    );

    await _notifications.initialize(initSettings);
  }

  /// Show a basic notification (used by settings_screen.dart)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Again, just do nothing on macOS so it can't crash
    if (Platform.isMacOS) {
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wordle_channel', // channel ID
      'Wordle Notifications', // channel name
      channelDescription: 'Basic notifications for the Wordle app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
