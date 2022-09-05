import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: null);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (message) {
      selectNotification(message!);
    });
  }

  Future selectNotification(String payload) async {
    //Handle notification tapped logic here
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) {
    //   return NewScreen(
    //     payload: payload,
    //   );
    // }));
  }
  static showNotification(String? title, String? description) async {
    AndroidNotificationDetails android = const AndroidNotificationDetails(
        'id', 'channel ',
        channelDescription: 'description',
        priority: Priority.high,
        importance: Importance.max);
    const iOS = IOSNotificationDetails();
    var platform = NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(
        UniqueKey().hashCode,
        title,
        description,
        platform,
        payload: 'Welcome to the Local Notification demo ');
  }
}
