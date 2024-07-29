import 'package:awesome_notifications/awesome_notifications.dart';

Future<void> scheduleNotification() async {
  DateTime now = DateTime.now();
  DateTime scheduledTime = now.add(Duration(hours: 24));

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      title: 'Quiz Time',
      body: 'You can attempt a new quiz now!',
      notificationLayout: NotificationLayout.Default,
    ),
    schedule: NotificationCalendar(
      year: scheduledTime.year,
      month: scheduledTime.month,
      day: scheduledTime.day,
      hour: scheduledTime.hour,
      minute: scheduledTime.minute,
      second: scheduledTime.second,
      millisecond: 0,
      repeats: false,
    ),
  );
}
