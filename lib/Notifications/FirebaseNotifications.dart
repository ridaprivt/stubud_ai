import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

// initialise the plugin. app_icon needs to be added as a drawable resource to the Android head project
  static AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  static initNotification() async {
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  static Future<bool> _isNotificationEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_enabled') ?? false;
  }

  static Future<void> showLocalNotification(
      String title, String body, String payload) async {
    bool isEnabled = await _isNotificationEnabled();
    if (!isEnabled) return;

    const androidNotificationDetail = AndroidNotificationDetails(
      '0',
      'general',
      priority: Priority.high,
      autoCancel: false,
      fullScreenIntent: true,
      enableVibration: true,
      importance: Importance.high,
      playSound: true,
    );
    const iosNotificatonDetail = DarwinNotificationDetails();
    const notificationDetails = NotificationDetails(
      iOS: iosNotificatonDetail,
      android: androidNotificationDetail,
    );
    flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails,
        payload: payload);
  }
}
